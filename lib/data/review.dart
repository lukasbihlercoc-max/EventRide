// review.dart
// Datenmodell für eine Fahrt-Bewertung.
// Wird serverseitig via submitReview Cloud Function erstellt.

import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerPhotoUrl;
  final String reviewedId;
  final String fahrtId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhotoUrl,
    required this.reviewedId,
    required this.fahrtId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final ts = d['createdAt'];
    DateTime createdAt;
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    } else if (ts is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      createdAt = DateTime.now();
    }
    return Review(
      id: doc.id,
      reviewerId: d['reviewerId'] as String? ?? '',
      reviewerName: d['reviewerName'] as String? ?? '',
      reviewerPhotoUrl: d['reviewerPhotoUrl'] as String?,
      reviewedId: d['reviewedId'] as String? ?? '',
      fahrtId: d['fahrtId'] as String? ?? '',
      rating: (d['rating'] as num?)?.toInt() ?? 0,
      comment: d['comment'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}
