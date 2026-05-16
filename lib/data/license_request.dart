import 'package:cloud_firestore/cloud_firestore.dart';

class LicenseRequest {
  final String uid;
  final String userName;
  final String? userPhotoUrl;
  final String licensePath;
  final String status;
  final String? rejectReason;
  final DateTime submittedAt;

  const LicenseRequest({
    required this.uid,
    required this.userName,
    this.userPhotoUrl,
    required this.licensePath,
    required this.status,
    this.rejectReason,
    required this.submittedAt,
  });

  factory LicenseRequest.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LicenseRequest(
      uid: d['uid'] as String? ?? doc.id,
      userName: d['userName'] as String? ?? '',
      userPhotoUrl: d['userPhotoUrl'] as String?,
      licensePath: d['licensePath'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
      rejectReason: d['rejectReason'] as String?,
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
