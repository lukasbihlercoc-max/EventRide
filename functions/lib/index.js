"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onMessageCreated = exports.onAnfrageUpdated = void 0;
const admin = require("firebase-admin");
const firestore_1 = require("firebase-functions/v2/firestore");
admin.initializeApp();
const db = admin.firestore();
// ──────────────────────────────────────────────────────────────────────────────
// Hilfsfunktionen
// ──────────────────────────────────────────────────────────────────────────────
async function getTokens(userId) {
    var _a, _b;
    const doc = await db.doc(`users/${userId}`).get();
    return (_b = (_a = doc.data()) === null || _a === void 0 ? void 0 : _a.fcmTokens) !== null && _b !== void 0 ? _b : [];
}
async function sendNotification(tokens, userId, payload) {
    if (!tokens.length)
        return;
    const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: { title: payload.title, body: payload.body },
        data: payload.data,
        android: { priority: "high" },
        apns: { payload: { aps: { sound: "default" } } },
    });
    // Ungültige Tokens aus Firestore entfernen
    const invalidTokens = [];
    response.responses.forEach((res, idx) => {
        var _a;
        if (!res.success &&
            ((_a = res.error) === null || _a === void 0 ? void 0 : _a.code) === "messaging/registration-token-not-registered") {
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
exports.onAnfrageUpdated = (0, firestore_1.onDocumentUpdated)("anfragen/{anfrageId}", async (event) => {
    const change = event.data;
    if (!change)
        return;
    const before = change.before.data();
    const after = change.after.data();
    if (before["status"] === after["status"])
        return;
    const statusMap = { 1: "akzeptiert", 2: "abgelehnt" };
    const statusText = statusMap[after["status"]];
    if (!statusText)
        return;
    const tokens = await getTokens(after["requesterId"]);
    await sendNotification(tokens, after["requesterId"], {
        title: `Anfrage ${statusText}`,
        body: `${after["fahrerName"]} hat deine Anfrage ${statusText}`,
        data: { type: "anfrage", anfrageId: event.params["anfrageId"] },
    });
});
// ──────────────────────────────────────────────────────────────────────────────
// Trigger 2: Neue Chat-Nachricht → anderen Teilnehmer benachrichtigen
// ──────────────────────────────────────────────────────────────────────────────
exports.onMessageCreated = (0, firestore_1.onDocumentCreated)("chat_conversations/{convId}/messages/{msgId}", async (event) => {
    var _a, _b, _c, _d;
    const snap = event.data;
    if (!snap)
        return;
    const msg = snap.data();
    if (msg["isSystem"] === true)
        return;
    const convSnap = await db
        .doc(`chat_conversations/${event.params["convId"]}`)
        .get();
    const conv = convSnap.data();
    if (!conv)
        return;
    const participants = conv["participants"];
    const targetUserId = participants.find((p) => p !== msg["senderId"]);
    if (!targetUserId)
        return;
    // Nicht senden wenn Empfänger gerade aktiv ist
    const userSnap = await db.doc(`users/${targetUserId}`).get();
    const lastSeen = (_b = (_a = userSnap.data()) === null || _a === void 0 ? void 0 : _a["lastSeen"]) === null || _b === void 0 ? void 0 : _b.toDate();
    if (lastSeen) {
        const msgTime = (_d = (_c = msg["createdAt"]) === null || _c === void 0 ? void 0 : _c.toDate()) !== null && _d !== void 0 ? _d : new Date();
        if (msgTime <= lastSeen)
            return;
    }
    const tokens = await getTokens(targetUserId);
    const text = msg["text"];
    const preview = text.length > 80 ? text.substring(0, 80) + "…" : text;
    await sendNotification(tokens, targetUserId, {
        title: "Neue Nachricht",
        body: preview,
        data: { type: "chat", conversationId: event.params["convId"] },
    });
});
//# sourceMappingURL=index.js.map