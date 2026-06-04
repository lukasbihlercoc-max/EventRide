/**
 * Löscht alle Test-Events (isTestData: true) aus Firestore.
 *
 * Ausführen:
 *   node scripts/delete_test_events.js
 */

const admin = require('../functions/node_modules/firebase-admin');
const path  = require('path');
const fs    = require('fs');

const KEY_PATH  = path.join(__dirname, 'serviceAccountKey.json');
const PROJECT   = 'eventride-cd0e9';
const BATCH_MAX = 499;

if (!fs.existsSync(KEY_PATH)) {
  console.error(`\n❌  Kein Service-Account-Key gefunden unter:\n   ${KEY_PATH}\n`);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(KEY_PATH)),
  projectId: PROJECT,
});

const db = admin.firestore();

async function deleteTestEvents() {
  console.log('\n🗑️   Lade alle Test-Events…\n');

  const snapshot = await db.collection('events')
    .where('isTestData', '==', true)
    .get();

  if (snapshot.empty) {
    console.log('ℹ️   Keine Test-Events gefunden – nichts zu tun.\n');
    process.exit(0);
  }

  const docs = snapshot.docs;
  console.log(`  Gefunden: ${docs.length} Test-Events → werden gelöscht…\n`);

  let deleted = 0;
  while (deleted < docs.length) {
    const chunk = docs.slice(deleted, deleted + BATCH_MAX);
    const batch = db.batch();
    chunk.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    deleted += chunk.length;
    process.stdout.write(`  🗑️   ${deleted}/${docs.length} gelöscht\r`);
  }

  console.log(`\n\n✅  Fertig! ${docs.length} Test-Events gelöscht.\n`);
  process.exit(0);
}

deleteTestEvents().catch(err => {
  console.error('\n❌  Fehler:', err.message);
  process.exit(1);
});
