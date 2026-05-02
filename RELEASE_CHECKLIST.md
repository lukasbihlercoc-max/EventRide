# EventRide – Release Checklist

_Stand: 2026-05-02_

---

## 🔴 BLOCKING — Release-Stopper

Diese Punkte müssen vor dem ersten Release vollständig gelöst sein.

---

### 1. Firestore Composite Index ergänzen
**Datei:** `firestore.indexes.json`

Die Cloud Function `acceptInvitation` stellt zwei 3-Feld-Compound-Queries auf die `anfragen`-Collection:
```
.where("requesterId", "==", uid)
.where("eventId", "==", eventId)
.where("status", "==", 0 oder 1)
```
Ohne passenden Index wirft Firestore zur Laufzeit einen Fehler.

**Fix:** Composite Index in `firestore.indexes.json` eintragen:
```json
{
  "collectionGroup": "anfragen",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "requesterId", "order": "ASCENDING" },
    { "fieldPath": "eventId",     "order": "ASCENDING" },
    { "fieldPath": "status",      "order": "ASCENDING" }
  ]
}
```

- [x] Index definiert (`firestore.indexes.json`)
- [ ] Index deployed (`firebase deploy --only firestore:indexes`)

---

### 2. Admin-Status auf Snapshot-Listener umstellen
**Datei:** `lib/data/firebase/firebase_auth_repository.dart`

`_isAdmin` wird einmalig beim Login geladen und danach nie mehr aktualisiert. Wenn einem User die Admin-Rechte entzogen werden, bleibt `isAdmin == true` bis zum App-Neustart.

**Fix:** Statt einmaligem `.get()` auf einen `.snapshots()`-Stream wechseln:
```dart
_firestore.collection('users').doc(uid).snapshots().listen((snap) {
  _isAdmin = snap.data()?['isAdmin'] == true;
  notifyListeners();
});
```

- [x] Admin-Status reagiert in Echtzeit auf Firestore-Änderungen (`authStateChanges`-Stream)

---

### 3. Race Condition im Interessenten-Toggle beheben
**Datei:** `lib/data/interessenten_service.dart` → `toggle()` (Zeile 55–98)

**Kernproblem (Blocking / Core-Logik):** Die Prüfung `existsInCache` liest aus dem lokalen In-Memory-Cache. Bei zwei schnellen Doppel-Taps (oder gleichzeitigen Requests von zwei Geräten desselben Users) sehen beide `existsInCache = false` → beide rufen `_repository.add()` auf → doppelte Einträge im `interessenten`-Index.

Da `InteressentenDaten.buildId()` eine deterministische ID erzeugt, schützt ein Firestore-`set(docId)` mit `SetOptions(merge: false)` serverseitig gegen Duplikate — aber nur wenn das Repository `set` statt `add` (auto-ID) verwendet.

**Fix:** Im Repository sicherstellen, dass `add(entry)` intern `doc(entry.id).set(data)` aufruft (kein `collection.add()`). Zusätzlich im Service einen Guard einbauen, der schnelle Doppel-Taps debounced.

- [x] Repository nutzt `doc(id).set()` — bereits korrekt
- [x] Toggle gegen Doppel-Tap geschützt (`_pendingToggles` Set in `interessenten_service.dart`)

---

### 4. Cloud Function Auth-Check verifizieren
**Datei:** `functions/src/index.ts`

Alle Callable Functions müssen am Anfang prüfen:
```typescript
if (!request.auth) {
  throw new HttpsError("unauthenticated", "Nicht eingeloggt");
}
```

**Status:** `acceptInvitation` (Zeile 256–259) hat den Check bereits ✓

Bei jeder neu hinzugefügten Callable (`onCall(...)`) ist dieser Check **Pflicht** — Firestore-Trigger (`onDocumentCreated` etc.) sind davon ausgenommen, da sie serverseitig durch Security Rules geschützt sind.

- [x] Alle bestehenden Callables geprüft — `acceptInvitation` hat Auth-Check (Zeile 257)
- [x] Firestore-Trigger brauchen keinen Auth-Check (serverseitig, durch Security Rules geschützt)
- [ ] Für neue Callables gilt der Check als Coding-Standard (kein Code-Change nötig)

---

### 5. Dev-Flags und toten Code entfernen
**Dateien:** `lib/testing.dart`, `lib/main.dart`, `lib/data/app_user.dart`

| Problem | Datei | Zeile |
|---------|-------|-------|
| `kDevAllowMultipleRequests = true` — erlaubt mehrfache Anfragen pro User | `lib/testing.dart` | 1 |
| Auskommentierte Hive-Löschbefehle | `lib/main.dart` | ~75 |
| Leerer `operator[]` | `lib/data/app_user.dart` | – |
| `debugPrint` global überschrieben statt `kReleaseMode`-Guard | Diverse | – |

- [x] `lib/testing.dart` gelöscht (Flag wurde nirgendwo verwendet)
- [x] Doppeltes `WidgetsFlutterBinding.ensureInitialized()` und Leerzeilen in `main.dart` bereinigt
- [x] `operator[]` in `app_user.dart` — bereits nicht vorhanden (bereits bereinigt)
- [x] Hive-Kommentare in `main.dart` — bereits nicht vorhanden (bereits bereinigt)

---

### 6. Phone Verification: aktivieren oder sauber deaktivieren
**Datei:** `lib/config/feature_flags.dart` → `kPhoneVerifEnabled = false`

Aktuell wird eine Telefonnummer gespeichert, ohne sie zu verifizieren. Das ist kein echtes Feature, sondern ein halbfertiger Zustand.

**Optionen:**
- **Option A (empfohlen für v1.0):** Telefonnummer-Feld komplett aus dem Onboarding entfernen bis Phone Auth bereit ist.
- **Option B:** Firebase Phone Auth + SHA-1-Fingerprint vollständig einrichten, dann `kPhoneVerifEnabled = true` setzen.

Voraussetzungen für Option B: Phone Auth in Firebase Console aktiviert, SHA-1-Fingerprint für Android hinterlegt.

- [ ] Entscheidung getroffen (A oder B)
- [ ] Umgesetzt

---

## 🟠 HIGH PRIORITY — vor oder kurz nach dem ersten Release

---

### 7. Storage: Dateigrößen-Limit setzen
**Datei:** `storage.rules`

Aktuell können authentifizierte User beliebig große Dateien hochladen.

**Fix:**
```
allow write: if request.auth != null
             && request.auth.uid == userId
             && request.resource.size < 5 * 1024 * 1024; // 5 MB
```

- [x] Größenlimit für Profil-Fotos gesetzt (5 MB, nur `image/jpeg`)
- [x] Größenlimit für Führerschein-Bilder gesetzt (10 MB, nur `image/jpeg`)

---

### 8. `debugPrint` bereinigen
**Hauptdatei:** `lib/data/notification_service.dart` (~13 Stellen, Zeilen 40–112)

Weitere: `lib/views/pages/detail_page.dart`, `lib/views/pages/fahrt_anbieten_page.dart`

**Fix:** Entweder entfernen oder in `if (kDebugMode)` einwickeln:
```dart
if (kDebugMode) debugPrint('[FCM] Token: $token');
```

- [x] Alle ungeschützten `debugPrint`-Calls mit `kDebugMode`-Guard versehen (`notification_service.dart`)

---

### 9. Error Handling: stille `catch (_)` Blöcke ersetzen
**Dateien:** `lib/data/anfrage_service.dart` (Zeilen 74, 90, 235), `lib/data/firebase/firebase_auth_repository.dart`

Stille Fehler sind im Produktionsbetrieb nicht akzeptabel — Probleme werden nie sichtbar.

**Fix:** Statt:
```dart
} catch (_) {
  return false;
}
```
Besser:
```dart
} catch (e, stack) {
  debugPrint('[AnfrageService] Fehler: $e\n$stack');
  return false;
}
```
Langfristig: Firebase Crashlytics einbinden.

- [x] Stille `catch (_)` mit `return false` in `anfrage_service.dart` durch `catch (e, stack)` + Logging ersetzt
- [x] Nutzloses `try/catch/rethrow` in `addAnfrage` entfernt
- [x] Dokumentierte stille Catches (Storage-Delete, Phone-Auth-Fallback, UI-Fallbacks) bleiben — absichtlich

---

### 10. Notification Navigation testen und absichern
**Datei:** `lib/data/notification_service.dart`

Die Navigation aus Notifications heraus ist implementiert (`onMessageOpenedApp`, Cold-Start, lokale Notifications), aber hat zwei brüchige Stellen:

**Problem A — Infinite Retry Loop (Zeile 229–233):**
```dart
void _navigateFromData(...) {
  if (_navigatorKey.currentState == null) {
    Future.delayed(const Duration(milliseconds: 300), () {
      _navigateFromData(data); // Kein Abbruch-Kriterium!
    });
    return;
  }
```
Wenn der Navigator nie bereit wird (z. B. nach Auth-Fehler), läuft diese Funktion unendlich.

**Fix:** Retry-Zähler einbauen (max. 5 Versuche):
```dart
void _navigateFromData(Map<String, dynamic> data, {int retries = 0}) {
  if (_navigatorKey.currentState == null) {
    if (retries >= 5) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      _navigateFromData(data, retries: retries + 1);
    });
    return;
  }
  // ...
}
```

**Problem B — Cold-Start-Delay (Zeile 107):**
`Future.delayed(500ms)` ist ein Workaround ohne Garantie. Auf langsamen Geräten kann 500 ms zu kurz sein.

**Fix:** Auf `WidgetsBinding.instance.addPostFrameCallback` oder auf `navigatorKey.currentState != null` warten statt fixen Delay.

**Zu testen:**
- [x] Infinite-Retry-Loop gefixt: max. 5 Versuche à 300 ms in `_navigateFromData`
- [x] Cold-Start-Delay von `Future.delayed(500ms)` auf `addPostFrameCallback` umgestellt
- [ ] Manuell testen: Notification-Tap aus Background → öffnet richtige Seite
- [ ] Manuell testen: Cold-Start → Navigation landet korrekt
- [ ] Manuell testen: Lokale Notification (App im Vordergrund) → Tap öffnet richtige Seite

---

## 🟡 POST-RELEASE — nächster Sprint

---

### 11. `uploadLicense` atomar machen
**Datei:** `lib/data/firebase/firebase_auth_repository.dart` (Zeilen 338–352)

Storage-Upload und Firestore-Batch sind aktuell nicht atomar. Schlägt der Batch nach erfolgreichem Storage-Upload fehl, bleiben verwaiste Bilder zurück. Kein Datenverlust, aber technische Schuld.

**Fix:** Cleanup-Logik bei Batch-Fehler (Storage-Datei löschen) oder auf Firestore Extension umstellen.

- [ ] Verwaiste Bilder werden bei Fehler bereinigt

---

### 12. Bildkompression vor Upload
**Datei:** `lib/data/firebase/firebase_auth_repository.dart` (Zeilen 233–244)

Profil- und Führerschein-Fotos werden unkomprimiert hochgeladen. Kamera-Fotos können 5–10 MB groß sein.

**Fix:** `flutter_image_compress` vor dem Upload einsetzen, Zielgröße ~500 KB.

- [ ] Bilder werden vor dem Upload auf max. 1 MB komprimiert

---

### 13. FCM Token Cleanup einrichten
**Datei:** `functions/src/index.ts`

Ungültige Tokens werden beim nächsten Sende-Versuch entfernt (bereits implementiert). Tokens von deinstallierten Apps bleiben aber dauerhaft stehen bis die nächste Notification ausgelöst wird.

**Fix:** Monatlichen Cloud Scheduler Job einrichten, der veraltete Tokens (> 60 Tage kein Login) aus Firestore entfernt.

- [ ] Scheduler-Job existiert

---

### 14. Firebase E-Mail-Absender konfigurieren
**Wo:** Firebase Console → Authentication → Templates → „E-Mail-Adresse bestätigen"

E-Mail-Verifikations-Mails kommen von `noreply@[projekt-id].firebaseapp.com` und landen im Spam.

**Fix:** Eigene Absender-Domain in Firebase Console konfigurieren.

- [ ] Eigene Domain hinterlegt
- [ ] Test-Mail landet im Posteingang

---

## Zusammenfassung

| Kategorie | Anzahl | Status |
|-----------|--------|--------|
| 🔴 Blocking | 6 | Offen |
| 🟠 High Priority | 4 | Offen |
| 🟡 Post-Release | 4 | Offen |
| **Gesamt** | **14** | |
