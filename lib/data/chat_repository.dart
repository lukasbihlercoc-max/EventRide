// chat_repository.dart
// Hive-Implementierung von IChatRepository.
// Wird nach vollständiger Firestore-Migration nicht mehr in main.dart genutzt,
// bleibt aber kompilierbar als Fallback.
import 'package:hive/hive.dart';
import 'chat_message.dart';
import 'chat_conversation.dart';
import 'interfaces/i_chat_repository.dart';

class ChatRepository implements IChatRepository {
  final Box<ChatConversation> conversationBox;
  final Box<ChatMessage> messageBox;

  ChatRepository(this.conversationBox, this.messageBox);

  @override
  Stream<List<ChatMessage>> messagesStream(String conversationId) {
    final messages = messageBox.values
        .where((m) => m.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Stream.value(messages);
  }

  @override
  Stream<List<ChatConversation>> conversationsStream(String userId) {
    final convos = conversationBox.values
        .where((c) => c.ownerId == userId || c.requesterId == userId)
        .toList();
    return Stream.value(convos);
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    await messageBox.put(message.id, message);
  }

  @override
  Future<void> ensureConversation(ChatConversation convo) async {
    if (!conversationBox.containsKey(convo.id)) {
      await conversationBox.put(convo.id, convo);
    }
  }
}
