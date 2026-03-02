// chat_message.dart
import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 40)
class ChatMessage {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String conversationId;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String text;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
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
