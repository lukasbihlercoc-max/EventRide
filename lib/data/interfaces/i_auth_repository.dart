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

  Future<void> setHomeTown(String town);

  Future<String?> getHomeTown();
}
