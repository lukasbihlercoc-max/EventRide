// firestore_event_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/interfaces/i_event_repository.dart';

class FirestoreEventRepository implements IEventRepository {
  final FirebaseFirestore _firestore;
  final List<Event> _cache = [];

  static const _collection = 'events';

  FirestoreEventRepository._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static FirestoreEventRepository create({FirebaseFirestore? firestore}) {
    return FirestoreEventRepository._(firestore: firestore);
  }

  // ------------------------------------------------------------------
  // IEventRepository
  // ------------------------------------------------------------------

  @override
  List<Event> getAll() => List.unmodifiable(_cache);

  /// Echtzeit-Stream: feuert bei jeder Änderung in Firestore.
  @override
  Stream<List<Event>> watch() {
    return _firestore.collection(_collection).snapshots().map((snap) {
      final events = snap.docs
          .map((doc) => Event.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      _cache
        ..clear()
        ..addAll(events);
      return List.unmodifiable(_cache);
    });
  }

  @override
  Future<void> add(Event event) async {
    await _firestore.collection(_collection).doc(event.id).set(event.toMap());
    _cache.add(event);
  }

  @override
  Future<void> update(Event event) async {
    await _firestore
        .collection(_collection)
        .doc(event.id)
        .update(event.toMap());
    final index = _cache.indexWhere((e) => e.id == event.id);
    if (index != -1) _cache[index] = event;
  }

  @override
  Future<void> delete(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
    _cache.removeWhere((e) => e.id == id);
  }
}
