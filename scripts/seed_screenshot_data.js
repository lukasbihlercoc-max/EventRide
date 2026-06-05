/**
 * Erstellt Screenshot-Testdaten in Firestore und Firebase Auth.
 *
 * Erstellt:
 *   - 4 echte Auth-Accounts (zum Einloggen + Profilbild setzen)
 *   - 1 Firestore-Only-User (Stefan, für den Chat)
 *   - 3 Events (Villacher Kirchtag, Feuerwehrfest Paternion, HTL Maturaball)
 *   - 4 Fahrten zum Villacher Kirchtag (Hin-, Rück-, Hin+Zurück)
 *   - 1 Chat-Conversation (Max ↔ Lisa) mit System-Message
 *   - 1 akzeptierte Anfrage (Lisa → Max)
 *
 * Login-Accounts:
 *   max.mueller@eventride-test.at    /  Test1234!
 *   karin.steiner@eventride-test.at  /  Test1234!
 *   lisa.wagner@eventride-test.at    /  Test1234!
 *   tom.berger@eventride-test.at     /  Test1234!
 *
 * Alle Dokumente: isTestData: true
 * Bereinigung:
 *   node scripts/delete_screenshot_data.js
 *
 * Ausführen:
 *   node scripts/seed_screenshot_data.js
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

// ── Feste IDs ────────────────────────────────────────────────────────────────

const U = {
  MAX:    'screenshot_user_max',
  KARIN:  'screenshot_user_karin',
  LISA:   'screenshot_user_lisa',
  TOM:    'screenshot_user_tom',
  STEFAN: 'screenshot_user_stefan',
};

const EV = {
  KIRCHTAG:  'screenshot_event_kirchtag',
  FEUERWEHR: 'screenshot_event_feuerwehr',
  BALL:      'screenshot_event_ball',
};

const FA = {
  MAX:   'screenshot_fahrt_max',
  KARIN: 'screenshot_fahrt_karin',
  TOM:   'screenshot_fahrt_tom',
  LISA:  'screenshot_fahrt_lisa',
};

// ── Hilfsfunktionen ──────────────────────────────────────────────────────────

function convId(fahrtId, uidA, uidB) {
  return `${fahrtId}_${[uidA, uidB].sort().join('_')}`;
}

function hoursAgo(h) {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() - h * 60 * 60 * 1000));
}

function isoDate(dateStr) {
  // festes ISO-8601-Datum (UTC Mitternacht), wie die App es erwartet
  return new Date(dateStr + 'T00:00:00.000Z').toISOString();
}

function dateMs(dateStr) {
  return new Date(dateStr + 'T00:00:00.000Z').getTime();
}

// ── Kerndaten ─────────────────────────────────────────────────────────────────

const USERS_DATA = [
  {
    id: U.MAX,
    userId: U.MAX,
    name: 'Max Müller',
    email: 'max.mueller@eventride-test.at',
    emailVerified: true,
    phoneVerified: false,
    licenseStatus: 'verified',
    homeTown: 'Wolfsberg',
    homeTownLat: 46.8394,
    homeTownLng: 14.8421,
    car: { make: 'VW', model: 'Golf', color: 'Blau', seats: 4 },
    ratingAvg: 4.8,
    ratingCount: 12,
    isTestData: true,
  },
  {
    id: U.KARIN,
    userId: U.KARIN,
    name: 'Karin Steiner',
    email: 'karin.steiner@eventride-test.at',
    emailVerified: true,
    phoneVerified: true,
    licenseStatus: 'verified',
    homeTown: 'Spittal an der Drau',
    homeTownLat: 46.7967,
    homeTownLng: 13.4972,
    car: { make: 'BMW', model: '3er', color: 'Silber', seats: 4 },
    ratingAvg: 4.9,
    ratingCount: 7,
    isTestData: true,
  },
  {
    id: U.LISA,
    userId: U.LISA,
    name: 'Lisa Wagner',
    email: 'lisa.wagner@eventride-test.at',
    emailVerified: true,
    phoneVerified: false,
    licenseStatus: 'verified',
    homeTown: 'Feldkirchen',
    homeTownLat: 46.7211,
    homeTownLng: 14.0989,
    car: { make: 'Seat', model: 'Ibiza', color: 'Weiß', seats: 4 },
    ratingAvg: 5.0,
    ratingCount: 3,
    isTestData: true,
  },
  {
    id: U.TOM,
    userId: U.TOM,
    name: 'Tom Berger',
    email: 'tom.berger@eventride-test.at',
    emailVerified: true,
    phoneVerified: false,
    licenseStatus: 'verified',
    homeTown: 'Klagenfurt',
    homeTownLat: 46.6228,
    homeTownLng: 14.3050,
    car: { make: 'Audi', model: 'A3', color: 'Schwarz', seats: 4 },
    ratingAvg: 4.6,
    ratingCount: 5,
    isTestData: true,
  },
  {
    // Firestore-Only: kein Auth-Account, nur für den Chat-Gesprächspartner
    id: U.STEFAN,
    userId: U.STEFAN,
    name: 'Stefan Rainer',
    email: 'stefan.rainer@example.com',
    emailVerified: true,
    phoneVerified: false,
    licenseStatus: 'none',
    homeTown: 'Villach',
    homeTownLat: 46.6111,
    homeTownLng: 13.8558,
    ratingAvg: null,
    ratingCount: 0,
    isTestData: true,
  },
];

const EVENTS_DATA = [
  {
    id: EV.KIRCHTAG,
    name: 'Villacher Kirchtag 2026',
    datum: isoDate('2026-07-27'),
    standort: 'Villach',
    typ: 'e1',
    beschreibung: 'Der Villacher Kirchtag – das größte Volksfest Kärntens! Eine Woche Fahrgeschäfte, Buden, Live-Musik und ausgelassene Stimmung in der Innenstadt.',
    adresse: 'Hauptplatz, 9500 Villach',
    latitude: 46.6111,
    longitude: 13.8558,
    isTestData: true,
  },
  {
    id: EV.FEUERWEHR,
    name: 'Feuerwehrfest Paternion 2026',
    datum: isoDate('2026-08-18'),
    standort: 'Paternion',
    typ: 'e2',
    beschreibung: 'Das traditionelle Sommerfest der Freiwilligen Feuerwehr Paternion. Musik, Grillstand, Tombola und gute Unterhaltung für die ganze Familie.',
    adresse: 'FF-Gebäude Paternion, 9711 Paternion',
    latitude: 46.7117,
    longitude: 13.6247,
    isTestData: true,
  },
  {
    id: EV.BALL,
    name: 'HTL Klagenfurt Maturaball 2026',
    datum: isoDate('2026-11-15'),
    standort: 'Klagenfurt',
    typ: 'e4',
    beschreibung: 'Der Maturaball der HTL Klagenfurt im Casino Velden. Eleganter Abend mit Live-Band, Eröffnungswalzer und großer After-Party.',
    adresse: 'Casino Velden, Am Corso 17, 9220 Velden',
    latitude: 46.6160,
    longitude: 14.0356,
    isTestData: true,
  },
];

// Alle 4 Fahrten gehen zum Villacher Kirchtag – unterschiedliche Richtungen und Startpunkte
const FAHRTEN_DATA = [
  {
    // Max: Nur Hinfahrt – 10:30 Uhr ab Wolfsberg
    id: FA.MAX,
    eventId: EV.KIRCHTAG,
    eventName: 'Villacher Kirchtag 2026',
    standort: 'Villach',
    abfahrtsort: 'Hauptplatz, Wolfsberg',
    abfahrtsortFullAddress: 'Hauptplatz 1, 9400 Wolfsberg',
    abfahrtsortLat: 46.8394,
    abfahrtsortLng: 14.8421,
    uhrzeitHour: 10, uhrzeitMinute: 30,
    rueckuhrzeitHour: null, rueckuhrzeitMinute: null,
    freiePlaetze: 2,
    richtung: 0, // hinfahrt
    ownerId: U.MAX,
    ownerName: 'Max Müller',
    eventDatum: dateMs('2026-07-27'),
    isTestData: true,
  },
  {
    // Tom: Hin- und Rückfahrt – 11:30 / Rück 01:00 ab Klagenfurt
    id: FA.TOM,
    eventId: EV.KIRCHTAG,
    eventName: 'Villacher Kirchtag 2026',
    standort: 'Villach',
    abfahrtsort: 'Klagenfurt, Heiligengeistplatz',
    abfahrtsortFullAddress: 'Heiligengeistplatz, 9020 Klagenfurt',
    abfahrtsortLat: 46.6228,
    abfahrtsortLng: 14.3050,
    uhrzeitHour: 11, uhrzeitMinute: 30,
    rueckuhrzeitHour: 1, rueckuhrzeitMinute: 0,
    freiePlaetze: 3,
    richtung: 2, // hinUndZurueck
    ownerId: U.TOM,
    ownerName: 'Tom Berger',
    eventDatum: dateMs('2026-07-27'),
    isTestData: true,
  },
  {
    // Karin: Hin- und Rückfahrt – 14:00 / Rück 02:00 ab Spittal
    id: FA.KARIN,
    eventId: EV.KIRCHTAG,
    eventName: 'Villacher Kirchtag 2026',
    standort: 'Villach',
    abfahrtsort: 'Bahnhof Spittal-Millstättersee',
    abfahrtsortFullAddress: 'Bahnhofstraße 5, 9800 Spittal an der Drau',
    abfahrtsortLat: 46.7967,
    abfahrtsortLng: 13.4972,
    uhrzeitHour: 14, uhrzeitMinute: 0,
    rueckuhrzeitHour: 2, rueckuhrzeitMinute: 0,
    freiePlaetze: 2,
    richtung: 2, // hinUndZurueck
    ownerId: U.KARIN,
    ownerName: 'Karin Steiner',
    eventDatum: dateMs('2026-07-27'),
    isTestData: true,
  },
  {
    // Lisa: Nur Rückfahrt – 23:30 Uhr ab Villach Richtung Feldkirchen
    id: FA.LISA,
    eventId: EV.KIRCHTAG,
    eventName: 'Villacher Kirchtag 2026',
    standort: 'Villach',
    abfahrtsort: 'Villach, Hauptplatz',
    abfahrtsortFullAddress: 'Hauptplatz, 9500 Villach',
    abfahrtsortLat: 46.6111,
    abfahrtsortLng: 13.8558,
    uhrzeitHour: 23, uhrzeitMinute: 30,
    rueckuhrzeitHour: null, rueckuhrzeitMinute: null,
    freiePlaetze: 2,
    richtung: 1, // rueckfahrt
    ownerId: U.LISA,
    ownerName: 'Lisa Wagner',
    eventDatum: dateMs('2026-07-27'),
    isTestData: true,
  },
];

const ANFRAGEN_DATA = [
  {
    id: 'screenshot_anfrage_stefan_max',
    fahrtId: FA.MAX,
    eventId: EV.KIRCHTAG,
    requesterId: U.STEFAN,
    requesterName: 'Stefan Rainer',
    seatsRequested: 1,
    status: 1, // akzeptiert
    createdAt: Date.now() - 20 * 60 * 60 * 1000,
    updatedAt: Date.now() - 18 * 60 * 60 * 1000,
    fahrtOwnerId: U.MAX,
    message: 'Hallo! Hätte gerne einen Platz, bin zuverlässig 😊',
    seatsAccepted: 1,
    eventName: 'Villacher Kirchtag 2026',
    startOrt: 'Hauptplatz, Wolfsberg',
    zielOrt: 'Villach',
    fahrerName: 'Max Müller',
    vonFahrer: false,
    eventDatum: dateMs('2026-07-27'),
    isTestData: true,
  },
];

// ── Seed-Funktion ─────────────────────────────────────────────────────────────

async function createAuthUser(uid, email, password, name) {
  try {
    const existing = await auth.getUserByEmail(email);
    console.log(`  ℹ️  Auth bereits vorhanden: ${email} (${existing.uid})`);
    return;
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
  }
  await auth.createUser({ uid, email, password, displayName: name, emailVerified: true });
  console.log(`  ✅  Auth-Account erstellt: ${email}`);
}

async function seed() {
  console.log('\n📸  Erstelle Screenshot-Testdaten…\n');

  // 1. Firebase Auth Accounts (alle 4 einlogbaren User)
  console.log('🔑  Firebase Auth…');
  await createAuthUser(U.MAX,   'max.mueller@eventride-test.at',   'Test1234!', 'Max Müller');
  await createAuthUser(U.KARIN, 'karin.steiner@eventride-test.at', 'Test1234!', 'Karin Steiner');
  await createAuthUser(U.LISA,  'lisa.wagner@eventride-test.at',   'Test1234!', 'Lisa Wagner');
  await createAuthUser(U.TOM,   'tom.berger@eventride-test.at',    'Test1234!', 'Tom Berger');

  // 2. User-Dokumente (inkl. Stefan als Firestore-Only)
  console.log('\n👥  User-Dokumente…');
  const b1 = db.batch();
  USERS_DATA.forEach(u => b1.set(db.collection('users').doc(u.id), u, { merge: true }));
  await b1.commit();
  console.log(`  ✅  ${USERS_DATA.length} User angelegt`);

  // 3. Events
  console.log('\n🎪  Events…');
  const b2 = db.batch();
  EVENTS_DATA.forEach(e => b2.set(db.collection('events').doc(e.id), e));
  await b2.commit();
  console.log(`  ✅  ${EVENTS_DATA.length} Events angelegt`);

  // 4. Fahrten
  console.log('\n🚗  Fahrten…');
  const b3 = db.batch();
  FAHRTEN_DATA.forEach(f => b3.set(db.collection('fahrten').doc(f.id), f));
  await b3.commit();
  console.log(`  ✅  ${FAHRTEN_DATA.length} Fahrten angelegt`);

  // 5. Anfragen
  console.log('\n📋  Anfragen…');
  const b4 = db.batch();
  ANFRAGEN_DATA.forEach(a => b4.set(db.collection('anfragen').doc(a.id), a));
  await b4.commit();
  console.log(`  ✅  ${ANFRAGEN_DATA.length} Anfragen angelegt`);

  // 6. Chat (Max ↔ Stefan – Stefan hat Platz in Max' Hinfahrt gebucht)
  console.log('\n💬  Chat…');

  const conv = convId(FA.MAX, U.MAX, U.STEFAN);
  const fa   = FAHRTEN_DATA.find(f => f.id === FA.MAX);

  const sysText =
    `🚗 Fahrt zum ${fa.eventName}\n` +
    `📍 ${fa.abfahrtsort} → ${fa.standort}\n` +
    `🕒 ${String(fa.uhrzeitHour).padStart(2,'0')}:${String(fa.uhrzeitMinute).padStart(2,'0')} Uhr\n` +
    `👤 Fahrer: ${fa.ownerName}`;

  const MSGS = [
    { id: `${conv}_msg1`, sender: U.STEFAN, text: 'Hallo Max! Freue mich schon auf die Fahrt 😊 Wo genau treffen wir uns?', hAgo: 19 },
    { id: `${conv}_msg2`, sender: U.MAX,    text: 'Hallo Stefan! Am Hauptplatz beim Löwenbrunnen, 10:15 Uhr ☑️',           hAgo: 18.5 },
    { id: `${conv}_msg3`, sender: U.STEFAN, text: 'Super, erkenne ich dich am Auto?',                                       hAgo: 18 },
    { id: `${conv}_msg4`, sender: U.MAX,    text: 'Blauer VW Golf, Kennzeichen VB-12 😊',                                   hAgo: 17.5 },
    { id: `${conv}_msg5`, sender: U.STEFAN, text: 'Perfekt! Danke, bis Sonntag 🙌',                                         hAgo: 17 },
  ];

  const lastMsg = MSGS.at(-1);

  await db.collection('chat_conversations').doc(conv).set({
    id: conv,
    fahrtId: FA.MAX,
    ownerId: U.MAX,
    requesterId: U.STEFAN,
    participants: [U.MAX, U.STEFAN],
    lastMessage: lastMsg.text,
    lastSenderId: lastMsg.sender,
    lastMessageAt: hoursAgo(lastMsg.hAgo),
    createdAt: hoursAgo(MSGS[0].hAgo),
    isTestData: true,
  });

  const bMsgs = db.batch();

  // System-Message
  bMsgs.set(
    db.collection('chat_conversations').doc(conv).collection('messages').doc(`${conv}_system`),
    { conversationId: conv, senderId: 'system', text: sysText, createdAt: hoursAgo(20), isSystem: true, isTestData: true }
  );

  // Normale Nachrichten
  for (const m of MSGS) {
    bMsgs.set(
      db.collection('chat_conversations').doc(conv).collection('messages').doc(m.id),
      { conversationId: conv, senderId: m.sender, text: m.text, createdAt: hoursAgo(m.hAgo), isSystem: false, isTestData: true }
    );
  }

  await bMsgs.commit();
  console.log('  ✅  1 Conversation + 6 Nachrichten angelegt');

  // ── Zusammenfassung ───────────────────────────────────────────────────────
  const line = '─'.repeat(60);
  console.log(`\n${line}`);
  console.log('🎉  Screenshot-Testdaten erfolgreich angelegt!\n');
  console.log('📱  App-Logins (alle: Test1234!):');
  console.log('   max.mueller@eventride-test.at    →  Max Müller    (Wolfsberg, VW Golf)');
  console.log('   karin.steiner@eventride-test.at  →  Karin Steiner (Spittal, BMW 3er)');
  console.log('   lisa.wagner@eventride-test.at    →  Lisa Wagner   (Feldkirchen, Seat Ibiza)');
  console.log('   tom.berger@eventride-test.at     →  Tom Berger    (Klagenfurt, Audi A3)');
  console.log('\n💬  Chat: Max Müller ↔ Stefan Rainer (als Max einloggen für Screenshot)');
  console.log(`\n🗑️   Bereinigung: node scripts/delete_screenshot_data.js`);
  console.log(`${line}\n`);

  process.exit(0);
}

seed().catch(err => {
  console.error('\n❌  Fehler:', err.message);
  console.error(err);
  process.exit(1);
});
