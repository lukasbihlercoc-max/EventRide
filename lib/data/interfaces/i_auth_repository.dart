import 'dart:io';
import 'package:my_app/data/app_user.dart';

abstract class IAuthRepository {
  AppUser? get currentUser;

  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signIn(String email, String password);

  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> signOut();

  Future<void> deleteAccount();

  Future<bool> isSignedIn();

  /// Gibt true zurück, wenn der eingeloggte User Admin-Rechte hat.
  bool get isAdmin;

  Future<void> setHomeTown(String town);

  Future<String?> getHomeTown();

  /// Lädt ein Profilbild zu Firebase Storage hoch, speichert die URL in
  /// Firestore und Firebase Auth und gibt die Download-URL zurück.
  Future<String> uploadProfilePhoto(File image);
}
