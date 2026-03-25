// lib/data/interessenten_daten.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class InteressentenDaten {
  /// Dokument-ID: {eventId}_{userId}
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DateTime timestamp;

  /// Wohnort-Bezirk des Interessenten (optional)
  final String? bezirk;

  InteressentenDaten({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.timestamp,
    this.bezirk,
  });

  static String buildId(String eventId, String userId) => '${eventId}_$userId';

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'bezirk': bezirk,
      };

  factory InteressentenDaten.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['timestamp'];
    final DateTime timestamp;
    if (raw is Timestamp) {
      timestamp = raw.toDate();
    } else {
      timestamp = DateTime.now();
    }
    return InteressentenDaten(
      id: id,
      eventId: map['eventId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userPhotoUrl: map['userPhotoUrl'] as String?,
      timestamp: timestamp,
      bezirk: map['bezirk'] as String?,
    );
  }
}
