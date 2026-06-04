/**
 * Erstellt 250 Test-Events in Firestore.
 * Alle Events bekommen `isTestData: true` für einfache Bereinigung.
 *
 * Voraussetzung: Service-Account-Key aus Firebase Console
 *   Firebase Console → Project Settings → Service Accounts → "Generate new private key"
 *   Speicher als: scripts/serviceAccountKey.json  (steht in .gitignore)
 *
 * Ausführen:
 *   node scripts/seed_events.js
 *   node scripts/seed_events.js 300   <- optional: andere Anzahl
 */

const admin = require('../functions/node_modules/firebase-admin');
const path  = require('path');
const fs    = require('fs');

const KEY_PATH  = path.join(__dirname, 'serviceAccountKey.json');
const PROJECT   = 'eventride-cd0e9';
const COUNT     = parseInt(process.argv[2] || '250', 10);
const BATCH_MAX = 499; // Firestore-Batch-Limit

// ── Credentials ────────────────────────────────────────────────────────────
if (!fs.existsSync(KEY_PATH)) {
  console.error(`\n❌  Kein Service-Account-Key gefunden unter:\n   ${KEY_PATH}\n`);
  console.error('Bitte aus Firebase Console herunterladen:');
  console.error('  Project Settings → Service Accounts → "Generate new private key"\n');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(KEY_PATH)),
  projectId: PROJECT,
});

const db = admin.firestore();

// ── Testdaten ───────────────────────────────────────────────────────────────
const EVENT_TYPES = ['Kirchtag', 'Ball', 'Konzert', 'Festival', 'Markt', 'Sportfest'];

const ORTE = [
  { standort: 'Klagenfurt',   lat: 46.6228, lng: 14.3050 },
  { standort: 'Villach',      lat: 46.6111, lng: 13.8558 },
  { standort: 'Wolfsberg',    lat: 46.8394, lng: 14.8421 },
  { standort: 'Feldkirchen',  lat: 46.7211, lng: 14.0989 },
  { standort: 'Spittal',      lat: 46.7967, lng: 13.4972 },
  { standort: 'Hermagor',     lat: 46.6267, lng: 13.3717 },
  { standort: 'Völkermarkt',  lat: 46.6572, lng: 14.6344 },
  { standort: 'St. Veit',     lat: 46.7700, lng: 14.3597 },
  { standort: 'Friesach',     lat: 46.9639, lng: 14.4069 },
  { standort: 'Bleiburg',     lat: 46.5894, lng: 14.7958 },
  { standort: 'Gmünd',        lat: 46.9025, lng: 13.5297 },
  { standort: 'Radenthein',   lat: 46.8017, lng: 13.7169 },
];

const ADJEKTIVE = ['Großer', 'Traditioneller', 'Jährlicher', 'Festlicher', 'Bunter', 'Internationaler'];

function randomItem(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomDate() {
  // Events zwischen heute und +180 Tagen
  const now = Date.now();
  const offset = Math.floor(Math.random() * 180 * 24 * 60 * 60 * 1000);
  return new Date(now + offset);
}

function buildEvent(index) {
  const ort  = randomItem(ORTE);
  const typ  = randomItem(EVENT_TYPES);
  const adj  = randomItem(ADJEKTIVE);
  const date = randomDate();
  const id   = `test_${date.getTime()}_${index}`;

  // leichte Koordinaten-Streuung damit Events nicht alle exakt gleich
  const jitterLat = (Math.random() - 0.5) * 0.05;
  const jitterLng = (Math.random() - 0.5) * 0.05;

  return {
    id,
    name: `${adj}er ${ort.standort}er ${typ} ${date.getFullYear()} #${index + 1}`,
    datum: date.toISOString(),
    standort: ort.standort,
    typ,
    beschreibung: `Testdaten-Event ${index + 1}. Perfektes Wetter vorhergesagt, gute Stimmung garantiert.`,
    adresse: `Hauptplatz ${1 + (index % 20)}, ${ort.standort}`,
    latitude:  ort.lat  + jitterLat,
    longitude: ort.lng  + jitterLng,
    isTestData: true,
  };
}

// ── Batch-Write ──────────────────────────────────────────────────────────────
async function seed() {
  console.log(`\n📝  Erstelle ${COUNT} Test-Events in Firestore (${PROJECT})…\n`);

  let total = 0;
  while (total < COUNT) {
    const batchSize = Math.min(BATCH_MAX, COUNT - total);
    const batch = db.batch();

    for (let i = 0; i < batchSize; i++) {
      const event = buildEvent(total + i);
      batch.set(db.collection('events').doc(event.id), event);
    }

    await batch.commit();
    total += batchSize;
    process.stdout.write(`  ✅  ${total}/${COUNT} Events geschrieben\r`);
  }

  console.log(`\n\n🎉  Fertig! ${COUNT} Test-Events angelegt.`);
  console.log('    Zum Löschen: node scripts/delete_test_events.js\n');
  process.exit(0);
}

seed().catch(err => {
  console.error('\n❌  Fehler:', err.message);
  process.exit(1);
});
