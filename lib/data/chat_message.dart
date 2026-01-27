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
}
