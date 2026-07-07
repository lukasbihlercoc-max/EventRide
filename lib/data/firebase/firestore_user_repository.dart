import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/data/interfaces/i_user_repository.dart';

class FirestoreUserRepository implements IUserRepository {
  final FirebaseFirestore _db;

  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String?> getPhotoUrl(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    final url = doc.data()?['photoUrl'] as String?;
    return (url != null && url.isNotEmpty) ? url : null;
  }

  @override
  Future<String?> getUserName(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    final data = doc.data();
    if (data == null) return null;
    final first = (data['firstName'] as String?) ?? '';
    final last = (data['lastName'] as String?) ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? null : name;
  }

  @override
  Future<int> getTrustLevel(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final data = doc.data();
      if (data == null) return 0;
      final emailVerified = data['emailVerified'] as bool? ?? false;
      final phoneVerified = data['phoneVerified'] as bool? ?? false;
      final licenseStatus = data['licenseStatus'] as String? ?? 'none';
      int count = 0;
      if (emailVerified) count++;
      if (phoneVerified) count++;
      if (licenseStatus == 'verified') count++;
      return count;
    } catch (_) {
      return 0;
    }
  }

  @override
  Stream<DateTime?> lastSeenStream(String userId) {
    if (userId.isEmpty) return Stream.value(null);
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snap) {
          final raw = snap.data()?['lastSeen'];
          if (raw == null) return null;
          return (raw as Timestamp).toDate();
        });
  }

  @override
  Future<void> updateLastSeen(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _db.collection('users').doc(userId).set(
        {'lastSeen': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return;
      rethrow;
    }
  }

  @override
  Future<void> saveFcmToken(String userId, String token) async {
    if (userId.isEmpty || token.isEmpty) return;
    try {
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return;
      rethrow;
    }
  }

  @override
  Future<void> removeFcmToken(String userId, String token) async {
    if (userId.isEmpty || token.isEmpty) return;
    try {
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return;
      rethrow;
    }
  }
}
