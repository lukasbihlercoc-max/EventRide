// chat_conversation.dart
import 'package:hive/hive.dart';

part 'chat_conversation.g.dart';

@HiveType(typeId: 41)
class ChatConversation {
  @HiveField(0)
  final String id; // = sorted(uidA, uidB).join('_')

  @HiveField(1)
  final String fahrtId;

  @HiveField(2)
  final String ownerId;

  @HiveField(3)
  final String requesterId;

  @HiveField(4)
  final DateTime lastUpdated;

  ChatConversation({
    required this.id,
    required this.fahrtId,
    required this.ownerId,
    required this.requesterId,
    required this.lastUpdated,
  });

  /// Serialisierung für Firestore.
  /// participants = [ownerId, requesterId] für Security Rules und arrayContains-Queries.
  /// createdAt + lastMessageAt werden im Repository per FieldValue.serverTimestamp() gesetzt.
  Map<String, dynamic> toMap() => {
        'id': id,
        'fahrtId': fahrtId,
        'ownerId': ownerId,
        'requesterId': requesterId,
        'participants': [ownerId, requesterId],
      };

  factory ChatConversation.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['lastMessageAt'] ?? map['createdAt'];
    final DateTime lastUpdated;
    if (raw is DateTime) {
      lastUpdated = raw;
    } else if (raw != null) {
      lastUpdated = (raw as dynamic).toDate() as DateTime;
    } else {
      lastUpdated = DateTime.now();
    }
    return ChatConversation(
      id: id,
      fahrtId: map['fahrtId'] as String? ?? '',
      ownerId: map['ownerId'] as String,
      requesterId: map['requesterId'] as String,
      lastUpdated: lastUpdated,
    );
  }
}
