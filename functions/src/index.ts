import * as admin from "firebase-admin";
import {onDocumentCreated, onDocumentUpdated, onDocumentDeleted, onDocumentWritten} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {auth} from "firebase-functions/v1";
import * as nodemailer from "nodemailer";

admin.initializeApp();
const db = admin.firestore();

// ──────────────────────────────────────────────────────────────────────────────
// Hilfsfunktionen
// ──────────────────────────────────────────────────────────────────────────────

// Gibt den UTC-Offset für Wien zurück (CEST=2 im Sommer, CET=1 im Winter).
// Umschaltung: letzter Sonntag im März 01:00 UTC → letzter Sonntag im Oktober 01:00 UTC.
function getViennaOffsetHours(date: Date): number {
  const y = date.getUTCFullYear();
  const lastSundayOf = (month: number) => {
    const lastDay = new Date(Date.UTC(y, month + 1, 0));
    return new Date(Date.UTC(y, month, lastDay.getUTCDate() - lastDay.getUTCDay(), 1, 0, 0));
  };
  const cstStart = lastSundayOf(2);  // letzter Sonntag März  01:00 UTC
  const cstEnd   = lastSundayOf(9);  // letzter Sonntag Okt.  01:00 UTC
  return (date >= cstStart && date < cstEnd) ? 2 : 1;
}

async function getTokens(userId: string): Promise<string[]> {
  const doc = await db.doc(`users/${userId}`).get();
  return (doc.data()?.fcmTokens as string[]) ?? [];
}

// Gleiche Fallback-Kette wie clientseitig (firebase_auth_repository.dart _toAppUser):
// Firestore firstName+lastName → Firebase-Auth-displayName (Google-Login-Nutzer haben
// nie firstName/lastName in Firestore, nur den Auth-displayName) → String-Fallback.
async function getUserName(userId: string, fallback: string): Promise<string> {
  const doc = await db.doc(`users/${userId}`).get();
  const data = doc.data() ?? {};
  const first = (data["firstName"] as string | undefined) ?? "";
  const last = (data["lastName"] as string | undefined) ?? "";
  const name = `${first} ${last}`.trim();
  if (name) return name;
  try {
    const authUser = await admin.auth().getUser(userId);
    if (authUser.displayName) return authUser.displayName;
  } catch (_) {
    // Nutzer evtl. gelöscht — String-Fallback verwenden
  }
  return fallback;
}

interface NotificationPayload {
  title: string;
  body: string;
  data: Record<string, string>;
}

async function sendNotification(
  tokens: string[],
  userId: string,
  payload: NotificationPayload
): Promise<void> {
  if (!tokens.length) return;

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {title: payload.title, body: payload.body},
    data: payload.data,
    android: {priority: "high"},
    apns: {payload: {aps: {sound: "default"}}},
  });

  // Ungültige Tokens aus Firestore entfernen
  const invalidTokens: string[] = [];
  response.responses.forEach((res, idx) => {
    if (
      !res.success &&
      res.error?.code === "messaging/registration-token-not-registered"
    ) {
      invalidTokens.push(tokens[idx]);
    }
  });
  if (invalidTokens.length > 0) {
    await db.doc(`users/${userId}`).update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
    });
  }
}

// Verhindert doppelte Verarbeitung bei Firestore-Trigger-Redelivery (at-least-once
// Zustellung, z.B. nach transientem Fehler/Timeout in einer vorherigen Ausführung).
// event.id ist bei einer Redelivery desselben Events identisch, bei einem neuen
// Event immer neu — schützt so nicht nur vor doppelten Push-Notifications, sondern
// auch vor doppelter Ausführung anderer nicht-idempotenter Seiteneffekte
// (z.B. FieldValue.increment auf freiePlaetze).
async function claimEventOnce(eventId: string): Promise<boolean> {
  const ref = db.collection("processedTriggerEvents").doc(eventId);
  try {
    await ref.create({at: admin.firestore.FieldValue.serverTimestamp()});
    return true;
  } catch (e) {
    return false; // Dokument existiert schon → Event wurde bereits verarbeitet
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Trigger 1: Anfrage-Status geändert → Mitfahrer benachrichtigen
// ──────────────────────────────────────────────────────────────────────────────

export const onAnfrageUpdated = onDocumentUpdated(
  "anfragen/{anfrageId}",
  async (event) => {
    const change = event.data;
    if (!change) return;
    if (!(await claimEventOnce(event.id))) return;

    const before = change.before.data();
    const after = change.after.data();

    const statusBefore = before["status"] as number;
    const statusAfter = after["status"] as number;

    if (statusBefore === statusAfter) return;

    // Status 4 = fahrtGeloescht: Fahrt wird gelöscht, onFahrtDeleted übernimmt
    if (statusAfter === 4) return;

    // ── freiePlaetze atomisch anpassen ──────────────────────────────────────
    const fahrtId = after["fahrtId"] as string | undefined;
    const vonFahrer = after["vonFahrer"] === true;
    if (fahrtId) {
      if (statusAfter === 1 && !vonFahrer) {
        // Normale Anfrage akzeptiert (Mitfahrer hat angefragt, Fahrer akzeptiert):
        // Platz(e) belegen. Bei vonFahrer=true übernimmt acceptInvitation die
        // atomare Dekrement innerhalb der Transaction.
        const seats = (after["seatsAccepted"] as number | undefined) ?? 1;
        await db.doc(`fahrten/${fahrtId}`).update({
          freiePlaetze: admin.firestore.FieldValue.increment(-seats),
        });
      } else if (statusBefore === 1 && (statusAfter === 2 || statusAfter === 3)) {
        // war akzeptiert, jetzt abgelehnt/storniert: Platz(e) freigeben
        const seats = (before["seatsAccepted"] as number | undefined) ?? 1;
        await db.doc(`fahrten/${fahrtId}`).update({
          freiePlaetze: admin.firestore.FieldValue.increment(seats),
        });
      }
    }

    // ── Notification senden ─────────────────────────────────────────────────
    const statusMap: Record<number, string> = {
      1: "akzeptiert",
      2: "abgelehnt",
      3: "storniert",
    };
    const statusText = statusMap[statusAfter];
    if (!statusText) return;

    // D1-Fix: Mitfahrer storniert eigene Anfrage → Fahrer benachrichtigen, nicht Mitfahrer
    const isMitfahrerStorniert = !vonFahrer && statusAfter === 3;
    const requesterId = after["requesterId"] as string | undefined;
    const fahrtOwnerId = after["fahrtOwnerId"] as string | undefined;
    const targetUserId = (vonFahrer || statusAfter === 3)
      ? fahrtOwnerId
      : requesterId;
    if (!targetUserId) return;

    // Namen immer live aus users-Collection lesen – gespeicherte Namen können veraltet sein
    const [requesterName, fahrerName] = await Promise.all([
      requesterId ? getUserName(requesterId, "Ein Mitfahrer") : Promise.resolve("Ein Mitfahrer"),
      fahrtOwnerId ? getUserName(fahrtOwnerId, "Der Fahrer") : Promise.resolve("Der Fahrer"),
    ]);

    let title: string;
    let body: string;
    if (isMitfahrerStorniert) {
      title = "Anfrage zurückgezogen";
      body = `${requesterName} hat die Anfrage zurückgezogen`;
    } else {
      title = vonFahrer ? `Einladung ${statusText}` : `Anfrage ${statusText}`;
      body = vonFahrer
        ? `${requesterName} hat deine Einladung ${statusText}`
        : `${fahrerName} hat deine Anfrage ${statusText}`;
    }

    const tokens = await getTokens(targetUserId);
    if (!tokens.length) return;

    let notifData: Record<string, string>;
    if (isMitfahrerStorniert) {
      const ownerId = after["fahrtOwnerId"] as string | undefined;
      const requesterId = after["requesterId"] as string | undefined;
      const conversationId =
        fahrtId && ownerId && requesterId
          ? `${fahrtId}_${[ownerId, requesterId].sort().join("_")}`
          : "";
      notifData = {
        type: "storno_chat",
        conversationId,
        senderId: requesterId ?? "",
      };
    } else {
      notifData = {type: "anfrage", anfrageId: event.params["anfrageId"]};
    }

    await sendNotification(tokens, targetUserId, {
      title,
      body,
      data: notifData,
    });
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// Trigger 2: Neue Anfrage erstellt → Fahrer benachrichtigen
//            Neue Einladung erstellt → Interessent benachrichtigen
// ──────────────────────────────────────────────────────────────────────────────

export const onAnfrageCreated = onDocumentCreated(
  "anfragen/{anfrageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    if (!(await claimEventOnce(event.id))) return;

    const data = snap.data();
    const vonFahrer = data["vonFahrer"] === true;
    const requesterId = data["requesterId"] as string | undefined;
    const fahrtOwnerId = data["fahrtOwnerId"] as string | undefined;
    const zielOrt = (data["zielOrt"] as string | undefined) ?? "?";

    let targetUserId: string | undefined;
    let title: string;
    let body: string;

    if (vonFahrer) {
      // Fahrer lädt Interessenten ein → Interessent benachrichtigen
      targetUserId = requesterId;
      const fahrerName = fahrtOwnerId ? await getUserName(fahrtOwnerId, "Ein Fahrer") : "Ein Fahrer";
      title = "Neue Einladung";
      body = `${fahrerName} lädt dich zur Fahrt nach ${zielOrt} ein`;
    } else {
      // Mitfahrer fragt an → Fahrer benachrichtigen
      targetUserId = fahrtOwnerId;
      const requesterName = requesterId ? await getUserName(requesterId, "Jemand") : "Jemand";
      title = "Neue Anfrage";
      body = `${requesterName} möchte mitfahren nach ${zielOrt}`;
    }

    if (!targetUserId) return;

    const tokens = await getTokens(targetUserId);
    await sendNotification(tokens, targetUserId, {
      title,
      body,
      data: {type: "anfrage", anfrageId: event.params["anfrageId"]},
    });
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// Trigger 3: Fahrt gelöscht → akzeptierte Mitfahrer benachrichtigen
// ──────────────────────────────────────────────────────────────────────────────

export const onFahrtDeleted = onDocumentDeleted(
  "fahrten/{fahrtId}",
  async (event) => {
    const fahrt = event.data?.data();
    if (!fahrt) return;
    if (!(await claimEventOnce(event.id))) return;

    const fahrtId = event.params["fahrtId"];
    const eventName = (fahrt["eventName"] as string | undefined) ?? "das Event";
    const zielOrt = (fahrt["standort"] as string | undefined) ?? "?";
    const ownerId = fahrt["ownerId"] as string | undefined;
    const fahrerName = ownerId ? await getUserName(ownerId, "Der Fahrer") : "Der Fahrer";

    // Alle akzeptierten Anfragen für diese Fahrt laden (status = 1)
    const snapshot = await db
      .collection("anfragen")
      .where("fahrtId", "==", fahrtId)
      .where("status", "==", 1)
      .get();

    if (snapshot.empty) return;

    const sends = snapshot.docs.map(async (doc) => {
      const anfrage = doc.data();
      const targetUserId = anfrage["requesterId"] as string | undefined;
      if (!targetUserId) return;

      const tokens = await getTokens(targetUserId);
      await sendNotification(tokens, targetUserId, {
        title: "Fahrt abgesagt",
        body: `${fahrerName} hat die Fahrt nach ${zielOrt} (${eventName}) abgesagt`,
        data: {type: "fahrt_geloescht", fahrtId},
      });
    });

    await Promise.all(sends);
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// Interessenten-Zähler: denormalisiertes Feld events/{eventId}.interessentenCount
// pflegen, damit auch ausgeloggte Clients den Zähler sehen können, ohne die
// (auth-geschützte) interessenten-Collection lesen zu müssen.
// ──────────────────────────────────────────────────────────────────────────────

export const onInteressentCreated = onDocumentCreated(
  "interessenten/{docId}",
  async (event) => {
    const eventId = event.data?.data()?.["eventId"] as string | undefined;
    if (!eventId) return;
    await db.collection("events").doc(eventId).update({
      interessentenCount: admin.firestore.FieldValue.increment(1),
    }).catch(() => {
      // Event evtl. bereits gelöscht (cleanupAbgelaufeneEvents) — nicht kritisch
    });
  }
);

export const onInteressentDeleted = onDocumentDeleted(
  "interessenten/{docId}",
  async (event) => {
    const eventId = event.data?.data()?.["eventId"] as string | undefined;
    if (!eventId) return;
    await db.collection("events").doc(eventId).update({
      interessentenCount: admin.firestore.FieldValue.increment(-1),
    }).catch(() => {
      // Event evtl. bereits gelöscht (cleanupAbgelaufeneEvents) — nicht kritisch
    });
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// Trigger 4: Führerschein hochgeladen → alle Admins benachrichtigen
// ──────────────────────────────────────────────────────────────────────────────

export const onLicenseRequestWritten = onDocumentWritten(
  "licenseRequests/{uid}",
  async (event) => {
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();

    // Nur feuern wenn Status auf 'pending' gesetzt wird
    if (!after || after["status"] !== "pending") return;

    // Re-Submissions erkennen: submittedAt muss sich geändert haben
    const submittedBefore = before?.["submittedAt"];
    const submittedAfter = after["submittedAt"];
    if (submittedBefore && submittedAfter &&
        submittedBefore.isEqual(submittedAfter)) return;
    if (!(await claimEventOnce(event.id))) return;

    const userName = await getUserName(event.params["uid"], "Ein Nutzer");

    const adminsSnap = await db
      .collection("users")
      .where("isAdmin", "==", true)
      .get();

    await Promise.all(
      adminsSnap.docs.map(async (adminDoc) => {
        const tokens = (adminDoc.data()["fcmTokens"] as string[]) ?? [];
        if (!tokens.length) return;
        await sendNotification(tokens, adminDoc.id, {
          title: "Neue Führerschein-Prüfung",
          body: `${userName} hat einen Führerschein hochgeladen`,
          data: {type: "license_review", uid: event.params["uid"]},
        });
      })
    );
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// Trigger 5b: Neue Event-Anfrage erstellt → alle Admins benachrichtigen
// ──────────────────────────────────────────────────────────────────────────────

export const onEventRequestCreated = onDocumentCreated(
  "eventRequests/{requestId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    if (!(await claimEventOnce(event.id))) return;

    const data = snap.data();
    const uid = data["uid"] as string | undefined;
    const userName = uid ? await getUserName(uid, "Ein Nutzer") : "Ein Nutzer";
    const isFlyer = data["submissionType"] === "flyer";
    const eventName = (data["eventName"] as string | undefined) ?? "";

    const body = isFlyer
      ? `${userName} hat einen Flyer hochgeladen`
      : `${userName} hat ein Event eingetragen${eventName ? `: ${eventName}` : ""}`;

    const adminsSnap = await db
      .collection("users")
      .where("isAdmin", "==", true)
      .get();

    await Promise.all(
      adminsSnap.docs.map(async (adminDoc) => {
        const tokens = (adminDoc.data()["fcmTokens"] as string[]) ?? [];
        if (!tokens.length) return;
        await sendNotification(tokens, adminDoc.id, {
          title: "Neue Event-Anfrage",
          body,
          data: {type: "event_request", requestId: event.params["requestId"]},
        });
      })
    );
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// Trigger 5c: Neue User-Meldung → alle Admins benachrichtigen
// ──────────────────────────────────────────────────────────────────────────────

export const onUserReportCreated = onDocumentCreated(
  "user_reports/{docId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    if (!(await claimEventOnce(event.id))) return;

    const data = snap.data();
    const reporterUid = data["reporterUid"] as string | undefined;
    const reportedUid = data["reportedUid"] as string | undefined;
    const reason = (data["reason"] as string | undefined) ?? "Unbekannt";

    const [reporterName, reportedName] = await Promise.all([
      reporterUid ? getUserName(reporterUid, "Ein Nutzer") : Promise.resolve("Ein Nutzer"),
      reportedUid ? getUserName(reportedUid, "Ein Nutzer") : Promise.resolve("Ein Nutzer"),
    ]);

    const adminsSnap = await db
      .collection("users")
      .where("isAdmin", "==", true)
      .get();

    await Promise.all(
      adminsSnap.docs.map(async (adminDoc) => {
        const tokens = (adminDoc.data()["fcmTokens"] as string[]) ?? [];
        if (!tokens.length) return;
        await sendNotification(tokens, adminDoc.id, {
          title: "Neue Nutzer-Meldung",
          body: `${reporterName} hat ${reportedName} gemeldet: ${reason}`,
          data: {type: "user_report", reportedUid: reportedUid ?? ""},
        });
      })
    );
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// Callable 6: Einladung atomar annehmen
//   – verifiziert Anfrage-Status in einer Transaction
//   – storniert alle anderen offenen Einladungen des Users für das Event
//   – entfernt den User aus der Interessentenliste
// ──────────────────────────────────────────────────────────────────────────────

export const acceptInvitation = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Nicht eingeloggt");
  }

  const uid = request.auth.uid;
  const data = request.data as {anfrageId?: unknown; seatsAccepted?: unknown};

  // Input-Validierung
  if (typeof data.anfrageId !== "string" || !data.anfrageId) {
    throw new HttpsError("invalid-argument", "anfrageId fehlt");
  }
  const seatsAccepted = Math.floor(Number(data.seatsAccepted));
  if (!Number.isFinite(seatsAccepted) || seatsAccepted <= 0 || seatsAccepted > 8) {
    throw new HttpsError("invalid-argument", "Ungültige Sitzanzahl (1–8)");
  }

  const anfrageId = data.anfrageId;
  const anfrageRef = db.collection("anfragen").doc(anfrageId);

  // Anfrage laden
  const anfrageDoc = await anfrageRef.get();
  if (!anfrageDoc.exists) {
    throw new HttpsError("not-found", "Anfrage nicht gefunden");
  }
  const anfrage = anfrageDoc.data()!;

  if (anfrage["requesterId"] !== uid) {
    throw new HttpsError("permission-denied", "Keine Berechtigung");
  }

  const eventId = anfrage["eventId"] as string;
  const fahrtId = anfrage["fahrtId"] as string;

  // (1) Bereits akzeptierte Fahrt für dieses Event?
  const acceptedSnap = await db
    .collection("anfragen")
    .where("requesterId", "==", uid)
    .where("eventId", "==", eventId)
    .where("status", "==", 1)
    .get();
  if (!acceptedSnap.empty) {
    throw new HttpsError("already-exists", "Du hast bereits eine Fahrt für dieses Event");
  }

  // (2) Andere offene Anfragen dieses Users für dieses Event
  const otherOpenSnap = await db
    .collection("anfragen")
    .where("requesterId", "==", uid)
    .where("eventId", "==", eventId)
    .where("status", "==", 0)
    .get();
  const otherOpenIds = otherOpenSnap.docs
    .filter((d) => d.id !== anfrageId)
    .map((d) => d.id);

  // (3) Atomare Transaction — Kapazitätsprüfung + Dekrement darin (Race-Condition-Schutz)
  const fahrtRef = db.doc(`fahrten/${fahrtId}`);
  const now = Date.now();
  await db.runTransaction(async (txn) => {
    // Anfrage-Status prüfen
    const latest = await txn.get(anfrageRef);
    if (!latest.exists || latest.data()!["status"] !== 0) {
      throw new HttpsError(
        "failed-precondition",
        "Diese Einladung wurde zwischenzeitlich bearbeitet"
      );
    }

    // Kapazität atomar prüfen und belegen
    const fahrtSnap = await txn.get(fahrtRef);
    if (!fahrtSnap.exists) {
      throw new HttpsError("not-found", "Fahrt nicht gefunden");
    }
    const aktuellFreiePlaetze = (fahrtSnap.data()!["freiePlaetze"] as number | undefined) ?? 0;
    if (aktuellFreiePlaetze < seatsAccepted) {
      throw new HttpsError("failed-precondition", "Keine freien Plätze mehr");
    }

    // Annehmen + Platz belegen
    txn.update(anfrageRef, {status: 1, seatsAccepted, updatedAt: now});
    txn.update(fahrtRef, {freiePlaetze: admin.firestore.FieldValue.increment(-seatsAccepted)});

    // Andere offene Einladungen stornieren
    for (const id of otherOpenIds) {
      txn.update(db.collection("anfragen").doc(id), {status: 3, updatedAt: now});
    }

    // Aus Interessentenliste entfernen (ID-Format: eventId_userId)
    txn.delete(db.collection("interessenten").doc(`${eventId}_${uid}`));
  });

  return {success: true};
});

// ──────────────────────────────────────────────────────────────────────────────
// Callable 7: Kennzeichen abrufen (Sicherheits-Feature)
//   – Gibt das aktuelle Kennzeichen des Fahrers zurück
//   – Nur für bestätigte Mitfahrer (akzeptierte Anfrage für diese Fahrt)
//   – Nur innerhalb von 24h vor Abfahrt (server-seitig geprüft)
//   – Gibt releasedAt zurück wenn noch zu früh, expired wenn Fahrt vorbei
// ──────────────────────────────────────────────────────────────────────────────

export const getLicensePlate = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Nicht eingeloggt");
  }

  const callerId = request.auth.uid;
  const data = request.data as {fahrtId?: unknown};
  if (typeof data.fahrtId !== "string" || !data.fahrtId) {
    throw new HttpsError("invalid-argument", "fahrtId fehlt");
  }
  const fahrtId = data.fahrtId;

  // 1. Akzeptierte Anfrage des Callers für diese Fahrt prüfen
  const anfragenSnap = await db
    .collection("anfragen")
    .where("fahrtId", "==", fahrtId)
    .where("requesterId", "==", callerId)
    .where("status", "==", 1)
    .limit(1)
    .get();

  if (anfragenSnap.empty) {
    throw new HttpsError("permission-denied", "Keine akzeptierte Anfrage für diese Fahrt");
  }

  // 2. Fahrt laden
  const fahrtDoc = await db.doc(`fahrten/${fahrtId}`).get();
  if (!fahrtDoc.exists) throw new HttpsError("not-found", "Fahrt nicht gefunden");
  const fahrtData = fahrtDoc.data()!;

  // 3. Event-Datum laden
  const eventId = fahrtData["eventId"] as string;
  const uhrzeitHour = (fahrtData["uhrzeitHour"] as number | undefined) ?? 0;
  const uhrzeitMinute = (fahrtData["uhrzeitMinute"] as number | undefined) ?? 0;

  const eventDoc = await db.doc(`events/${eventId}`).get();
  if (!eventDoc.exists) throw new HttpsError("not-found", "Event nicht gefunden");

  const rawDatum = eventDoc.data()!["datum"];
  let eventDatum: Date;
  if (rawDatum && typeof rawDatum.toDate === "function") {
    eventDatum = rawDatum.toDate();
  } else if (typeof rawDatum === "string") {
    eventDatum = new Date(rawDatum);
  } else {
    throw new HttpsError("internal", "Ungültiges Event-Datum");
  }

  // 4. Abfahrtszeit berechnen und 24h-Fenster prüfen (server-seitig)
  // Uhrzeit ist in Wiener Lokalzeit gespeichert → in UTC umrechnen (CET=UTC+1, CEST=UTC+2)
  const departure = new Date(eventDatum);
  departure.setUTCHours(uhrzeitHour, uhrzeitMinute, 0, 0);
  const viennaOffset = getViennaOffsetHours(departure);
  departure.setTime(departure.getTime() - viennaOffset * 60 * 60 * 1000);

  const now = new Date();
  const hoursUntilDeparture = (departure.getTime() - now.getTime()) / (1000 * 60 * 60);

  if (hoursUntilDeparture > 24) {
    // Noch zu früh: Freigabezeitpunkt zurückgeben
    const releasedAt = new Date(departure.getTime() - 24 * 60 * 60 * 1000).toISOString();
    return {plate: null, releasedAt};
  }
  // 6 Stunden nach Abfahrt: Fahrt ist vorbei (Rückfahrt-Puffer inbegriffen)
  if (hoursUntilDeparture < -6) {
    return {plate: null, expired: true};
  }

  // 5. Kennzeichen aus private doc des Fahrers lesen (Admin SDK hat vollen Zugriff)
  const ownerId = fahrtData["ownerId"] as string;
  const privateDoc = await db.doc(`users/${ownerId}/private/data`).get();
  const plate = (privateDoc.data()?.["licensePlate"] as string | undefined) ?? null;

  return {plate};
});

// ──────────────────────────────────────────────────────────────────────────────
// Callable 8: Bewertung abgeben
//   – Vollständige serverseitige Validierung:
//     1. Authentifizierung
//     2. reviewer !== reviewed
//     3. rating 1–5
//     4. comment max. 120 Zeichen
//     5. Review noch nicht vorhanden
//     6. Gemeinsame akzeptierte Anfrage vorhanden
//     7. Event bereits vorbei (datum + 3h Puffer)
//   – Bei Erfolg: Review anlegen + ratingAvg/ratingCount im User-Dokument aktualisieren
// ──────────────────────────────────────────────────────────────────────────────

export const submitReview = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Nicht eingeloggt");
  }

  const reviewerId = request.auth.uid;
  const data = request.data as {
    reviewedId?: unknown;
    fahrtId?: unknown;
    rating?: unknown;
    comment?: unknown;
  };

  // ── Input-Validierung ──
  if (typeof data.reviewedId !== "string" || !data.reviewedId) {
    throw new HttpsError("invalid-argument", "reviewedId fehlt");
  }
  if (typeof data.fahrtId !== "string" || !data.fahrtId) {
    throw new HttpsError("invalid-argument", "fahrtId fehlt");
  }
  const rating = Math.floor(Number(data.rating));
  if (!Number.isFinite(rating) || rating < 1 || rating > 5) {
    throw new HttpsError("invalid-argument", "Bewertung muss zwischen 1 und 5 Sternen liegen");
  }
  const comment = typeof data.comment === "string" ? data.comment.trim() : "";
  if (comment.length > 120) {
    throw new HttpsError("invalid-argument", "Kommentar darf maximal 120 Zeichen lang sein");
  }

  const reviewedId = data.reviewedId;
  const fahrtId = data.fahrtId;

  // ── reviewer !== reviewed ──
  if (reviewerId === reviewedId) {
    throw new HttpsError("invalid-argument", "Du kannst dich nicht selbst bewerten");
  }

  // ── Review bereits vorhanden? ──
  const reviewId = `${fahrtId}_${reviewedId}`;
  const existingDoc = await db.doc(`reviews/${reviewId}`).get();
  if (existingDoc.exists) {
    throw new HttpsError("already-exists", "Du hast diese Person für diese Fahrt bereits bewertet");
  }

  // ── Gemeinsame akzeptierte Anfrage vorhanden? (nur Mitfahrer → Fahrer) ──
  const anfrageSnap = await db
    .collection("anfragen")
    .where("fahrtId", "==", fahrtId)
    .where("requesterId", "==", reviewerId)
    .where("fahrtOwnerId", "==", reviewedId)
    .where("status", "==", 1)
    .limit(1)
    .get();

  if (anfrageSnap.empty) {
    throw new HttpsError(
      "failed-precondition",
      "Keine gemeinsame Fahrt gefunden. Bewertungen sind nur nach geteilten Fahrten möglich"
    );
  }

  // ── Event bereits vorbei + 3h Puffer? ──
  // Wenn das Fahrt-Dokument nicht mehr existiert (z.B. vom Fahrer gelöscht),
  // wird der Zeitfenster-Check übersprungen – die akzeptierte Anfrage ist Beweis genug.
  const fahrtDoc = await db.doc(`fahrten/${fahrtId}`).get();
  if (fahrtDoc.exists) {
    const fahrtData = fahrtDoc.data()!;
    const eventId = fahrtData["eventId"] as string | undefined;

    if (eventId) {
      const eventDoc = await db.doc(`events/${eventId}`).get();
      if (eventDoc.exists) {
        const datum = eventDoc.data()!["datum"] as string | undefined;
        if (datum) {
          const eventTime = new Date(datum).getTime();
          const bufferMs = 3 * 60 * 60 * 1000; // 3 Stunden
          const reviewWindowMs = 14 * 24 * 60 * 60 * 1000; // 14 Tage
          const now = Date.now();
          if (eventTime + bufferMs > now) {
            throw new HttpsError(
              "failed-precondition",
              "Bewertungen sind erst nach der Veranstaltung möglich"
            );
          }
          if (now > eventTime + bufferMs + reviewWindowMs) {
            throw new HttpsError(
              "failed-precondition",
              "Die Bewertungsfrist für diese Fahrt ist abgelaufen (14 Tage nach der Veranstaltung)."
            );
          }
        }
      }
    }
  }

  // ── Reviewer-Name + Foto laden ──
  const reviewerDoc = await db.doc(`users/${reviewerId}`).get();
  const reviewerData = reviewerDoc.data() ?? {};
  const reviewerFirst = (reviewerData["firstName"] as string | undefined) ?? "";
  const reviewerLast = (reviewerData["lastName"] as string | undefined) ?? "";
  const reviewerName = `${reviewerFirst} ${reviewerLast}`.trim() || "Unbekannt";
  const reviewerPhotoUrl = (reviewerData["photoUrl"] as string | undefined) ?? null;

  // ── Review anlegen + ratingAvg/ratingCount atomar aktualisieren ──
  await db.runTransaction(async (txn) => {
    // Nochmals prüfen ob Review inzwischen existiert (Race Condition)
    const check = await txn.get(db.doc(`reviews/${reviewId}`));
    if (check.exists) {
      throw new HttpsError("already-exists", "Du hast diese Person für diese Fahrt bereits bewertet");
    }

    // Alle bestehenden Reviews für reviewedId lesen (für Avg-Berechnung)
    const existingReviewsSnap = await db
      .collection("reviews")
      .where("reviewedId", "==", reviewedId)
      .get();

    const existingRatings = existingReviewsSnap.docs.map(
      (d) => (d.data()["rating"] as number | undefined) ?? 0
    );
    const newCount = existingRatings.length + 1;
    const sum = existingRatings.reduce((a, b) => a + b, 0) + rating;
    const newAvg = Math.round((sum / newCount) * 10) / 10;

    // Review-Dokument schreiben
    txn.set(db.doc(`reviews/${reviewId}`), {
      reviewerId,
      reviewerName,
      reviewerPhotoUrl,
      reviewedId,
      fahrtId,
      rating,
      comment,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // User-Dokument mit neuen Rating-Werten aktualisieren
    txn.update(db.doc(`users/${reviewedId}`), {
      ratingAvg: newAvg,
      ratingCount: newCount,
    });
  });

  // Notification an den bewerteten User senden
  const reviewedTokens = await getTokens(reviewedId);
  if (reviewedTokens.length > 0) {
    const senderName = reviewerName.trim() || 'Jemand';
    await sendNotification(reviewedTokens, reviewedId, {
      title: 'Neue Bewertung ⭐',
      body: `${senderName} hat dich bewertet`,
      data: {
        type: 'review',
        reviewedId: reviewedId,
      },
    });
  }

  return {success: true};
});

// ──────────────────────────────────────────────────────────────────────────────
// Trigger 5: Neue Chat-Nachricht → anderen Teilnehmer benachrichtigen
// ──────────────────────────────────────────────────────────────────────────────

export const onMessageCreated = onDocumentCreated(
  "chat_conversations/{convId}/messages/{msgId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const msg = snap.data();
    if (msg["isSystem"] === true) return;
    if (!(await claimEventOnce(event.id))) return;

    const convSnap = await db
      .doc(`chat_conversations/${event.params["convId"]}`)
      .get();
    const conv = convSnap.data();
    if (!conv) return;

    const participants = conv["participants"] as string[];
    const targetUserId = participants.find((p) => p !== msg["senderId"]);
    if (!targetUserId) return;

    // Nicht senden wenn Empfänger gerade aktiv ist
    const userSnap = await db.doc(`users/${targetUserId}`).get();
    const lastSeen = userSnap.data()?.["lastSeen"]?.toDate() as Date | undefined;
    if (lastSeen) {
      const msgTime =
        (msg["createdAt"] as admin.firestore.Timestamp)?.toDate() ?? new Date();
      if (msgTime <= lastSeen) return;
    }

    const senderId = msg["senderId"] as string;
    const tokens = await getTokens(targetUserId);
    const text = msg["text"] as string;
    const preview = text.length > 80 ? text.substring(0, 80) + "…" : text;
    const senderName = await getUserName(senderId, "Neue Nachricht");

    await sendNotification(tokens, targetUserId, {
      title: senderName,
      body: preview,
      data: {
        type: "chat",
        conversationId: event.params["convId"],
        senderId: senderId,
      },
    });
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// Event-Anfrage genehmigt → Nutzer benachrichtigen
// ──────────────────────────────────────────────────────────────────────────────

export const onEventRequestUpdated = onDocumentUpdated(
  "eventRequests/{requestId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;

    if (before["status"] !== "pending" || after["status"] !== "approved") return;
    if (!(await claimEventOnce(event.id))) return;

    const uid = after["uid"] as string | undefined;
    if (!uid) return;

    const tokens = await getTokens(uid);
    const eventName = (after["eventName"] as string | undefined) ?? "Dein Event";

    await sendNotification(tokens, uid, {
      title: "Event angenommen 🎉",
      body: `„${eventName}" wurde von uns veröffentlicht!`,
      data: {
        type: "event_request_approved",
        requestId: event.params["requestId"],
      },
    });
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// Event bearbeitet (Name/Datum geändert) → verknüpfte Fahrten aktualisieren,
// damit "vergangene Fahrten" nicht dauerhaft den alten Namen/Datum zeigen.
// ──────────────────────────────────────────────────────────────────────────────

const FIRESTORE_BATCH_LIMIT = 500;

async function batchUpdateAll(
  docs: FirebaseFirestore.QueryDocumentSnapshot[],
  data: Record<string, unknown>
): Promise<void> {
  for (let i = 0; i < docs.length; i += FIRESTORE_BATCH_LIMIT) {
    const chunk = docs.slice(i, i + FIRESTORE_BATCH_LIMIT);
    const batch = db.batch();
    chunk.forEach((doc) => batch.update(doc.ref, data));
    await batch.commit();
  }
}

export const onEventUpdated = onDocumentUpdated(
  "events/{eventId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;

    const nameChanged = before["name"] !== after["name"];
    const datumChanged = before["datum"] !== after["datum"];
    if (!nameChanged && !datumChanged) return;

    const eventId = event.params["eventId"];
    const fahrtenSnap = await db.collection("fahrten")
      .where("eventId", "==", eventId)
      .get();
    if (fahrtenSnap.empty) return;

    const update: Record<string, unknown> = {};
    if (nameChanged) update["eventName"] = after["name"];
    if (datumChanged) {
      const parsed = new Date(after["datum"] as string);
      if (!isNaN(parsed.getTime())) {
        update["eventDatum"] = parsed.getTime();
      }
    }
    if (Object.keys(update).length === 0) return;

    await batchUpdateAll(fahrtenSnap.docs, update);

    console.log(`[onEventUpdated] ${fahrtenSnap.size} Fahrten aktualisiert für Event ${eventId}`);
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// Täglicher Cleanup: offene Anfragen löschen, deren Event > 48h vergangen ist
// ──────────────────────────────────────────────────────────────────────────────

// ──────────────────────────────────────────────────────────────────────────────
// Täglicher Cleanup: alte Idempotenz-Marker aus claimEventOnce() löschen,
// damit die processedTriggerEvents-Collection nicht unbegrenzt wächst.
// ──────────────────────────────────────────────────────────────────────────────

export const cleanupProcessedTriggerEvents = onSchedule(
  {schedule: "every day 02:00", timeZone: "Europe/Vienna"},
  async () => {
    const cutoff = admin.firestore.Timestamp.fromMillis(
      Date.now() - 7 * 24 * 60 * 60 * 1000
    );
    const snapshot = await db
      .collection("processedTriggerEvents")
      .where("at", "<", cutoff)
      .get();

    if (snapshot.empty) return;

    for (let i = 0; i < snapshot.docs.length; i += FIRESTORE_BATCH_LIMIT) {
      const chunk = snapshot.docs.slice(i, i + FIRESTORE_BATCH_LIMIT);
      const batch = db.batch();
      chunk.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }

    console.log(`Cleanup: ${snapshot.size} alte Idempotenz-Marker gelöscht`);
  }
);

export const cleanupAbgelaufeneAnfragen = onSchedule(
  {schedule: "every day 03:00", timeZone: "Europe/Vienna"},
  async () => {
    const cutoff = Date.now() - 48 * 60 * 60 * 1000;
    const snapshot = await db
      .collection("anfragen")
      .where("status", "==", 0) // AnfrageStatus.offen
      .where("eventDatum", "<", cutoff)
      .get();

    if (snapshot.empty) return;

    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    console.log(`Cleanup: ${snapshot.size} abgelaufene Anfragen gelöscht`);
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// Täglicher Cleanup: abgelaufene Events + verknüpfte Daten löschen
// Reihenfolge: anfragen → fahrten → interessenten → event
// anfragen zuerst, damit onFahrtDeleted keine Spurious-Notifications schickt
// ──────────────────────────────────────────────────────────────────────────────

export const cleanupAbgelaufeneEvents = onSchedule(
  {schedule: "every day 04:00", timeZone: "Europe/Vienna"},
  async () => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 30);
    cutoff.setUTCHours(0, 0, 0, 0);
    const cutoffStr = cutoff.toISOString();

    const eventsSnap = await db.collection("events")
      .where("datum", "<", cutoffStr)
      .get();
    if (eventsSnap.empty) return;

    for (const eventDoc of eventsSnap.docs) {
      const eventId = eventDoc.id;

      const anfragenSnap = await db.collection("anfragen")
        .where("eventId", "==", eventId).get();
      if (!anfragenSnap.empty) {
        const batch = db.batch();
        anfragenSnap.docs.forEach((d) => batch.delete(d.ref));
        await batch.commit();
      }

      const fahrtenSnap = await db.collection("fahrten")
        .where("eventId", "==", eventId).get();
      if (!fahrtenSnap.empty) {
        for (const fahrtDoc of fahrtenSnap.docs) {
          const convsSnap = await db.collection("chat_conversations")
            .where("fahrtId", "==", fahrtDoc.id).get();
          for (const convDoc of convsSnap.docs) {
            const msgsSnap = await convDoc.ref.collection("messages").get();
            if (!msgsSnap.empty) {
              const batch = db.batch();
              msgsSnap.docs.forEach((d) => batch.delete(d.ref));
              await batch.commit();
            }
            await convDoc.ref.delete();
          }
        }
        const batch = db.batch();
        fahrtenSnap.docs.forEach((d) => batch.delete(d.ref));
        await batch.commit();
      }

      const interessentenSnap = await db.collection("interessenten")
        .where("eventId", "==", eventId).get();
      if (!interessentenSnap.empty) {
        const batch = db.batch();
        interessentenSnap.docs.forEach((d) => batch.delete(d.ref));
        await batch.commit();
      }

      await eventDoc.ref.delete();
    }

    console.log(`[cleanupAbgelaufeneEvents] ${eventsSnap.size} Events + verknüpfte Daten gelöscht`);
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// E-Mail-Verifikation (eigener Versand, umgeht Firebase Console)
// ──────────────────────────────────────────────────────────────────────────────

export const sendVerificationEmail = onCall(async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Nicht eingeloggt");
    }

    const uid = request.auth.uid;
    const userRecord = await admin.auth().getUser(uid);
    const email = userRecord.email;

    if (!email) throw new HttpsError("not-found", "Keine E-Mail-Adresse");
    if (userRecord.emailVerified) return {alreadyVerified: true};

    // Firebase Admin generiert den oobCode – wir bauen daraus unsere eigene URL
    const firebaseLink = await admin.auth().generateEmailVerificationLink(email, {
      url: "https://eventride.at/auth/email-action.html",
    });

    const linkUrl = new URL(firebaseLink);
    const oobCode = linkUrl.searchParams.get("oobCode") ?? "";
    const apiKey = linkUrl.searchParams.get("apiKey") ?? "";

    const verifyUrl =
      `https://eventride.at/auth/email-action.html` +
      `?mode=verifyEmail&oobCode=${encodeURIComponent(oobCode)}&apiKey=${encodeURIComponent(apiKey)}`;

    const transporter = nodemailer.createTransport({
      host: "smtp.world4you.com",
      port: 587,
      secure: false,
      auth: {
        user: "kontakt@eventride.at",
        pass: process.env.EMAIL_PASS,
      },
    });

    const htmlBody = `
<!DOCTYPE html>
<html lang="de">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#0d1b3e;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#0d1b3e;padding:40px 16px">
    <tr><td align="center">
      <table width="100%" style="max-width:480px;background:rgba(255,255,255,0.07);border-radius:20px;border:1px solid rgba(255,255,255,0.12);padding:40px 32px">
        <tr><td align="center" style="padding-bottom:24px">
          <span style="font-size:26px;font-weight:700;color:#52A1EF;letter-spacing:-0.5px">EventRide</span>
        </td></tr>
        <tr><td align="center" style="padding-bottom:12px">
          <p style="font-size:22px;font-weight:600;color:#ffffff;margin:0">E-Mail bestätigen</p>
        </td></tr>
        <tr><td align="center" style="padding-bottom:28px">
          <p style="font-size:15px;color:rgba(255,255,255,0.65);line-height:1.6;margin:0">
            Klicke auf den Button um deine E-Mail-Adresse zu bestätigen<br>und EventRide zu nutzen.
          </p>
        </td></tr>
        <tr><td align="center" style="padding-bottom:28px">
          <a href="${verifyUrl}" style="display:inline-block;padding:16px 40px;background:linear-gradient(135deg,#52A1EF,#406CFB);color:#ffffff;border-radius:12px;font-size:16px;font-weight:600;text-decoration:none">
            E-Mail bestätigen
          </a>
        </td></tr>
        <tr><td align="center">
          <p style="font-size:12px;color:rgba(255,255,255,0.35);line-height:1.5;margin:0">
            Falls du dich nicht bei EventRide registriert hast, kannst du diese E-Mail ignorieren.<br>
            Der Link ist 24 Stunden gültig.
          </p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;

    await transporter.sendMail({
      from: '"EventRide" <kontakt@eventride.at>',
      to: email,
      subject: "EventRide – Bitte bestätige deine E-Mail-Adresse",
      html: htmlBody,
    });

    return {success: true};
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// Passwort-Reset (eigener Versand, umgeht Firebase Console)
//
// Anders als sendVerificationEmail MUSS diese Function ohne Login aufrufbar
// sein (der Nutzer ist ja gerade ausgesperrt). Deshalb zwei zusätzliche
// Schutzmaßnahmen, die es bei sendVerificationEmail nicht braucht:
// - Keine Nutzer-Enumeration: immer {success:true}, unabhängig davon ob die
//   E-Mail existiert (Fehler wird nur serverseitig geloggt).
// - Rate-Limit (60s pro E-Mail) gegen Mail-Bombing, da kein Auth-Check greift.
// ──────────────────────────────────────────────────────────────────────────────

export const sendPasswordResetEmailCustom = onCall(async (request) => {
  const email = (request.data?.email as string | undefined)?.trim().toLowerCase();
  if (!email) throw new HttpsError("invalid-argument", "E-Mail fehlt");

  const rateLimitRef = db.collection("password_reset_attempts").doc(email);
  const rateDoc = await rateLimitRef.get();
  const now = Date.now();
  if (rateDoc.exists && now - ((rateDoc.data()?.lastRequest as number | undefined) ?? 0) < 60_000) {
    // Stiller Erfolg — kein Hinweis nach außen, dass ein Rate-Limit gegriffen hat
    return {success: true};
  }
  await rateLimitRef.set({lastRequest: now});

  try {
    const firebaseLink = await admin.auth().generatePasswordResetLink(email, {
      url: "https://eventride.at/auth/password-reset.html",
    });

    const linkUrl = new URL(firebaseLink);
    const oobCode = linkUrl.searchParams.get("oobCode") ?? "";
    const apiKey = linkUrl.searchParams.get("apiKey") ?? "";

    const resetUrl =
      `https://eventride.at/auth/password-reset.html` +
      `?mode=resetPassword&oobCode=${encodeURIComponent(oobCode)}&apiKey=${encodeURIComponent(apiKey)}`;

    const transporter = nodemailer.createTransport({
      host: "smtp.world4you.com",
      port: 587,
      secure: false,
      auth: {
        user: "kontakt@eventride.at",
        pass: process.env.EMAIL_PASS,
      },
    });

    const htmlBody = `
<!DOCTYPE html>
<html lang="de">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#0d1b3e;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#0d1b3e;padding:40px 16px">
    <tr><td align="center">
      <table width="100%" style="max-width:480px;background:rgba(255,255,255,0.07);border-radius:20px;border:1px solid rgba(255,255,255,0.12);padding:40px 32px">
        <tr><td align="center" style="padding-bottom:24px">
          <span style="font-size:26px;font-weight:700;color:#52A1EF;letter-spacing:-0.5px">EventRide</span>
        </td></tr>
        <tr><td align="center" style="padding-bottom:12px">
          <p style="font-size:22px;font-weight:600;color:#ffffff;margin:0">Passwort zurücksetzen</p>
        </td></tr>
        <tr><td align="center" style="padding-bottom:28px">
          <p style="font-size:15px;color:rgba(255,255,255,0.65);line-height:1.6;margin:0">
            Klicke auf den Button um ein neues Passwort für dein EventRide-Konto festzulegen.
          </p>
        </td></tr>
        <tr><td align="center" style="padding-bottom:28px">
          <a href="${resetUrl}" style="display:inline-block;padding:16px 40px;background:linear-gradient(135deg,#52A1EF,#406CFB);color:#ffffff;border-radius:12px;font-size:16px;font-weight:600;text-decoration:none">
            Passwort zurücksetzen
          </a>
        </td></tr>
        <tr><td align="center">
          <p style="font-size:12px;color:rgba(255,255,255,0.35);line-height:1.5;margin:0">
            Falls du das nicht angefordert hast, kannst du diese E-Mail ignorieren — dein Passwort bleibt unverändert.<br>
            Der Link ist 1 Stunde gültig.
          </p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;

    await transporter.sendMail({
      from: '"EventRide" <kontakt@eventride.at>',
      to: email,
      subject: "EventRide – Passwort zurücksetzen",
      html: htmlBody,
    });
  } catch (err) {
    // z.B. auth/user-not-found — bewusst NICHT nach außen geben (Enumeration-Schutz)
    console.error("[sendPasswordResetEmailCustom]", err);
  }

  return {success: true};
});

// ──────────────────────────────────────────────────────────────────────────────
// Account-Deletion Cleanup: Chat-Conversations + Messages löschen
// Wird serverseitig ausgelöst, damit die Firestore-Rules kein client-seitiges
// delete auf chat_conversations erlauben müssen.
// ──────────────────────────────────────────────────────────────────────────────
export const cleanupDeletedUser = auth.user().onDelete(async (user) => {
  const uid = user.uid;

  const chatsSnap = await db
    .collection("chat_conversations")
    .where("participants", "array-contains", uid)
    .get();

  for (const chatDoc of chatsSnap.docs) {
    const msgsSnap = await chatDoc.ref.collection("messages").get();
    const batch = db.batch();
    for (const msg of msgsSnap.docs) batch.delete(msg.ref);
    batch.delete(chatDoc.ref);
    await batch.commit();
  }
});
