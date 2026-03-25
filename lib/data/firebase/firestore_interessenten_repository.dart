// lib/data/firebase/firestore_interessenten_repository.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/data/interessenten_daten.dart';
import 'package:my_app/data/interfaces/i_interessenten_repository.dart';

class FirestoreInteressentenRepository implements IInteressentenRepository {
  final CollectionReference _col;

  FirestoreInteressentenRepository()
      : _col = FirebaseFirestore.instance.collection('interessenten');

  @override
  Stream<List<InteressentenDaten>> watchForEvent(String eventId) {
    return _col
        .where('eventId', isEqualTo: eventId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => InteressentenDaten.fromMap(
                d.id, d.data() as Map<String, dynamic>))
            .toList())
        .transform(StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (_, __, sink) => sink.add([]),
        ));
  }

  @override
  Future<InteressentenDaten?> get(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return InteressentenDaten.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> add(InteressentenDaten interessent) async {
    await _col.doc(interessent.id).set(interessent.toMap());
  }

  @override
  Future<void> remove(String id) async {
    await _col.doc(id).delete();
  }
}
