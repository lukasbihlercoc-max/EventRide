/**
 * Erstellt Screenshot-Testdaten in Firestore und Firebase Auth.
 *
 * Erstellt:
 *   - 5 Fake-User (Firestore-Dokumente + 2 echte Auth-Accounts zum Einloggen)
 *   - 5 Events (zukünftige Termine in Kärnten)
 *   - 5 Fahrten (diverse Strecken, Richtungen, Uhrzeiten)
 *   - 4 Anfragen (2 akzeptiert, 2 offen)
 *   - 2 Chat-Conversations mit realistischen Nachrichten
 *
 * Login-Accounts für die App:
 *   max.mueller@eventride-test.at    /  Test1234!
 *   karin.steiner@eventride-test.at  /  Test1234!
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
  MAX:   'screenshot_user_max',
  KARIN: 'screenshot_user_karin',
  LISA:  'screenshot_user_lisa',
  TOM:   'screenshot_user_tom',
  ANNA:  'screenshot_user_anna',
};

const EV = {
  KIRCHTAG:    'screenshot_event_kirchtag',
  BALL:        'screenshot_event_ball',
  FESTIVAL:    'screenshot_event_festival',
  WOLFSBERG:   'screenshot_event_wolfsberg',
  VOELKERMARKT:'screenshot_event_voelkermarkt',
};

const FA = {
  KIRCHTAG:    'screenshot_fahrt_kirchtag',
  BALL:        'screenshot_fahrt_ball',
  FESTIVAL:    'screenshot_fahrt_festival',
  WOLFSBERG:   'screenshot_fahrt_wolfsberg',
  VOELKERMARKT:'screenshot_fahrt_voelkermarkt',
};

// ── Hilfsfunktionen ──────────────────────────────────────────────────────────

function convId(fahrtId, uidA, uidB) {
  return `${fahrtId}_${[uidA, uidB].sort().join('_')}`;
}

function hoursAgo(h) {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() - h * 60 * 60 * 1000));
}

function daysFromNow(n) {
  const d = new Date();
  d.setDate(d.getDate() + n);
  d.setUTCHours(0, 0, 0, 0);
  return d;
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
    email: 'lisa.wagner@example.com',
    emailVerified: true,
    phoneVerified: false,
    licenseStatus: 'none',
    homeTown: 'Klagenfurt',
    homeTownLat: 46.6228,
    homeTownLng: 14.3050,
    ratingAvg: 5.0,
    ratingCount: 3,
    isTestData: true,
  },
  {
    id: U.TOM,
    userId: U.TOM,
    name: 'Tom Berger',
    email: 'tom.berger@example.com',
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
  {
    id: U.ANNA,
    userId: U.ANNA,
    name: 'Anna Hofer',
    email: 'anna.hofer@example.com',
    emailVerified: true,
    phoneVerified: true,
    licenseStatus: 'none',
    homeTown: 'Feldkirchen',
    homeTownLat: 46.7211,
    homeTownLng: 14.0989,
    ratingAvg: 4.5,
    ratingCount: 2,
    isTestData: true,
  },
];

// Datum als UTC-ISO8601 (wie die App es erwartet)
const E_DATES = {
  KIRCHTAG:    daysFromNow(23), // ~27. Juni
  BALL:        daysFromNow(31), // ~5. Juli
  FESTIVAL:    daysFromNow(38), // ~12. Juli
  WOLFSBERG:   daysFromNow(45), // ~19. Juli
  VOELKERMARKT:daysFromNow(59), // ~2. August
};

const EVENTS_DATA = [
  {
    id: EV.KIRCHTAG,
    name: 'Klagenfurter Kirchtag 2026',
    datum: E_DATES.KIRCHTAG.toISOString(),
    standort: 'Klagenfurt',
    typ: 'Kirchtag',
    beschreibung: 'Der größte Kirchtag Kärntens! Fahrgeschäfte, Buden, Live-Musik und gute Stimmung am Neuen Platz.',
    adresse: 'Neuer Platz 1, 9020 Klagenfurt',
    latitude: 46.6228,
    longitude: 14.3050,
    isTestData: true,
  },
  {
    id: EV.BALL,
    name: 'Großer Villacher Faschingsball 2026',
    datum: E_DATES.BALL.toISOString(),
    standort: 'Villach',
    typ: 'Ball',
    beschreibung: 'Der bekannteste Faschingsball Kärntens im Congress Center Villach. Kostüme ausdrücklich erwünscht!',
    adresse: 'Congress Center, Europaplatz 1, 9500 Villach',
    latitude: 46.6111,
    longitude: 13.8558,
    isTestData: true,
  },
  {
    id: EV.FESTIVAL,
    name: 'Wörthersee Festival 2026',
    datum: E_DATES.FESTIVAL.toISOString(),
    standort: 'Klagenfurt',
    typ: 'Festival',
    beschreibung: 'Sommerliches Musikfestival am Wörthersee mit österreichischen und internationalen Künstlern.',
    adresse: 'Strandbad Klagenfurt, Strandbadstraße 1',
    latitude: 46.6106,
    longitude: 14.1225,
    isTestData: true,
  },
  {
    id: EV.WOLFSBERG,
    name: 'Wolfsberger Stadtfest 2026',
    datum: E_DATES.WOLFSBERG.toISOString(),
    standort: 'Wolfsberg',
    typ: 'Konzert',
    beschreibung: 'Jährliches Stadtfest in Wolfsberg mit Livemusik, Kulinarik und Unterhaltung für die ganze Familie.',
    adresse: 'Hauptplatz, 9400 Wolfsberg',
    latitude: 46.8394,
    longitude: 14.8421,
    isTestData: true,
  },
  {
    id: EV.VOELKERMARKT,
    name: 'Völkermarkter Stadtfest 2026',
    datum: E_DATES.VOELKERMARKT.toISOString(),
    standort: 'Völkermarkt',
    typ: 'Konzert',
    beschreibung: 'Traditionsreiches Stadtfest mit Live-Bands, dem bekannten Handwerkermarkt und regionaler Küche.',
    adresse: 'Hauptplatz, 9100 Völkermarkt',
    latitude: 46.6572,
    longitude: 14.6344,
    isTestData: true,
  },
];

const FAHRTEN_DATA = [
  {
    id: FA.KIRCHTAG,
    eventId: EV.KIRCHTAG,
    eventName: 'Klagenfurter Kirchtag 2026',
    standort: 'Klagenfurt',
    abfahrtsort: 'Hauptplatz, Wolfsberg',
    abfahrtsortFullAddress: 'Hauptplatz 1, 9400 Wolfsberg',
    abfahrtsortLat: 46.8394,
    abfahrtsortLng: 14.8421,
    uhrzeitHour: 10, uhrzeitMinute: 30,
    rueckuhrzeitHour: 22, rueckuhrzeitMinute: 0,
    freiePlaetze: 2,
    richtung: 2, // hinUndZurueck
    ownerId: U.MAX,
    ownerName: 'Max Müller',
    eventDatum: E_DATES.KIRCHTAG.getTime(),
    isTestData: true,
  },
  {
    id: FA.BALL,
    eventId: EV.BALL,
    eventName: 'Großer Villacher Faschingsball 2026',
    standort: 'Villach',
    abfahrtsort: 'Bahnhof Spittal-Millstättersee',
    abfahrtsortFullAddress: 'Bahnhofstraße 5, 9800 Spittal an der Drau',
    abfahrtsortLat: 46.7967,
    abfahrtsortLng: 13.4972,
    uhrzeitHour: 19, uhrzeitMinute: 0,
    rueckuhrzeitHour: 2, rueckuhrzeitMinute: 30,
    freiePlaetze: 3,
    richtung: 2,
    ownerId: U.KARIN,
    ownerName: 'Karin Steiner',
    eventDatum: E_DATES.BALL.getTime(),
    isTestData: true,
  },
  {
    id: FA.FESTIVAL,
    eventId: EV.FESTIVAL,
    eventName: 'Wörthersee Festival 2026',
    standort: 'Klagenfurt',
    abfahrtsort: 'Völkermarkt Zentrum',
    abfahrtsortFullAddress: 'Hauptplatz 5, 9100 Völkermarkt',
    abfahrtsortLat: 46.6572,
    abfahrtsortLng: 14.6344,
    uhrzeitHour: 14, uhrzeitMinute: 0,
    rueckuhrzeitHour: 23, rueckuhrzeitMinute: 30,
    freiePlaetze: 3,
    richtung: 2,
    ownerId: U.MAX,
    ownerName: 'Max Müller',
    eventDatum: E_DATES.FESTIVAL.getTime(),
    isTestData: true,
  },
  {
    id: FA.WOLFSBERG,
    eventId: EV.WOLFSBERG,
    eventName: 'Wolfsberger Stadtfest 2026',
    standort: 'Wolfsberg',
    abfahrtsort: 'Villach Hauptbahnhof',
    abfahrtsortFullAddress: 'Bahnhofplatz 1, 9500 Villach',
    abfahrtsortLat: 46.6111,
    abfahrtsortLng: 13.8558,
    uhrzeitHour: 16, uhrzeitMinute: 0,
    rueckuhrzeitHour: 23, rueckuhrzeitMinute: 0,
    freiePlaetze: 2,
    richtung: 2,
    ownerId: U.TOM,
    ownerName: 'Tom Berger',
    eventDatum: E_DATES.WOLFSBERG.getTime(),
    isTestData: true,
  },
  {
    id: FA.VOELKERMARKT,
    eventId: EV.VOELKERMARKT,
    eventName: 'Völkermarkter Stadtfest 2026',
    standort: 'Völkermarkt',
    abfahrtsort: 'Klagenfurt, Heiligengeistplatz',
    abfahrtsortFullAddress: 'Heiligengeistplatz, 9020 Klagenfurt',
    abfahrtsortLat: 46.6228,
    abfahrtsortLng: 14.3050,
    uhrzeitHour: 17, uhrzeitMinute: 30,
    rueckuhrzeitHour: null, rueckuhrzeitMinute: null,
    freiePlaetze: 1,
    richtung: 0, // nur Hinfahrt
    ownerId: U.KARIN,
    ownerName: 'Karin Steiner',
    eventDatum: E_DATES.VOELKERMARKT.getTime(),
    isTestData: true,
  },
];

const ANFRAGEN_DATA = [
  {
    id: 'screenshot_anfrage_lisa_kirchtag',
    fahrtId: FA.KIRCHTAG,
    eventId: EV.KIRCHTAG,
    requesterId: U.LISA,
    requesterName: 'Lisa Wagner',
    seatsRequested: 1,
    status: 1, // akzeptiert
    createdAt: Date.now() - 2 * 24 * 60 * 60 * 1000,
    updatedAt: Date.now() - 1 * 24 * 60 * 60 * 1000,
    fahrtOwnerId: U.MAX,
    message: 'Hallo, hätte gerne einen Mitfahrplatz 😊',
    seatsAccepted: 1,
    eventName: 'Klagenfurter Kirchtag 2026',
    startOrt: 'Hauptplatz, Wolfsberg',
    zielOrt: 'Klagenfurt',
    fahrerName: 'Max Müller',
    vonFahrer: false,
    eventDatum: E_DATES.KIRCHTAG.getTime(),
    isTestData: true,
  },
  {
    id: 'screenshot_anfrage_anna_ball',
    fahrtId: FA.BALL,
    eventId: EV.BALL,
    requesterId: U.ANNA,
    requesterName: 'Anna Hofer',
    seatsRequested: 1,
    status: 1, // akzeptiert
    createdAt: Date.now() - 3 * 24 * 60 * 60 * 1000,
    updatedAt: Date.now() - 2 * 24 * 60 * 60 * 1000,
    fahrtOwnerId: U.KARIN,
    message: 'Super, ich suche genau eine Mitfahrgelegenheit nach Villach!',
    seatsAccepted: 1,
    eventName: 'Großer Villacher Faschingsball 2026',
    startOrt: 'Bahnhof Spittal-Millstättersee',
    zielOrt: 'Villach',
    fahrerName: 'Karin Steiner',
    vonFahrer: false,
    eventDatum: E_DATES.BALL.getTime(),
    isTestData: true,
  },
  {
    id: 'screenshot_anfrage_tom_festival',
    fahrtId: FA.FESTIVAL,
    eventId: EV.FESTIVAL,
    requesterId: U.TOM,
    requesterName: 'Tom Berger',
    seatsRequested: 2,
    status: 0, // offen
    createdAt: Date.now() - 12 * 60 * 60 * 1000,
    updatedAt: Date.now() - 12 * 60 * 60 * 1000,
    fahrtOwnerId: U.MAX,
    message: 'Hallo! Könnten wir 2 Plätze haben? Fahre mit meiner Freundin. 🙏',
    seatsAccepted: null,
    eventName: 'Wörthersee Festival 2026',
    startOrt: 'Völkermarkt Zentrum',
    zielOrt: 'Klagenfurt',
    fahrerName: 'Max Müller',
    vonFahrer: false,
    eventDatum: E_DATES.FESTIVAL.getTime(),
    isTestData: true,
  },
  {
    id: 'screenshot_anfrage_lisa_wolfsberg',
    fahrtId: FA.WOLFSBERG,
    eventId: EV.WOLFSBERG,
    requesterId: U.LISA,
    requesterName: 'Lisa Wagner',
    seatsRequested: 1,
    status: 0, // offen
    createdAt: Date.now() - 6 * 60 * 60 * 1000,
    updatedAt: Date.now() - 6 * 60 * 60 * 1000,
    fahrtOwnerId: U.TOM,
    message: 'Bitte um einen Platz, bin pünktlich! Danke 🙏',
    seatsAccepted: null,
    eventName: 'Wolfsberger Stadtfest 2026',
    startOrt: 'Villach Hauptbahnhof',
    zielOrt: 'Wolfsberg',
    fahrerName: 'Tom Berger',
    vonFahrer: false,
    eventDatum: E_DATES.WOLFSBERG.getTime(),
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

  // 1. Firebase Auth Accounts (nur Max + Karin, da die App eine echte Anmeldung braucht)
  console.log('🔑  Firebase Auth…');
  await createAuthUser(U.MAX,   'max.mueller@eventride-test.at',   'Test1234!', 'Max Müller');
  await createAuthUser(U.KARIN, 'karin.steiner@eventride-test.at', 'Test1234!', 'Karin Steiner');

  // 2. User-Dokumente
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

  // 6. Chat Conversations
  console.log('\n💬  Chat…');

  const conv1 = convId(FA.KIRCHTAG, U.MAX, U.LISA);
  const conv2 = convId(FA.BALL,     U.KARIN, U.ANNA);

  const fa1 = FAHRTEN_DATA.find(f => f.id === FA.KIRCHTAG);
  const fa2 = FAHRTEN_DATA.find(f => f.id === FA.BALL);

  const CHAT_MESSAGES = {
    [conv1]: [
      { id: `${conv1}_msg1`, sender: U.MAX,  text: 'Hallo Lisa! Deine Anfrage wurde akzeptiert 😊', hAgo: 25 },
      { id: `${conv1}_msg2`, sender: U.LISA, text: 'Super, danke! Wo genau ist der Treffpunkt?',    hAgo: 24.5 },
      { id: `${conv1}_msg3`, sender: U.MAX,  text: 'Am Hauptplatz beim Brunnen. Pünktlich um 10:30 🚗', hAgo: 24 },
      { id: `${conv1}_msg4`, sender: U.LISA, text: 'Perfekt, ich bin dabei! Danke 🙂',              hAgo: 23 },
    ],
    [conv2]: [
      { id: `${conv2}_msg1`, sender: U.KARIN, text: 'Hallo Anna! Freue mich schon auf die gemeinsame Fahrt 🎊', hAgo: 50 },
      { id: `${conv2}_msg2`, sender: U.ANNA,  text: 'Ich mich auch! Soll ich etwas mitbringen?',               hAgo: 49 },
      { id: `${conv2}_msg3`, sender: U.KARIN, text: 'Nein danke 😊 Abfahrt: Bahnhofstraße 5, Spittal. Parkplatz beim Bahnhof.', hAgo: 48 },
      { id: `${conv2}_msg4`, sender: U.ANNA,  text: 'Top, dann bis Samstag! 🎉',                              hAgo: 47 },
    ],
  };

  const lastMsg1 = CHAT_MESSAGES[conv1].at(-1);
  const lastMsg2 = CHAT_MESSAGES[conv2].at(-1);

  // Conversation-Dokumente anlegen
  await db.collection('chat_conversations').doc(conv1).set({
    id: conv1,
    fahrtId: FA.KIRCHTAG,
    ownerId: U.MAX,
    requesterId: U.LISA,
    participants: [U.MAX, U.LISA],
    lastMessage: lastMsg1.text,
    lastSenderId: lastMsg1.sender,
    lastMessageAt: hoursAgo(lastMsg1.hAgo),
    createdAt: hoursAgo(CHAT_MESSAGES[conv1][0].hAgo),
    isTestData: true,
  });

  await db.collection('chat_conversations').doc(conv2).set({
    id: conv2,
    fahrtId: FA.BALL,
    ownerId: U.KARIN,
    requesterId: U.ANNA,
    participants: [U.KARIN, U.ANNA],
    lastMessage: lastMsg2.text,
    lastSenderId: lastMsg2.sender,
    lastMessageAt: hoursAgo(lastMsg2.hAgo),
    createdAt: hoursAgo(CHAT_MESSAGES[conv2][0].hAgo),
    isTestData: true,
  });

  // System-Nachrichten
  const sysText1 =
    `🚗 Fahrt zum ${fa1.eventName}\n` +
    `📍 ${fa1.abfahrtsort} → ${fa1.standort}\n` +
    `🕒 ${String(fa1.uhrzeitHour).padStart(2,'0')}:${String(fa1.uhrzeitMinute).padStart(2,'0')} Uhr\n` +
    `🔄 Rückfahrt: ${String(fa1.rueckuhrzeitHour).padStart(2,'0')}:${String(fa1.rueckuhrzeitMinute).padStart(2,'0')} Uhr\n` +
    `👤 Fahrer: ${fa1.ownerName}`;

  const sysText2 =
    `🚗 Fahrt zum ${fa2.eventName}\n` +
    `📍 ${fa2.abfahrtsort} → ${fa2.standort}\n` +
    `🕒 ${String(fa2.uhrzeitHour).padStart(2,'0')}:${String(fa2.uhrzeitMinute).padStart(2,'0')} Uhr\n` +
    `🔄 Rückfahrt: 02:30 Uhr\n` +
    `👤 Fahrerin: ${fa2.ownerName}`;

  // Alle Messages in einem Batch
  const bMsgs = db.batch();

  // System-Messages (feste ID = ${convId}_system)
  bMsgs.set(
    db.collection('chat_conversations').doc(conv1).collection('messages').doc(`${conv1}_system`),
    { conversationId: conv1, senderId: 'system', text: sysText1, createdAt: hoursAgo(26), isSystem: true, isTestData: true }
  );
  bMsgs.set(
    db.collection('chat_conversations').doc(conv2).collection('messages').doc(`${conv2}_system`),
    { conversationId: conv2, senderId: 'system', text: sysText2, createdAt: hoursAgo(51), isSystem: true, isTestData: true }
  );

  // Normale Nachrichten
  for (const [cId, msgs] of Object.entries(CHAT_MESSAGES)) {
    for (const m of msgs) {
      bMsgs.set(
        db.collection('chat_conversations').doc(cId).collection('messages').doc(m.id),
        { conversationId: cId, senderId: m.sender, text: m.text, createdAt: hoursAgo(m.hAgo), isSystem: false, isTestData: true }
      );
    }
  }

  await bMsgs.commit();
  console.log('  ✅  2 Conversations + 10 Nachrichten angelegt');

  // ── Zusammenfassung ───────────────────────────────────────────────────────
  const line = '─'.repeat(56);
  console.log(`\n${line}`);
  console.log('🎉  Screenshot-Testdaten erfolgreich angelegt!\n');
  console.log('📱  App-Logins:');
  console.log('   max.mueller@eventride-test.at    /  Test1234!  (Max, Fahrer)');
  console.log('   karin.steiner@eventride-test.at  /  Test1234!  (Karin, Fahrerin)\n');
  console.log('🗑️   Bereinigung: node scripts/delete_screenshot_data.js');
  console.log(`${line}\n`);

  process.exit(0);
}

seed().catch(err => {
  console.error('\n❌  Fehler:', err.message);
  console.error(err);
  process.exit(1);
});
