// Telefon-Verifizierung via Firebase Phone Auth (echte SMS).
// false = Nummer wird direkt gespeichert (kein SMS, zum Testen).
// true  = Echter Firebase-OTP-Flow (vor Release aktivieren).
const bool kPhoneVerifEnabled = true;

// Story Creator Mode: versteckter Admin-Workflow zum Aufnehmen sauberer,
// reproduzierbarer Instagram-Story-Screen-Recordings (Event-Liste → Event
// auto-scrollen → Detailseite öffnen → bis zum Ende scrollen).
// Nur sichtbar/aktiv wenn zusätzlich isAdmin == true.
const bool kStoryCreatorModeEnabled = true;
