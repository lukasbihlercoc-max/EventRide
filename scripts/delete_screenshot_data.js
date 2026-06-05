/**
 * Löscht alle Screenshot-Testdaten aus Firestore + Firebase Auth.
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

const USER_IDS = [
  'screenshot_user_max',
  'screenshot_user_karin',
  'screenshot_user_lisa',
  'screenshot_user_tom',
  'screenshot_user_stefan',
];

const EVENT_IDS = [
  'screenshot_event_kirchtag',
  'screenshot_event_feuerwehr',
  'screenshot_event_ball',
];

const FAHRT_IDS = [
  'screenshot_fahrt_max',
  'screenshot_fahrt_karin',
  'screenshot_fahrt_tom',
  'screenshot_fahrt_lisa',
];

const ANFRAGE_IDS = [
  'screenshot_anfrage_stefan_max',
];

const AUTH_EMAILS = [
  'max.mueller@eventride-test.at',
  'karin.steiner@eventride-test.at',
  'lisa.wagner@eventride-test.at',
  'tom.berger@eventride-test.at',
];

function convId(fahrtId, uidA, uidB) {
  return `${fahrtId}_${[uidA, uidB].sort().join('_')}`;
}

const CONV_IDS = [
  convId('screenshot_fahrt_max', 'screenshot_user_max', 'screenshot_user_stefan'),
];

// ── Hilfsfunktionen ──────────────────────────────────────────────────────────

async function deleteDocs(collection, ids) {
  const batch = db.batch();
  ids.forEach(id => batch.delete(db.collection(collection).doc(id)));
  await batch.commit();
  console.log(`  ✅  ${ids.length} Docs aus '${collection}' gelöscht`);
}

async function deleteConversationWithMessages(cId) {
  const msgsSnap = await db.collection('chat_conversations').doc(cId).collection('messages').get();
  if (!msgsSnap.empty) {
    const batch = db.batch();
    msgsSnap.docs.forEach(d => batch.delete(d.ref));
    await batch.commit();
  }
  await db.collection('chat_conversations').doc(cId).delete();
  console.log(`  ✅  Conversation '${cId.substring(0, 45)}…' + ${msgsSnap.size} Msgs gelöscht`);
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
