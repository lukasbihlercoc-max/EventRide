// chat_conversation.dart
import 'package:hive/hive.dart';

part 'chat_conversation.g.dart';

@HiveType(typeId: 41)
class ChatConversation {
  @HiveField(0)
  final String id; // = fahrtId_requesterId

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
}
