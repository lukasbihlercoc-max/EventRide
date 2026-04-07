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
    await _db.collection('users').doc(userId).set(
      {'lastSeen': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}
