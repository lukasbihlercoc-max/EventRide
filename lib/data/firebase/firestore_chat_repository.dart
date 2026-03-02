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
        .orderBy('createdAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());
  }

  /// Echtzeit-Conversations des Users, absteigend nach lastMessageAt.
  /// Benötigt Firestore Composite Index: participants (array-contains) + lastMessageAt (desc).
  @override
  Stream<List<ChatConversation>> conversationsStream(String userId) {
    return _db
        .collection(_col)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatConversation.fromMap(d.id, d.data()))
            .toList());
  }

  // ── Writes ───────────────────────────────────────────────────────────────

  /// Schreibt eine Nachricht in die Subcollection.
  /// Bei normalen Nachrichten wird zusätzlich lastMessage + lastMessageAt aktualisiert.
  /// Bei Systemnachrichten (feste ID) wird nur die Nachricht selbst überschrieben.
  @override
  Future<void> sendMessage(ChatMessage message) async {
    final convoRef = _db.collection(_col).doc(message.conversationId);

    final msgData = message.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp();

    await convoRef.collection('messages').doc(message.id).set(msgData);

    if (!message.isSystem) {
      await convoRef.update({
        'lastMessage': message.text,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Legt eine Conversation an – nur wenn sie noch nicht existiert (Transaction).
  /// Verhindert Race-Conditions bei gleichzeitigem Öffnen des Chats.
  @override
  Future<void> ensureConversation(ChatConversation convo) async {
    final ref = _db.collection(_col).doc(convo.id);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) {
        final data = convo.toMap()
          ..['createdAt'] = FieldValue.serverTimestamp()
          ..['lastMessageAt'] = FieldValue.serverTimestamp()
          ..['lastMessage'] = '';
        tx.set(ref, data);
      }
    });
  }
}
