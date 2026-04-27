import * as admin from "firebase-admin";
import {onDocumentCreated, onDocumentUpdated, onDocumentDeleted, onDocumentWritten} from "firebase-functions/v2/firestore";

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
    if (fahrtId) {
      if (statusAfter === 1) {
        // akzeptiert: Platz(e) belegen
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
    const targetUserId = vonFahrer
      ? (after["fahrtOwnerId"] as string | undefined)
      : (after["requesterId"] as string | undefined);
    if (!targetUserId) return;

    const title = vonFahrer
      ? `Einladung ${statusText}`
      : `Anfrage ${statusText}`;
    const body = vonFahrer
      ? `${after["requesterName"] ?? "Ein Nutzer"} hat deine Einladung ${statusText}`
      : `${after["fahrerName"] ?? "Der Fahrer"} hat deine Anfrage ${statusText}`;

    const tokens = await getTokens(targetUserId);
    if (!tokens.length) return;

    await sendNotification(tokens, targetUserId, {
      title,
      body,
      data: {type: "anfrage", anfrageId: event.params["anfrageId"]},
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
