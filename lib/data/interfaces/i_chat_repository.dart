import 'package:my_app/data/chat_message.dart';
import 'package:my_app/data/chat_conversation.dart';

abstract class IChatRepository {
  /// Echtzeit-Stream aller Nachrichten einer Conversation, aufsteigend nach createdAt.
  Stream<List<ChatMessage>> messagesStream(String conversationId);

  /// Echtzeit-Stream aller Conversations des Users, absteigend nach lastMessageAt.
  Stream<List<ChatConversation>> conversationsStream(String userId);

  /// Schreibt eine Nachricht in die Subcollection und aktualisiert lastMessage/lastMessageAt.
  Future<void> sendMessage(ChatMessage message);

  /// Legt eine Conversation an – nur wenn sie noch nicht existiert (idempotent).
  Future<void> ensureConversation(ChatConversation convo);
}
