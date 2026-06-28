const String kDatenschutzText = '''
Datenschutzerklärung – EventRide

Stand: 28.06.2026

1. Verantwortlicher

EventRide
E-Mail: kontakt@eventride.at
Website: eventride.at

──────────────────────────────────────

2. Erhobene Daten

Im Rahmen der Nutzung der App werden folgende Daten erhoben:

• E-Mail-Adresse
• Vor- und Nachname / Benutzername
• Profilbild (optional)
• Telefonnummer (optional, zur Verifizierung)
• Heimatgemeinde inkl. GPS-Koordinaten (optional)
• Fahrzeugdaten: Marke, Modell, Farbe, Sitzanzahl (optional)
• Kfz-Kennzeichen (optional, für akzeptierte Mitfahrer 24 h vor Fahrtantritt sichtbar)
• Führerschein-Foto (optional, zur Fahrer-Verifizierung)
• Event- und Fahrtdaten (erstellte oder angefragte Fahrten)
• Chat-Nachrichten zwischen Nutzern
• Push-Benachrichtigungs-Token (gerätebezogen)

──────────────────────────────────────

3. Rechtsgrundlage und Zweck der Verarbeitung

Die Daten werden auf folgenden Rechtsgrundlagen verarbeitet:

• Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung):
  Vermittlung von Mitfahrten, Anzeige von Events,
  Kommunikation innerhalb der App.

• Art. 6 Abs. 1 lit. a DSGVO (Einwilligung):
  Führerschein-Foto, Telefonnummer, Kfz-Kennzeichen und
  GPS-Koordinaten werden nur mit ausdrücklicher Zustimmung
  des Nutzers erhoben. Die Einwilligung kann jederzeit
  widerrufen werden.

──────────────────────────────────────

4. Führerschein-Verifizierung

Fahrer können optional ein Foto ihres Führerscheins hochladen,
um als verifizierter Fahrer zu gelten.

Das Foto wird ausschließlich manuell durch den Betreiber
(EventRide) geprüft. Nach abgeschlossener Prüfung wird der
Verifizierungs-Status gespeichert. Das Foto selbst wird nicht
für andere Zwecke verwendet und nicht an Dritte weitergegeben.

──────────────────────────────────────

5. Speicherung und Verarbeitung

Die Daten werden auf Servern von Firebase (Google Ireland
Limited) gespeichert und verarbeitet:

• Firestore: Nutzerdaten, Fahrten, Events, Chats
• Firebase Storage: Profilbilder, Führerschein-Fotos, Flyer

Beim Eintippen einer Heimatgemeinde werden außerdem Anfragen
an die Google Places API (Google Ireland Limited) gesendet.

Firebase und Google können Daten außerhalb der EU verarbeiten.
Dabei werden geeignete Schutzmaßnahmen eingesetzt
(Standardvertragsklauseln gemäß Art. 46 DSGVO).

──────────────────────────────────────

6. Aufbewahrungsdauer

Daten werden gespeichert, solange das Nutzerkonto aktiv ist.
Nach Kontolöschung werden personenbezogene Daten innerhalb
von 30 Tagen gelöscht, soweit keine gesetzlichen
Aufbewahrungspflichten entgegenstehen.

──────────────────────────────────────

7. Weitergabe von Daten

Es erfolgt keine Weitergabe personenbezogener Daten an Dritte,
außer:

• soweit technisch zur Bereitstellung der App notwendig
  (Firebase, Google Places API)
• bei gesetzlichen Verpflichtungen

──────────────────────────────────────

8. Push-Benachrichtigungen

Die App kann Push-Benachrichtigungen senden (z. B. bei neuen
Anfragen oder Nachrichten). Diese können jederzeit in den
Geräteeinstellungen deaktiviert werden.

──────────────────────────────────────

9. Rechte der Nutzer

Nutzer haben folgende Rechte nach der DSGVO:

• Auskunft (Art. 15 DSGVO)
• Berichtigung unrichtiger Daten (Art. 16 DSGVO)
• Löschung ihrer Daten (Art. 17 DSGVO)
• Einschränkung der Verarbeitung (Art. 18 DSGVO)
• Datenübertragbarkeit (Art. 20 DSGVO)
• Widerspruch gegen die Verarbeitung (Art. 21 DSGVO)
• Widerruf einer Einwilligung (Art. 7 Abs. 3 DSGVO)

Zur Ausübung dieser Rechte sowie für Anfragen zur
Datenlöschung wende dich an: kontakt@eventride.at

Außerdem besteht das Recht, Beschwerde bei der zuständigen
Datenschutzbehörde einzulegen:

Österreichische Datenschutzbehörde
Barichgasse 40–42, 1030 Wien
dsb.gv.at

──────────────────────────────────────

10. Datensicherheit

Es werden technische und organisatorische Maßnahmen getroffen,
um Daten vor Verlust, Missbrauch oder unbefugtem Zugriff
zu schützen.

──────────────────────────────────────

11. Kennzeichen (optional)

Wenn ein Nutzer freiwillig ein Kfz-Kennzeichen hinterlegt, wird
dieses ausschließlich bestätigten Mitfahrern innerhalb von
24 Stunden vor Fahrtantritt angezeigt. Das Kennzeichen dient
ausschließlich der Verifizierung des Fahrzeugs und der Erhöhung
der Sicherheit während der Mitfahrt.

Mitfahrer sind selbst dafür verantwortlich, vor Fahrtantritt zu
überprüfen, ob das angezeigte Kennzeichen mit dem tatsächlichen
Fahrzeug übereinstimmt.

Das Kennzeichen wird nach Ablauf der Fahrt nicht mehr angezeigt.
Es wird gelöscht, sobald der Account des Fahrers gelöscht wird.

──────────────────────────────────────

12. Änderungen

Diese Datenschutzerklärung kann bei Bedarf angepasst werden.
Die jeweils aktuelle Version ist in der App verfügbar.
''';

const String kAgbText = '''
Allgemeine Geschäftsbedingungen (AGB) – EventRide

Stand: 28.06.2026

──────────────────────────────────────

1. Geltungsbereich

Diese AGB regeln die Nutzung der App „EventRide".
Mit der Registrierung akzeptiert der Nutzer diese Bedingungen.

──────────────────────────────────────

2. Leistungsbeschreibung

EventRide ist eine Plattform zur Vermittlung von
Mitfahrgelegenheiten zu Veranstaltungen. Die App stellt
lediglich die technische Infrastruktur bereit.

──────────────────────────────────────

3. Mindestalter

Die Nutzung der App ist ab 16 Jahren gestattet.
Für die Nutzung als Fahrer ist ein gültiger Führerschein
erforderlich (Mindestalter 17 Jahre).

──────────────────────────────────────

4. Führerschein-Verifizierung

Fahrer können ihren Führerschein zur Verifizierung hochladen.
Das Foto wird manuell durch den Betreiber geprüft.

• EventRide behält sich vor, die Verifizierung ohne
  Angabe von Gründen abzulehnen.
• Bei Ablehnung kann der Nutzer erneut einreichen.
• Eine Verifizierung bestätigt lediglich, dass zum
  Zeitpunkt der Prüfung eine gültige Fahrerlaubnis
  vorlag – nicht eine fortlaufende Überprüfung.
• Das hochgeladene Foto wird nur für diesen Zweck
  verwendet und nicht weitergegeben.

──────────────────────────────────────

5. Keine Haftung für Fahrten

EventRide ist kein Anbieter von Fahrten.

• Fahrten werden ausschließlich von Nutzern organisiert.
• EventRide übernimmt keine Verantwortung für Ablauf,
  Sicherheit oder Durchführung von Fahrten.
• Nutzer handeln auf eigene Verantwortung.

──────────────────────────────────────

6. Nutzerpflichten

Nutzer verpflichten sich:

• korrekte und wahrheitsgemäße Angaben zu machen
• keine rechtswidrigen Inhalte zu verbreiten
• andere Nutzer nicht zu belästigen oder zu täuschen
• keine fremden Führerschein-Fotos oder gefälschte
  Dokumente hochzuladen

──────────────────────────────────────

7. Kfz-Kennzeichen (optional)

Fahrer können optional ihr Kfz-Kennzeichen hinterlegen.

• Das Hinterlegen ist freiwillig und kann jederzeit in
  den Einstellungen rückgängig gemacht werden.
• Der Fahrer ist für die Richtigkeit des Kennzeichens
  selbst verantwortlich.
• Das Kennzeichen wird ausschließlich bestätigten
  Mitfahrern innerhalb von 24 Stunden vor Fahrtantritt
  angezeigt.
• EventRide übernimmt keine Haftung für Schäden, die aus
  einem falschen oder fehlenden Kennzeichen entstehen.
• Mitfahrer sind selbst dafür verantwortlich, das
  Kennzeichen vor Fahrtantritt zu überprüfen.

──────────────────────────────────────

8. Inhalte & Events

• Nutzer können Events vorschlagen.
• EventRide behält sich vor, Inhalte zu prüfen,
  zu ändern oder abzulehnen.
• Es besteht kein Anspruch auf Veröffentlichung.

──────────────────────────────────────

9. Accounts und Kündigung

• Nutzer sind für ihre Zugangsdaten selbst verantwortlich.
• Missbrauch ist untersagt.
• Nutzer können ihr Konto jederzeit über die App löschen.
  Alle personenbezogenen Daten werden daraufhin innerhalb
  von 30 Tagen gelöscht.

──────────────────────────────────────

10. Ausschluss von Nutzern

EventRide behält sich vor, Nutzer bei Verstößen gegen
diese AGB zu sperren oder zu löschen.

──────────────────────────────────────

11. Haftung

EventRide haftet nur für Schäden, die durch vorsätzliches
oder grob fahrlässiges Verhalten verursacht wurden.

──────────────────────────────────────

12. Anwendbares Recht / Gerichtsstand

Es gilt österreichisches Recht. Gerichtsstand ist
Klagenfurt am Wörthersee, Österreich.

──────────────────────────────────────

13. Änderungen der AGB

EventRide kann diese AGB jederzeit anpassen.
Die aktuelle Version ist in der App verfügbar.
Wesentliche Änderungen werden den Nutzern mitgeteilt.

──────────────────────────────────────

14. Kontakt

E-Mail: kontakt@eventride.at
Website: eventride.at
''';
