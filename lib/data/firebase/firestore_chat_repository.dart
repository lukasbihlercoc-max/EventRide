// firestore_chat_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/data/chat_conversation.dart';
import 'package:my_app/data/chat_message.dart';
import 'package:my_app/data/interfaces/i_chat_repository.dart';

class FirestoreChatRepository implements IChatRepository {
  final FirebaseFirestore _db;
  static const _col = 'chat_conversations';

  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ── Streams ──────────────────────────────────────────────────────────────

  /// Echtzeit-Nachrichten einer Conversation, aufsteigend nach Server-Timestamp.
  @override
  Stream<List<ChatMessage>> messagesStream(String conversationId) {
    return _db
        .collection(_col)
        .doc(conversationId)
        .collection('messages')
        .snapshots()
        .map((snap) {
          final result = <ChatMessage>[];
          for (final d in snap.docs) {
            try {
              result.add(ChatMessage.fromMap(d.id, d.data()));
            } catch (_) {}
          }
          return result..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });
  }

  /// Echtzeit-Conversations des Users, absteigend nach lastMessageAt.
  /// Benötigt Firestore Composite Index: participants (array-contains) + lastMessageAt (desc).
  @override
  Stream<List<ChatConversation>> conversationsStream(String userId) {
    return _db
        .collection(_col)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snap) {
          final result = <ChatConversation>[];
          for (final d in snap.docs) {
            try {
              result.add(ChatConversation.fromMap(d.id, d.data()));
            } catch (_) {}
          }
          return result..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        });
  }

  // ── Writes ───────────────────────────────────────────────────────────────

  /// Schreibt eine Nachricht in die Subcollection.
  /// Bei normalen Nachrichten wird zusätzlich lastMessage + lastMessageAt aktualisiert.
  /// Bei Systemnachrichten (feste ID) wird nur die Nachricht selbst überschrieben.
  @override
  Future<void> sendMessage(ChatMessage message) async {
    try {
      final convoRef = _db.collection(_col).doc(message.conversationId);

      final msgData = message.toMap()
        ..['createdAt'] = FieldValue.serverTimestamp();

      await convoRef.collection('messages').doc(message.id).set(msgData);

      if (!message.isSystem) {
        await convoRef.update({
          'lastMessage': message.text,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastSenderId': message.senderId,
        });
      }
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Legt eine Conversation an oder aktualisiert sie (merge).
  /// Kein Transaction-Roundtrip → schreibt sofort in den lokalen Cache,
  /// await löst sofort auf. Das ermöglicht das direkte Chaining mit
  /// updateSystemMessage ohne Netzwerk-Blockierung.
  @override
  Future<void> ensureConversation(ChatConversation convo) async {
    try {
      final ref = _db.collection(_col).doc(convo.id);
      final data = convo.toMap()
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['lastMessageAt'] = FieldValue.serverTimestamp()
        ..['lastMessage'] = '';
      await ref.set(data, SetOptions(merge: true));
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> markConversationRead(
      String conversationId, String userId) async {
    try {
      await _db.collection(_col).doc(conversationId).update({
        'lastRead.$userId': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // not-found: Conversation existiert noch nicht (Race mit ensureConversation)
      // permission-denied: Conversation ohne participants-Feld (Altdaten) → nicht kritisch
      if (e.code != 'not-found' && e.code != 'permission-denied') rethrow;
    }
  }

  @override
  Stream<bool> hasAnyUnreadStream(String userId) {
    return _db
        .collection(_col)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.any((doc) {
              final data = doc.data();
              // Eigene Nachrichten sind nie ungelesen
              if (data['lastSenderId'] == userId) return false;
              if (data['lastMessageAt'] == null) return false;
              final lastMessageAt =
                  (data['lastMessageAt'] as Timestamp).toDate();
              final lastReadMap =
                  data['lastRead'] as Map<String, dynamic>?;
              if (lastReadMap == null || lastReadMap[userId] == null) {
                return true;
              }
              final lastReadAt =
                  (lastReadMap[userId] as Timestamp).toDate();
              return lastMessageAt.isAfter(lastReadAt);
            }));
  }
}
