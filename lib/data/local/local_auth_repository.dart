// local_auth_repository.dart
// Lokale Mock-Implementierung von IAuthRepository.
// Wird nach Firebase-Integration durch FirebaseAuthRepository ersetzt.

import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/user_service.dart';

class LocalAuthRepository implements IAuthRepository {
  final UserService _userService;

  LocalAuthRepository(this._userService);

  @override
  AppUser? get currentUser => _userService.currentUser;

  @override
  Future<AppUser> signIn(String email, String password) async {
    await _userService.login(email, password);
    return _userService.safeUser;
  }

  @override
  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _userService.register(firstName, lastName, email, phone, password);
    return _userService.safeUser;
  }

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(currentUser);

  @override
  Future<void> signOut() => _userService.logout();

  @override
  Future<void> deleteAccount() => _userService.logout();

  @override
  Future<bool> isSignedIn() => _userService.isLoggedIn();

  @override
  Future<void> setHomeTown(String town) => _userService.setHomeTown(town);

  @override
  Future<String?> getHomeTown() => _userService.getHomeTown();
}
