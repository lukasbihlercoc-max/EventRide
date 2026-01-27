import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'chat_repository.dart';
import 'chat_conversation.dart';
import 'chat_message.dart';

class ChatService with ChangeNotifier {
  final ChatRepository _repo;
  final _uuid = const Uuid();

  ChatService(this._repo);

  /// ------------------------------------------------------------
  /// 🔑 ZENTRALE REGEL: stabile Conversation-ID
  /// Eine Fahrt + zwei User = genau ein Chat
  /// ------------------------------------------------------------
  String buildConversationId({
    required String fahrtId,
    required String userA,
    required String userB,
  }) {
    final ids = [userA, userB]..sort();
    return "${fahrtId}_${ids[0]}_${ids[1]}";
  }

  /// ------------------------------------------------------------
  /// 🔹 Conversation sicherstellen (existiert oder wird erstellt)
  /// ------------------------------------------------------------
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
      fahrtId: fahrtId,
      userA: ownerId,
      userB: requesterId,
    );

    final existing = _repo.getConversation(conversationId);
    if (existing != null) {
      return existing;
    }

    final convo = ChatConversation(
      id: conversationId,
      fahrtId: fahrtId,
      ownerId: ownerId,
      requesterId: requesterId,
      lastUpdated: DateTime.now(),
    );

    await _repo.saveConversation(convo);
    return convo;
  }

  /// ------------------------------------------------------------
  /// 🔹 Nachrichten einer Conversation abrufen
  /// ------------------------------------------------------------
  List<ChatMessage> getMessages(String conversationId) {
    return _repo.getMessages(conversationId);
  }

  /// ------------------------------------------------------------
  /// 🔹 Normale Nachricht senden
  /// ------------------------------------------------------------
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

    await _repo.addMessage(message);
    notifyListeners();
  }

  /// ------------------------------------------------------------
  /// 🔹 SYSTEMNACHRICHT erstellen ODER aktualisieren
  /// (wird bei Annahme / Teilannahme verwendet)
  /// ------------------------------------------------------------
  Future<void> updateSystemMessage({
    required String conversationId,
    required String eventName,
    required String startOrt,
    required String zielOrt,
    required int seatsRequested,
    required int seatsAccepted,
  }) async {
    final messages = _repo.getMessages(conversationId);
    final systemMessages = messages.where((m) => m.isSystem).toList();

    final buffer = StringBuffer()
      ..writeln("🚗 Mitfahranfrage")
      ..writeln("")
      ..writeln("Event: $eventName")
      ..writeln("Strecke: $startOrt → $zielOrt")
      ..writeln(
        "Angefragt: $seatsRequested Platz${seatsRequested > 1 ? 'e' : ''}",
      );

    // ✅ HIER IST DER ENTSCHEIDENDE TEIL
    if (seatsAccepted > 0) {
      buffer.writeln(
        "Akzeptiert: $seatsAccepted Platz${seatsAccepted > 1 ? 'e' : ''}",
      );
    }

    final text = buffer.toString();

    // 🔹 Falls noch keine Systemmessage existiert → neu anlegen
    if (systemMessages.isEmpty) {
      final msg = ChatMessage(
        id: _uuid.v4(),
        conversationId: conversationId,
        senderId: 'system',
        isSystem: true,
        createdAt: DateTime.now(),
        text: text,
      );

      await _repo.addMessage(msg);
      notifyListeners();
      return;
    }

    // 🔹 Bestehende überschreiben (gleiche ID!)
    final old = systemMessages.last;

    final updated = ChatMessage(
      id: old.id,
      conversationId: old.conversationId,
      senderId: old.senderId,
      isSystem: true,
      createdAt: old.createdAt,
      text: text,
    );

    await _repo.addMessage(updated);
    notifyListeners();
  }

}
