import 'package:uuid/uuid.dart';

import 'chat_conversation.dart';
import 'chat_message.dart';
import 'interfaces/i_chat_repository.dart';

class ChatService {
  final IChatRepository _repo;
  final _uuid = const Uuid();

  ChatService(this._repo);

  // ── Conversation-ID ───────────────────────────────────────────────────────
  /// Deterministisch: sorted([userA, userB]).join('_')
  /// Kein fahrtId – ein User-Paar hat genau einen Chat.
  String buildConversationId({
    required String userA,
    required String userB,
  }) {
    final ids = [userA, userB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<List<ChatMessage>> messagesStream(String conversationId) =>
      _repo.messagesStream(conversationId);

  Stream<List<ChatConversation>> conversationsStream(String userId) =>
      _repo.conversationsStream(userId);

  // ── Conversation anlegen ──────────────────────────────────────────────────

  Future<ChatConversation> ensureConversation({
    required String fahrtId,
    required String ownerId,
    required String requesterId,
    required String eventName,
    required String startOrt,
    required String zielOrt,
    required int seatsRequested,
  }) async {
    final conversationId = buildConversationId(
      userA: ownerId,
      userB: requesterId,
    );

    final convo = ChatConversation(
      id: conversationId,
      fahrtId: fahrtId,
      ownerId: ownerId,
      requesterId: requesterId,
      lastUpdated: DateTime.now(),
    );

    await _repo.ensureConversation(convo);
    return convo;
  }

  // ── Nachrichten ───────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final message = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    await _repo.sendMessage(message);
  }

  /// Erstellt oder überschreibt die Systemnachricht einer Conversation.
  /// Feste Dokument-ID: '${conversationId}_system' – kein get() nötig.
  Future<void> updateSystemMessage({
    required String conversationId,
    required String eventName,
    required String startOrt,
    required String zielOrt,
    required int seatsRequested,
    required int seatsAccepted,
  }) async {
    final buffer = StringBuffer()
      ..writeln('🚗 Mitfahranfrage')
      ..writeln('')
      ..writeln('Event: $eventName')
      ..writeln('Strecke: $startOrt → $zielOrt')
      ..writeln(
        'Angefragt: $seatsRequested Platz${seatsRequested > 1 ? 'e' : ''}',
      );

    if (seatsAccepted > 0) {
      buffer.writeln(
        'Akzeptiert: $seatsAccepted Platz${seatsAccepted > 1 ? 'e' : ''}',
      );
    }

    final systemMessage = ChatMessage(
      id: '${conversationId}_system',
      conversationId: conversationId,
      senderId: 'system',
      isSystem: true,
      createdAt: DateTime.now(),
      text: buffer.toString(),
    );

    await _repo.sendMessage(systemMessage);
  }
}
