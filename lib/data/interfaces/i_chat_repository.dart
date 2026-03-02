import 'package:my_app/data/chat_message.dart';
import 'package:my_app/data/chat_conversation.dart';

abstract class IChatRepository {
  List<ChatMessage> getMessages(String conversationId);
  Future<void> addMessage(ChatMessage message);
  ChatConversation? getConversation(String id);
  Future<void> saveConversation(ChatConversation convo);
  ChatMessage? getSystemMessage(String conversationId);
}
