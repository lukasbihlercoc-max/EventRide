// chat_conversation.dart
class ChatConversation {
  final String id; // = sorted(uidA, uidB).join('_')
  final String fahrtId;
  final String ownerId;
  final String requesterId;
  final DateTime lastUpdated;
  final String? lastMessage;
  final String? lastSenderId;

  ChatConversation({
    required this.id,
    required this.fahrtId,
    required this.ownerId,
    required this.requesterId,
    required this.lastUpdated,
    this.lastMessage,
    this.lastSenderId,
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
      lastMessage: map['lastMessage'] as String?,
      lastSenderId: map['lastSenderId'] as String?,
    );
  }
}
