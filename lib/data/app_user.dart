class AppUser {
  final String userId; // Firebase UID (aktuell: Email bis zur Firebase-Migration)
  final String name;
  final String email;

  AppUser({
    required this.userId,
    required this.name,
    required this.email,
  });
}
