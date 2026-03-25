// chat_message.dart
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isSystem;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isSystem = false,
  });

  /// Serialisierung für Firestore.
  /// createdAt wird im Repository durch FieldValue.serverTimestamp() überschrieben.
  Map<String, dynamic> toMap() => {
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text,
        'createdAt': createdAt,
        'isSystem': isSystem,
      };

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['createdAt'];
    final DateTime createdAt;
    if (raw is DateTime) {
      createdAt = raw;
    } else if (raw != null) {
      createdAt = (raw as dynamic).toDate() as DateTime;
    } else {
      createdAt = DateTime.now();
    }
    return ChatMessage(
      id: id,
      conversationId: map['conversationId'] as String,
      senderId: map['senderId'] as String,
      text: map['text'] as String,
      createdAt: createdAt,
      isSystem: map['isSystem'] as bool? ?? false,
    );
  }
}
