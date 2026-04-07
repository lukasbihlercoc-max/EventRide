# EventRide

## Was die App macht
Flutter App für lokale Events (Kirchtage, Bälle, Feste) in Kärnten.
Nutzer können Mitfahrgelegenheiten anbieten und anfragen.
Chat-System zwischen Fahrer und Mitfahrer.
Ziel: Release in Kärnten, schlechtes Verkehrsnetz = echter Bedarf.

## Aktueller Stand
Kurz vor Firebase-Integration.
Hive wird schrittweise durch Firestore ersetzt.
Firebase Auth ersetzt das aktuelle SharedPreferences-System.
Neuer Git-Branch für Firebase-Integration bereits erstellt.

## Bekannte Probleme (vor Firebase beheben)
- User-ID ist aktuell die E-Mail → muss Firebase UID werden
- AnfrageService ist Singleton → sauber per Provider injizieren
- MaterialStateProperty deprecated → WidgetStateProperty
- debugPrint global überschrieben → kReleaseMode verwenden
- Toter Code in main.dart (auskommentierte Hive-Löschbefehle)
- Leerer operator[] in app_user.dart → entfernen

## Architektur
Model → Repository → Service (ChangeNotifier) → Provider → View
Hive-Repositories werden durch Firebase-Repositories ersetzt.
Service-API bleibt dabei unverändert.

## Wichtige Regeln
- Immer Manuel approve edits (nicht auto-accept)
- Eine Aufgabe pro Session
- Nach jeder Aufgabe: git commit
- Änderungen immer erklären wenn unklar
- Sprache: Deutsch