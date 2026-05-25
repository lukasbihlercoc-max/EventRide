import * as admin from "firebase-admin";
import {onDocumentCreated, onDocumentUpdated, onDocumentDeleted, onDocumentWritten} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";

admin.initializeApp();
const db = admin.firestore();

// ──────────────────────────────────────────────────────────────────────────────
// Hilfsfunktionen
// ──────────────────────────────────────────────────────────────────────────────

async function getTokens(userId: string): Promise<string[]> {
  const doc = await db.doc(`users/${userId}`).get();
  return (doc.data()?.fcmTokens as string[]) ?? [];
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

// ──────────────────────────────────────────────────────────────────────────────
// Trigger 1: Anfrage-Status geändert → Mitfahrer benachrichtigen
// ──────────────────────────────────────────────────────────────────────────────

export const onAnfrageUpdated = onDocumentUpdated(
  "anfragen/{anfrageId}",
  async (event) => {
    const change = event.data;
    if (!change) return;

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

    const vonFahrer = after["vonFahrer"] === true;
    // D1-Fix: Mitfahrer storniert eigene Anfrage → Fahrer benachrichtigen, nicht Mitfahrer
    const isMitfahrerStorniert = !vonFahrer && statusAfter === 3;
    const targetUserId = (vonFahrer || statusAfter === 3)
      ? (after["fahrtOwnerId"] as string | undefined)
      : (after["requesterId"] as string | undefined);
    if (!targetUserId) return;

    let title: string;
    let body: string;
    if (isMitfahrerStorniert) {
      title = "Anfrage zurückgezogen";
      body = `${after["requesterName"] ?? "Ein Mitfahrer"} hat die Anfrage zurückgezogen`;
    } else {
      title = vonFahrer ? `Einladung ${statusText}` : `Anfrage ${statusText}`;
      body = vonFahrer
        ? `${after["requesterName"] ?? "Ein Nutzer"} hat deine Einladung ${statusText}`
        : `${after["fahrerName"] ?? "Der Fahrer"} hat deine Anfrage ${statusText}`;
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

    const data = snap.data();
    const vonFahrer = data["vonFahrer"] === true;

    let targetUserId: string | undefined;
    let title: string;
    let body: string;

    if (vonFahrer) {
      // Fahrer lädt Interessenten ein → Interessent benachrichtigen
      targetUserId = data["requesterId"] as string | undefined;
      title = "Neue Einladung";
      body = `${data["fahrerName"] ?? "Ein Fahrer"} lädt dich zur Fahrt nach ${data["zielOrt"] ?? "?"} ein`;
    } else {
      // Mitfahrer fragt an → Fahrer benachrichtigen
      targetUserId = data["fahrtOwnerId"] as string | undefined;
      title = "Neue Anfrage";
      body = `${data["requesterName"] ?? "Jemand"} möchte mitfahren nach ${data["zielOrt"] ?? "?"}`;
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

    const fahrtId = event.params["fahrtId"];
    const eventName = (fahrt["eventName"] as string | undefined) ?? "das Event";
    const zielOrt = (fahrt["standort"] as string | undefined) ?? "?";
    const fahrerName = (fahrt["ownerName"] as string | undefined) ?? "Der Fahrer";

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

    const userName = (after["userName"] as string | undefined) ?? "Ein Nutzer";

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

    const data = snap.data();
    const userName = (data["userName"] as string | undefined) ?? "Ein Nutzer";
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
// Callable 7: Bewertung abgeben
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

    const tokens = await getTokens(targetUserId);
    const text = msg["text"] as string;
    const preview = text.length > 80 ? text.substring(0, 80) + "…" : text;

    await sendNotification(tokens, targetUserId, {
      title: "Neue Nachricht",
      body: preview,
      data: {
        type: "chat",
        conversationId: event.params["convId"],
        senderId: msg["senderId"] as string,
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
// Täglicher Cleanup: offene Anfragen löschen, deren Event > 48h vergangen ist
// ──────────────────────────────────────────────────────────────────────────────

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
    cutoff.setDate(cutoff.getDate() - 1);
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
