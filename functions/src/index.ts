import * as admin from "firebase-admin";
import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";

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

    if (before["status"] === after["status"]) return;

    const statusMap: Record<number, string> = {1: "akzeptiert", 2: "abgelehnt"};
    const statusText = statusMap[after["status"] as number];
    if (!statusText) return;

    const tokens = await getTokens(after["requesterId"] as string);
    await sendNotification(tokens, after["requesterId"] as string, {
      title: `Anfrage ${statusText}`,
      body: `${after["fahrerName"] as string} hat deine Anfrage ${statusText}`,
      data: {type: "anfrage", anfrageId: event.params["anfrageId"]},
    });
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// Trigger 2: Neue Chat-Nachricht → anderen Teilnehmer benachrichtigen
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
      data: {type: "chat", conversationId: event.params["convId"]},
    });
  }
);
