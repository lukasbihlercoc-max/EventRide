// user_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/data/app_user.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  Future<void> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', email.split('@').first);

    _currentUser = AppUser(
      userId: email, // wird nach Firebase-Migration zur UID
      name: email.split('@').first,
      email: email,
    );
  }

  Future<void> register(
    String firstName,
    String lastName,
    String email,
    String phone,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', '$firstName $lastName');

    _currentUser = AppUser(
      userId: email, // wird nach Firebase-Migration zur UID
      name: '$firstName $lastName',
      email: email,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    _currentUser = null;
  }

  AppUser? getCurrentUser() {
    return _currentUser;
  }

  AppUser get safeUser {
    return _currentUser ??
        AppUser(userId: 'temp_user', name: 'Testnutzer', email: '');
  }

  Future<void> setHomeTown(String town) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_home_town', town);
  }

  Future<String?> getHomeTown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_home_town');
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    final email = prefs.getString('user_email');

    if (name != null && email != null) {
      _currentUser = AppUser(
        userId: email, // wird nach Firebase-Migration zur UID
        name: name,
        email: email,
      );
    }
  }
}
