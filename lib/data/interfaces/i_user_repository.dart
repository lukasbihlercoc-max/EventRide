abstract class IUserRepository {
  /// Gibt die photoUrl eines beliebigen Nutzers zurück, oder null wenn
  /// kein Foto gesetzt ist.
  Future<String?> getPhotoUrl(String userId);

  /// Streams das lastSeen-Datum eines Nutzers aus Firestore.
  Stream<DateTime?> lastSeenStream(String userId);

  /// Setzt lastSeen des eigenen Nutzers auf den aktuellen Serverzeitpunkt.
  Future<void> updateLastSeen(String userId);
}
