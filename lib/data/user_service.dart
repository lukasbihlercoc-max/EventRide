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
      id: email, 
      name: email.split('@').first,
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
    id: email,
    name: '$firstName $lastName',
  );
}


  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_email');
    await prefs.remove('user_name');
  }

  //User Daten:
  AppUser? getCurrentUser() {
  return _currentUser;
}

AppUser get safeUser {
  return _currentUser ??
      AppUser(id: 'temp_user', name: 'Testnutzer');
}


  // 🔥 OPTIONAL: Async-Version die aus SharedPreferences liest
  /*Future<Map<String, String>> getCurrentUserAsync() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'Unbekannter Benutzer';
    final userEmail = prefs.getString('user_email') ?? 'unbekannt@email.com';
    
    return {
      'id': userEmail, // Verwende E-Mail als ID bis wir echte User-IDs haben
      'name': userName,
    };
  }*/
  
    // 🔹 Wohnort speichern
  Future<void> setHomeTown(String town) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_home_town', town);
  }

  // 🔹 Wohnort lesen
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
      id: email,
      name: name,
    );
  }
}
}
