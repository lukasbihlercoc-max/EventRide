class AppUser {
  final String userId; // Firebase UID
  final String name;
  final String email;
  final String? photoUrl;

  AppUser({
    required this.userId,
    required this.name,
    required this.email,
    this.photoUrl,
  });
}
