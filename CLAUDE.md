# EventRide

## Website (eventride.at)

**Hosting:** World4You (FTP) — NICHT Firebase Hosting  
**Deployment:** `git push` → GitHub Actions (`.github/workflows/deploy-website.yml`) → FTP nach World4You  
**Manueller Trigger:** GitHub → Actions → "Deploy Website → World4You" → Run workflow  
**Dateien bearbeiten:** Immer in `public/` — nie in `web_assets/` (veraltetes Verzeichnis)

| Datei | Inhalt |
|-------|--------|
| `public/index.html` | Landing Page + interaktive App-Preview |
| `public/eventride_manager.html` | Admin-Panel (Events anlegen) |
| `public/assets/image/` | Event-Hintergrundbilder (kirchtag6.jpg etc.) |

**App-Preview** im `#screenshots`-Abschnitt: iPhone-Mockup mit 3 navigierbaren Screens,  
lädt echte Events aus Firestore, Design 1:1 wie die App (Gradient `#B79B78→#52A1EF→#406CFB`, Akzent `#F5A04A`).

---

## Automatischer Build-Loop

Wenn der Nutzer "loop", "fix bis es läuft", "auto-build", "baue durch", "nacht-build" oder ähnliches sagt:

**Ablauf (max. 5 Iterationen):**

1. Starte einen neuen Codemagic-Build:
   ```bash
   bash scripts/build_loop.sh
   ```

2. Das Skript triggert den Build, wartet auf das Ergebnis und gibt Fehler aus.

3. Wenn exit-code 1 (Build fehlgeschlagen):
   - Lese `/tmp/cm_last_errors.txt` (gespeicherte Fehler)
   - Analysiere den fehlgeschlagenen Schritt und den Fehlertext
   - Fixe den Dart-/iOS-/YAML-Code direkt (bearbeite die betroffenen Dateien)
   - Das Skript committe und pushe die Änderungen automatisch beim nächsten Aufruf
   - Rufe `bash scripts/build_loop.sh` erneut auf
   - Wiederhole bis exit-code 0 (Erfolg) oder exit-code 2 (Max-Iterationen)

4. Wenn exit-code 0: Gib den Build-Link aus und berichte dem Nutzer.

5. Wenn exit-code 3 (lokale Dart-Analyse fehlgeschlagen):
   - Lese die Fehlerausgabe direkt aus dem Terminal
   - Fixe die Dart-Fehler und rufe das Skript erneut auf ohne Build zu triggern.

**Iteration zurücksetzen:**
```bash
rm -f /tmp/cm_iteration
```

**Wichtig:** `.env` muss vorhanden sein (siehe `.env.example`).
Credentials: CODEMAGIC_API_TOKEN, CODEMAGIC_APP_ID, CODEMAGIC_WORKFLOW_ID=ios-release

## Was die App macht
Flutter App für lokale Events (Kirchtage, Bälle, Feste) in Kärnten.
Nutzer können Mitfahrgelegenheiten anbieten und anfragen.
Chat-System zwischen Fahrer und Mitfahrer.
Ziel: Release in Kärnten, schlechtes Verkehrsnetz = echter Bedarf.

## Aktueller Stand
Firebase-Integration vollständig abgeschlossen. Hive ist vollständig durch Firestore ersetzt.
- Firebase Auth, Firestore, Storage und FCM produktiv
- Chat-System: Echtzeit, Unread-Tracking, Datum-Trenner, System-Messages, Navbar-Badge
- Admin-Bereich: Führerschein-Freigabe + Event-Freigabe fertig
- Trust-System: E-Mail / Telefon / Führerschein (0–3 Level)
- Bewertungs-System: Reviews mit Durchschnitt auf Profilseite
- Push Notifications: Anfragen, Einladungen, Absagen, Fahrt-Löschen, Bewertungen, Führerschein
- Android Release-Signing + Package `at.*` eingerichtet
- Offene Anfragen werden nach 48h automatisch gelöscht (Cloud Function)
- App kurz vor erstem Release in Kärnten

---

## Wichtige Regeln
- Immer Manuel approve edits (nicht auto-accept)
- Eine Aufgabe pro Session
- Nach jeder Aufgabe: git commit
- Änderungen immer erklären wenn unklar
- Sprache: Deutsch

---

## Architektur
Model → Repository (Interface + Firebase-Impl.) → Service (ChangeNotifier) → Provider → View

**Firestore Collections:** users, fahrten, anfragen, events, chat_conversations, messages (Sub-Collection), interessenten, licenseRequests, eventRequests, reviews

**Repositories:** IAuthRepository, IFahrtRepository, IAnfrageRepository, IChatRepository, IEventRepository, IInteressentenRepository, IUserRepository — alle in `lib/data/firebase/`

**State:** Provider für Services, ValueNotifier in `notifiers.dart` für UI-State (Theme, Filter, Favoriten, `activeChatConversationId`)

---

## Kernlogik: Status-Flows

### AnfrageStatus
```
pending (0)
  ├─→ akzeptiert (1)   [nur Cloud Function `acceptInvitation`]
  ├─→ abgelehnt (2)    [requesterId kann selbst setzen]
  └─→ storniert (3)    [requesterId kann selbst setzen]
  └─→ fahrtGeloescht   [wenn Fahrt gelöscht wird]
```
Wichtig: Fahrer kann status auf JEDEN Wert setzen (Firestore Rules validieren den Wert nicht) — bekannte Lücke.

### LicenseStatus
```
'none' → 'pending' (Upload) → 'verified' (Admin) oder 'rejected' (Admin, mit Grund)
```
Nutzer können abgelehnte Anfragen löschen (ermöglicht Re-Submit).

### Trust-Level (0–3)
```dart
if (emailVerified)            → +1
if (phoneVerified)            → +1
if (licenseStatus=='verified') → +1
```
Wird dynamisch aus AppUser-Feldern berechnet, nicht in Firestore gespeichert.

---

## Kernlogik: Chat-System

### Conversation-ID (deterministisch)
```dart
buildConversationId(fahrtId, uidA, uidB):
  → "${fahrtId}_${[uidA,uidB].sorted().join('_')}"
```
Gleiche Fahrt + gleiche zwei User = immer gleiche ID. Conversation existiert genau einmal pro Fahrt-Paar.

### System-Message
- ID: `${conversationId}_system`
- Wird beim Chat-Öffnen einmalig angelegt (idempotent via merge)
- Enthält: Fahrtdetails (Route, Zeit, Plätze, Richtung) als strukturierten Text
- Wird oben in der Chat-UI als persistente Karte angezeigt
- Wenn zwei Anfragen gleichzeitig akzeptiert werden, überschreibt die letzte die System-Message

### Unread-Tracking
```
ChatConversation.lastRead = { userId → Timestamp }
isUnreadFor(userId):
  → false wenn lastSenderId == userId (eigene Nachricht)
  → false wenn lastSenderId == 'system'
  → true  wenn lastRead[userId] fehlt
  → true  wenn lastUpdated > lastRead[userId]
```
`markConversationRead()` schreibt `lastRead[userId]` mit Server-Timestamp.
Achtung: kann fehlschlagen wenn Conversation noch nicht existiert (catch 'not-found' → silent fail → Nachricht bleibt "ungelesen").

---

## Kernlogik: Notifications

### Push-Notification-Trigger (Cloud Functions)
| Trigger | Wer bekommt Notification |
|---------|--------------------------|
| Neue Anfrage | Fahrt-Owner |
| Anfrage akzeptiert | Requester |
| Anfrage abgelehnt | Requester |
| Fahrt gelöscht | alle akzeptierten Mitfahrer |
| Neue Bewertung | Bewerteter User |
| Führerschein eingereicht | Admins |
| Neue Chat-Nachricht | Gegenüber (wenn nicht im Chat) |

### In-App Chat-Monitoring (`notification_service.dart`)
- Hört auf `conversationsStream()` und zeigt lokale Notification wenn `lastUpdated` neuer ist als bekannt
- **Bekanntes Problem:** `_knownLastMessageAt` wird nicht persistiert → nach App-Neustart kann es Duplicate-Notifications geben (erste Emission setzt Baseline)
- Keine Notification wenn `activeChatConversationId == conv.id` (User ist gerade in diesem Chat)
- Timestamp-Filter: Messages älter als 30 Sekunden werden ignoriert — kann echte Notifications unterdrücken bei langsamer Verbindung

---

## Kernlogik: Interessenten (Event-Favoriten)
- `interessenten_service.dart` cached die Liste pro Event lokal
- Toggle-Operationen sind **optimistisch**: UI ändert sich sofort, Rollback bei Fehler nach 8s
- `_pendingToggles` verhindert Doppel-Taps — wird aber bei Timeout nicht immer korrekt zurückgesetzt (Toggle kann dauerhaft blockiert bleiben → App-Neustart nötig)

---

## Bekannte Risiken / Noch nicht ausgiebig getestet

### Overbooking (nur Einladungs-Flow)
- Der normale Flow (Fahrer akzeptiert Anfrage manuell) hat **kein** Overbooking-Risiko — läuft seriell
- Im **Einladungs-Flow** (`acceptInvitation` CF, Mitfahrer akzeptiert selbst): Kapazitätsprüfung liegt VOR der Firestore-Transaction, nicht darin
- Race Condition: Zwei gleichzeitig eingeladene Mitfahrer akzeptieren beide den letzten Platz → beide kommen durch
- Tritt nur auf wenn der Fahrer mehrere Leute einlädt und genau zum gleichen Moment beide annehmen

### Review-System (gut abgesichert)
- Cloud Function `submitReview` prüft: akzeptierte Anfrage (status==1) muss existieren, Event muss vorbei sein (+3h Puffer), 14-Tage-Frist, keine Doppelbewertung
- Parallele Review-Writes können falschen Durchschnitt erzeugen (Durchschnitt wird vor Transaction gelesen) — bei wenigen gleichzeitigen Usern kein Problem

### Chat Notifications (Vordergrund)
- `_knownLastMessageAt` setzt beim App-Start `DateTime.now()` als Baseline → **kein** Duplicate-Problem nach Neustart
- Potenzielles Doppel-Feuern: FCM Cloud Function schickt Push Notification + lokaler Stream-Listener zeigt lokale Notification — wenn App im Vordergrund, könnten beide gleichzeitig erscheinen

### Firestore Batch-Limit
- `cleanupAbgelaufeneAnfragen` (Cloud Function, täglich): Wenn >500 alte Anfragen gelöscht werden müssen, schlägt der Batch fehl (Firestore-Limit)

### Firestore Security Rules — bekannte Lücken
- `events` Collection ist ohne Auth lesbar (`allow read: if true`) — kein kritisches Problem aber inkonsistent
- Anfragen: `status`-Wert wird in Rules nicht validiert (Fahrer könnte beliebigen Wert setzen, ist aber nur intern sichtbar)
- `lastRead` in Chat-Conversations kann vom Client direkt manipuliert werden (kein größeres Sicherheitsproblem)

---

## AppUser — Felder
```dart
userId, name, email, photoUrl?
emailVerified (bool), phone?, phoneVerified (bool)
licenseStatus: 'none'|'pending'|'verified'|'rejected'
licenseRejectReason?
homeTown?, homeTownLat?, homeTownLng?
car? (CarInfo: make, model, color, seats)
ratingAvg?, ratingCount (int)
```

---

## Neue Dateien (seit letztem großen Commit)
- `lib/config/feature_flags.dart` — `kPhoneVerifEnabled` (Telefon-Verif an/aus)
- `lib/data/review.dart` — Review-Model
- `lib/data/event_request.dart`, `license_request.dart` — Models
- `lib/views/auth/verification_guard.dart` — Block-Screen bis E-Mail bestätigt
- `lib/views/pages/admin_license_page.dart` — Führerschein prüfen & freigeben
- `lib/views/pages/admin_event_requests_page.dart` — Events genehmigen
- `lib/views/pages/email_verification_page.dart` — E-Mail-Verifikations-Seite
- `lib/views/pages/event_submit_page.dart` — Nutzer reicht Event ein
- `lib/views/pages/reviews_list_page.dart` — Vollansicht Bewertungen
- `lib/views/pages/user_event_requests_page.dart` — Nutzer-seitige Event-Anfragen
- `lib/views/pages/legal_page.dart` — Impressum / Datenschutz
- `lib/views/widgets/places_autocomplete_field.dart` — Google Places (nur Österreich)
- `lib/views/widgets/review_card_widget.dart` — Review-Anzeige
- `lib/utils/` — Utility-Funktionen
- `deploy_apk.ps1` — PowerShell-Script für APK-Deploy

---

## Firebase-Konfiguration (vor Release erledigen)
- **E-Mail-Verifikation landet im Spam:** Fix: Firebase Console → Authentication → Templates → eigene Absender-Domain.
- **Telefon-Verifikation aktivieren:** `lib/config/feature_flags.dart` → `kPhoneVerifEnabled = true`.
  Voraussetzung: Phone Auth in Firebase Console aktiviert + SHA-1-Fingerprint für Android.
- **Firestore Index:** `chat_conversations` — `participants (array-contains)` + `lastMessageAt (desc)` muss angelegt sein.
- **Google Maps API Key restringieren:** Google Cloud Console → Credentials → Key `AIzaSyAjs4VgCkDwQ_GyZntKXTOBmt7Co1sUkC8` auf Package `at.eventride.app` + Release-SHA-1 einschränken.

## Erledigte Release-Vorbereitungen
- ✅ Package auf `at.eventride.app` umgestellt (build.gradle, MainActivity, google-services.json)
- ✅ `firebase_options.dart` Android: appId + apiKey auf `at.eventride.app`-Eintrag aktualisiert
- ✅ iOS Info.plist: `CFBundleDisplayName` / `CFBundleName` auf "EventRide" gesetzt
- ✅ Memory Leaks behoben: TextEditingController in Dialogen (login, settings, admin) + home_page disposed

---

## Offene Lint-Warnings (kein Release-Blocker)
- `withOpacity` → `.withValues(alpha: x)` — 12× in 6 Dateien (fahrt_anbieten_page, login_page, app_snackbar, chat_system_widget, eventcard_widget, suchleiste_widget)
- `unused_field: andereFahrtLupeFarbe` — lib/views/pages/fahrten_page.dart
- `avoid_types_as_parameter_names` (sum) — lib/views/pages/fahrten_page.dart
- Radio: `groupValue`/`onChanged` deprecated → RadioGroup — lib/views/pages/fahrt_anbieten_page.dart
- Warnings in `1_uebungen/` ignorieren — separates Übungsprojekt

---

## Offene Punkte / Release-Fixes

Gefunden beim ersten Zwei-Nutzer-Test auf iOS (2026-05-21). Priorisiert nach Kritikalität.

### 🔴 A – Sicherheit (vor Release zwingend)

**Email-Verification-Bypass im Chat**
- Nicht verifizierte Nutzer können Chat via Push-Notification-Tap öffnen/verwenden, obwohl sie geblockt sein sollten.
- `verification_guard.dart` greift nur bei normaler Navigation – Deep-Link via Notification-Tap geht daran vorbei.
- Fix UI: `chat_page.dart` → in `initState` `requireVerified(context)` aufrufen und bei fail sperren.
- Fix Server: Firestore Rules `messages` Sub-Collection: `allow write: if request.auth.token.email_verified == true;`
- Dateien: `lib/views/pages/chat_page.dart`, `lib/views/auth/verification_guard.dart`, Firestore Rules

---

### 🔴 B – iOS-Bugs (Release-kritisch)

**"Fahrt erstellen"-Button: Fahrt wird erstellt, aber kein Feedback auf iOS**
- Fahrt wird tatsächlich angelegt, aber Nutzer bekommt keine Rückmeldung (kein Snackbar, keine Navigation, kein visueller Hinweis).
- Mögliche Ursache: Snackbar/Navigation wird nach `pop` nicht angezeigt, oder `Listener`-Widget (Zeile 123) stört den Tap-Flow sodass der Bestätigungsschritt nicht ausgeführt wird.
- Fix: Fehler-/Erfolgs-Feedback (Snackbar + Navigation) auf iOS sicherstellen; `Listener` auf Hit-Test-Konflikte prüfen.
- Alle anderen Seiten mit gleichem Pattern ebenfalls prüfen.
- Datei: `lib/views/pages/fahrt_anbieten_page.dart:123`

---

### 🟠 C – Fehlende Core-Features

**Akzeptierte Mitfahr-Anfrage zurückziehen**
- Mitfahrer kann akzeptierte Anfrage nicht zurückziehen. Service-Methode `storniereAnfrage()` (`anfrage_service.dart:210`) existiert, aber:
  1. Kein UI-Button für akzeptierte Anfragen
  2. `freie_plaetze` in der Fahrt wird nicht wieder erhöht
  3. Fahrer bekommt keine Notification
- Fix: Atomische Transaktion: status → `storniert` + `freie_plaetze++`, danach Push an Fahrer.
- Button prominent einbauen (löst auch E1 – zu dezent sichtbar).
- Dateien: `lib/data/anfrage_service.dart`, Anfragen-/Fahrt-Detailseite, ggf. Cloud Function

---

### 🟠 D – Notification-Bugs

**D1 – Notification-Logik falsch herum**
- Jana zieht Anfrage zurück → Jana bekommt Notification „Lukas hat die Fahrt storniert" (Sender/Empfänger vertauscht).
- Bei Status `storniert` (Mitfahrer zieht zurück) muss Notification **an den Fahrer** gehen, nicht an den Requester.
- Zu prüfen: Cloud Function `sendNotificationOnAnfrageUpdate`

**D2 – Event-Freigabe Notification fehlt**
- Admin genehmigt Event → Ersteller bekommt keine Benachrichtigung.
- Handler `event_request_approved` ist in `notification_service.dart:283` vorbereitet, aber Cloud Function sendet kein FCM an `createdByUserId`.
- Fix: Cloud Function bei `approved`-Status: FCM-Token des Erstellers aus Firestore lesen + Push senden.

**D3 – Chat-Notifications bleiben im System-Tray hängen**
- Notification bleibt dauerhaft, wenn Nutzer nicht direkt darauf klickt.
- Fix: Nach `markConversationRead()` in `chat_page.dart` → `_localNotifications.cancel(notificationId)` aufrufen.
- Notification-ID beim Erstellen speichern (z.B. Hash aus conversationId → Int).
- Dateien: `lib/data/notification_service.dart`, `lib/views/pages/chat_page.dart`

---

### 🟡 E – UI/UX

**E1 – "Anfrage zurückziehen" zu dezent sichtbar**
- Wird zusammen mit C gelöst (prominenter Button).

**E2 – iOS Design-Polishing**
- Schriftarten, Spacing und generelles Layout stärker an Apple/iOS anpassen (Cupertino-Style).
- Nicht Release-kritisch; Umfang nach Screen-by-Screen-Sichtung festlegen.

---

### 🟡 F – Daten-Bereinigung (einmalig vor Release)

**Alte Events aus Firestore löschen**
- Alle Events mit `datum < heute` bereinigen.
- Einfachste Lösung: Firebase Console → Firestore → Filter → manuell löschen.
- Langfristig: Cloud Function `cleanupAbgelaufeneEvents` analog zu `cleanupAbgelaufeneAnfragen`.

---

### 🔵 G – Nach Release (kein Release-Blocker)

**Event absagen / löschen mit Kaskaden-Bereinigung**
- Wenn ein Event gelöscht oder abgesagt wird, müssen alle abhängigen Daten bereinigt und Nutzer benachrichtigt werden.
- **Was passieren soll:**
  1. Admin drückt "Event absagen"-Button in `admin_event_requests_page.dart` (neuer Button, separat von "löschen")
  2. Cloud Function `cancelEvent(eventId)` läuft durch:
     - Alle Fahrten mit `eventId` laden → für jede Fahrt alle `anfragen` mit `status == akzeptiert (1)` laden → Push-Notification an jeden Mitfahrer ("Event wurde abgesagt")
     - Alle Fahrer der betroffenen Fahrten ebenfalls benachrichtigen
     - Alle `anfragen` auf `status = fahrtGeloescht (4)` setzen
     - Alle `fahrten` löschen
     - Event-Dokument löschen (oder `status: 'abgesagt'` setzen statt löschen, damit History erhalten bleibt)
  3. Alternativ als Batch-Cloud-Function wenn >500 Anfragen möglich
- **Warum noch nicht:** tritt im Normalfall nicht auf, kein Release-Blocker; Aufwand ~3–4h
- **Dateien:** `functions/index.js` (neue Cloud Function), `lib/views/pages/admin_event_requests_page.dart`, `lib/data/notification_service.dart`

---

### Empfohlene Session-Reihenfolge

| Session | Kategorie | Aufwand | Status |
|---------|-----------|---------|--------|
| 1 | A – Email-Verification-Bypass | ~1h | ✅ umgesetzt – noch nicht auf Gerät getestet |
| 2 | B – iOS Tap-Handler Bug | ~1–2h | ✅ umgesetzt – noch nicht auf Gerät getestet |
| 3 | C – Anfrage zurückziehen (inkl. E1) | ~2h | ✅ umgesetzt – noch nicht auf Gerät getestet |
| 4 | D1+D2 – Notification-Bugs | ~1h | ✅ umgesetzt – noch nicht auf Gerät getestet |
| 5 | D3 – Chat-Notifications clearen | ~1h | ✅ umgesetzt – noch nicht auf Gerät getestet |
| 6 | F – Alte Events löschen | ~15min | ✅ umgesetzt – noch nicht auf Gerät getestet |
| 7 | E2 – iOS Design-Polishing | eigene Session | ✅ umgesetzt – noch nicht auf Gerät getestet |
