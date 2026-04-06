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
}
