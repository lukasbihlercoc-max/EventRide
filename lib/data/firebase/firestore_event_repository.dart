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
      final now = DateTime.now();
      final all = snap.docs
          .map((doc) => Event.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Container-Events bleiben sichtbar, solange auch nur einer ihrer
      // Kind-Tage noch nicht vorbei ist — dafür brauchen wir das späteste
      // Kind-Datum je containerId aus demselben Snapshot.
      final latestChildDatumByContainer = <String, DateTime>{};
      for (final e in all) {
        final containerId = e.containerId;
        if (containerId == null) continue;
        final current = latestChildDatumByContainer[containerId];
        if (current == null || e.datum.isAfter(current)) {
          latestChildDatumByContainer[containerId] = e.datum;
        }
      }

      final events = all.where((e) {
        final effectiveDatum = e.isContainer
            ? (latestChildDatumByContainer[e.id] ?? e.datum)
            : e.datum;
        // Event bleibt sichtbar bis 6:00 Uhr des Folgetags (lokale Zeit)
        return now.isBefore(eventHideAfter(effectiveDatum));
      }).toList();

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
