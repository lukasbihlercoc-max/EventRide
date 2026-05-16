# EventRide

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

---

## Offene Lint-Warnings (kein Release-Blocker)
- `withOpacity` → `.withValues(alpha: x)` — 12× in 6 Dateien (fahrt_anbieten_page, login_page, app_snackbar, chat_system_widget, eventcard_widget, suchleiste_widget)
- `unused_field: andereFahrtLupeFarbe` — lib/views/pages/fahrten_page.dart
- `avoid_types_as_parameter_names` (sum) — lib/views/pages/fahrten_page.dart
- Radio: `groupValue`/`onChanged` deprecated → RadioGroup — lib/views/pages/fahrt_anbieten_page.dart
- Warnings in `1_uebungen/` ignorieren — separates Übungsprojekt
