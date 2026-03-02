// chat_repository.dart
import 'package:hive/hive.dart';
import 'chat_message.dart';
import 'chat_conversation.dart';
import 'interfaces/i_chat_repository.dart';

class ChatRepository implements IChatRepository {
  final Box<ChatConversation> conversationBox;
  final Box<ChatMessage> messageBox;

  ChatRepository(this.conversationBox, this.messageBox);

  @override
  List<ChatMessage> getMessages(String conversationId) {
    return messageBox.values
        .where((m) => m.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> addMessage(ChatMessage message) async {
    await messageBox.put(message.id, message);
  }

  @override
  ChatConversation? getConversation(String id) {
    return conversationBox.get(id);
  }

  @override
  Future<void> saveConversation(ChatConversation convo) async {
    await conversationBox.put(convo.id, convo);
  }

  @override
  ChatMessage? getSystemMessage(String conversationId) {
    try {
      return messageBox.values.firstWhere(
        (m) => m.conversationId == conversationId && m.isSystem,
      );
    } catch (_) {
      return null;
    }
  }
}
