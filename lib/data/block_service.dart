import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BlockService extends ChangeNotifier {
  List<String> _blockedUserIds = const [];
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  List<String> get blockedUserIds => _blockedUserIds;

  bool isBlocked(String uid) => _blockedUserIds.contains(uid);

  void init(String currentUid) {
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final data = snap.data()!;
      final ids = (data['blockedUserIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [];
      _blockedUserIds = ids;
      notifyListeners();
    }, onError: (_) {});
  }

  void reset() {
    _sub?.cancel();
    _sub = null;
    _blockedUserIds = const [];
    notifyListeners();
  }

  Future<void> blockUser({
    required String currentUid,
    required String targetUid,
  }) async {
    final db = FirebaseFirestore.instance;
    await Future.wait([
      db.collection('users').doc(currentUid).update({
        'blockedUserIds': FieldValue.arrayUnion([targetUid]),
      }),
      db.collection('user_reports').add({
        'reporterUid': currentUid,
        'reportedUid': targetUid,
        'reason': 'blocked',
        'createdAt': FieldValue.serverTimestamp(),
      }),
    ]);
  }

  Future<void> reportUser({
    required String currentUid,
    required String targetUid,
    required String reason,
  }) async {
    await FirebaseFirestore.instance.collection('user_reports').add({
      'reporterUid': currentUid,
      'reportedUid': targetUid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
