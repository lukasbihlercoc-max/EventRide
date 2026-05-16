import 'dart:io';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/event_request.dart';
import 'package:my_app/data/license_request.dart';

abstract class IAuthRepository {
  AppUser? get currentUser;

  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signIn(String email, String password);

  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  Future<void> resetPassword(String email);

  Future<void> signOut();

  Future<void> deleteAccount();

  /// Re-Authentifizierung mit aktuellem Passwort – nötig vor sensitiven
  /// Operationen wie Account-Löschung wenn die letzte Anmeldung zu lange zurückliegt.
  Future<void> reauthenticate(String password);

  Future<bool> isSignedIn();

  bool get isAdmin;

  Future<void> setHomeTown(String town, {double? lat, double? lng});

  Future<String?> getHomeTown();

  Future<({double? lat, double? lng})> getHomeTownCoords();

  Future<String> uploadProfilePhoto(File image);

  // ── E-Mail-Verifizierung ─────────────────────────────────────────────────

  /// Sendet eine Bestätigungs-E-Mail an den aktuellen Nutzer.
  Future<void> sendEmailVerification();

  /// Re-authentifiziert und schickt eine Bestätigungs-E-Mail an die neue
  /// Adresse. Firebase aktualisiert die E-Mail erst nach dem Klick auf den
  /// Verifikationslink.
  Future<void> changeEmail(String newEmail, String password);

  /// Lädt den Firebase-Auth-Status neu. Gibt true zurück wenn die E-Mail
  /// jetzt verifiziert ist und aktualisiert Firestore entsprechend.
  Future<bool> reloadAndCheckEmailVerified();

  // ── Telefon-Verifizierung ────────────────────────────────────────────────

  /// Speichert die Telefonnummer und setzt phoneVerified=true direkt in
  /// Firestore (wird im Test-Modus ohne SMS verwendet).
  Future<void> savePhone(String phone);

  /// Startet den Firebase Phone Auth Flow (nur wenn kPhoneVerifEnabled=true).
  /// [onCodeSent] wird mit der verificationId aufgerufen sobald die SMS gesendet wurde.
  /// [onError] wird bei Fehlern aufgerufen.
  Future<void> startPhoneVerification(
    String phone, {
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  });

  /// Bestätigt einen SMS-Code und speichert die Nummer in Firestore.
  Future<void> confirmPhoneCode(String verificationId, String smsCode);

  // ── Führerschein ─────────────────────────────────────────────────────────

  /// Lädt ein Führerschein-Bild zu Firebase Storage hoch und setzt
  /// licenseStatus='pending' in Firestore.
  Future<void> uploadLicense(File image);

  // ── Auto-Infos ───────────────────────────────────────────────────────────

  /// Speichert die Auto-Daten in Firestore.
  Future<void> updateCarInfo(
      String make, String model, String? color, int? seats);

  // ── Admin: Führerschein-Prüfung ──────────────────────────────────────────

  /// Stream aller offenen Führerschein-Anfragen (nur für Admins).
  Stream<List<LicenseRequest>> get pendingLicenseRequests;

  /// Führerschein annehmen – setzt licenseStatus auf 'verified'.
  Future<void> approveLicense(String userId);

  /// Führerschein ablehnen mit Begründung – setzt licenseStatus auf 'rejected'.
  Future<void> rejectLicense(String userId, String reason);

  // ── Event-Anfragen ───────────────────────────────────────────────────────────

  Future<void> submitEventRequestManual({
    required String name,
    required String standort,
    required String datum,
    required String eventTyp,
    required String beschreibung,
    required String adresse,
    double? latitude,
    double? longitude,
  });

  Future<void> submitEventRequestFlyer(File flyer, {String? note});

  Stream<List<EventRequest>> get pendingEventRequests;

  Stream<List<EventRequest>> get myEventRequests;

  Future<void> approveEventRequest(String requestId, Event event);

  Future<void> discardEventRequest(String requestId, {String? reason});
}
