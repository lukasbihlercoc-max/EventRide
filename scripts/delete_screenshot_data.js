/**
 * Löscht alle Screenshot-Testdaten aus Firestore + Firebase Auth.
 *
 * Löscht:
 *   - users          (IDs: screenshot_user_*)
 *   - events         (IDs: screenshot_event_*)
 *   - fahrten        (IDs: screenshot_fahrt_*)
 *   - anfragen       (IDs: screenshot_anfrage_*)
 *   - chat_conversations + ihre messages Subcollections
 *   - Firebase Auth Accounts (max + karin)
 *
 * Ausführen:
 *   node scripts/delete_screenshot_data.js
 */

const admin = require('../functions/node_modules/firebase-admin');
const path  = require('path');
const fs    = require('fs');

const KEY_PATH = path.join(__dirname, 'serviceAccountKey.json');
const PROJECT  = 'eventride-cd0e9';

if (!fs.existsSync(KEY_PATH)) {
  console.error(`\n❌  Kein Service-Account-Key gefunden:\n   ${KEY_PATH}\n`);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(KEY_PATH)),
  projectId: PROJECT,
});

const db   = admin.firestore();
const auth = admin.auth();

// ── Feste IDs (identisch mit seed_screenshot_data.js) ───────────────────────

const USER_IDS  = ['screenshot_user_max', 'screenshot_user_karin', 'screenshot_user_lisa', 'screenshot_user_tom', 'screenshot_user_anna'];
const EVENT_IDS = ['screenshot_event_kirchtag', 'screenshot_event_ball', 'screenshot_event_festival', 'screenshot_event_wolfsberg', 'screenshot_event_voelkermarkt'];
const FAHRT_IDS = ['screenshot_fahrt_kirchtag', 'screenshot_fahrt_ball', 'screenshot_fahrt_festival', 'screenshot_fahrt_wolfsberg', 'screenshot_fahrt_voelkermarkt'];
const ANFRAGE_IDS = ['screenshot_anfrage_lisa_kirchtag', 'screenshot_anfrage_anna_ball', 'screenshot_anfrage_tom_festival', 'screenshot_anfrage_lisa_wolfsberg'];

const AUTH_EMAILS = ['max.mueller@eventride-test.at', 'karin.steiner@eventride-test.at'];

function convId(fahrtId, uidA, uidB) {
  return `${fahrtId}_${[uidA, uidB].sort().join('_')}`;
}

const CONV_IDS = [
  convId('screenshot_fahrt_kirchtag', 'screenshot_user_max',   'screenshot_user_lisa'),
  convId('screenshot_fahrt_ball',     'screenshot_user_karin', 'screenshot_user_anna'),
];

// ── Hilfsfunktion ─────────────────────────────────────────────────────────────

async function deleteDocs(collection, ids) {
  const batch = db.batch();
  ids.forEach(id => batch.delete(db.collection(collection).doc(id)));
  await batch.commit();
  console.log(`  ✅  ${ids.length} Docs aus '${collection}' gelöscht`);
}

async function deleteConversationWithMessages(convId) {
  // Messages-Subcollection auslesen und löschen
  const msgsSnap = await db.collection('chat_conversations').doc(convId).collection('messages').get();
  if (!msgsSnap.empty) {
    const batch = db.batch();
    msgsSnap.docs.forEach(d => batch.delete(d.ref));
    await batch.commit();
  }
  // Conversation selbst löschen
  await db.collection('chat_conversations').doc(convId).delete();
  console.log(`  ✅  Conversation '${convId.substring(0, 40)}…' + ${msgsSnap.size} Msgs gelöscht`);
}

// ── Haupt-Funktion ────────────────────────────────────────────────────────────

async function deleteAll() {
  console.log('\n🗑️   Lösche Screenshot-Testdaten…\n');

  await deleteDocs('users',    USER_IDS);
  await deleteDocs('events',   EVENT_IDS);
  await deleteDocs('fahrten',  FAHRT_IDS);
  await deleteDocs('anfragen', ANFRAGE_IDS);

  console.log('\n💬  Chat-Conversations…');
  for (const cId of CONV_IDS) {
    await deleteConversationWithMessages(cId);
  }

  console.log('\n🔑  Firebase Auth Accounts…');
  for (const email of AUTH_EMAILS) {
    try {
      const user = await auth.getUserByEmail(email);
      await auth.deleteUser(user.uid);
      console.log(`  ✅  ${email} gelöscht`);
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        console.log(`  ℹ️  ${email} existiert nicht – übersprungen`);
      } else {
        throw e;
      }
    }
  }

  console.log('\n🎉  Alle Screenshot-Testdaten gelöscht.\n');
  process.exit(0);
}

deleteAll().catch(err => {
  console.error('\n❌  Fehler:', err.message);
  process.exit(1);
});
