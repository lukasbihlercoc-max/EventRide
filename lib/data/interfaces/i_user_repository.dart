abstract class IUserRepository {
  /// Gibt die photoUrl eines beliebigen Nutzers zurück, oder null wenn
  /// kein Foto gesetzt ist.
  Future<String?> getPhotoUrl(String userId);
}
