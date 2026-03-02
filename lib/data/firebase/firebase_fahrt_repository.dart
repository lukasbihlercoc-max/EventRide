// firebase_fahrt_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/interfaces/i_fahrt_repository.dart';

class FirestoreFahrtRepository implements IFahrtRepository {
  final FirebaseFirestore _firestore;
  final List<FahrtDaten> _cache = [];

  static const _collection = 'fahrten';

  FirestoreFahrtRepository._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static FirestoreFahrtRepository create({FirebaseFirestore? firestore}) {
    return FirestoreFahrtRepository._(firestore: firestore);
  }

  // ------------------------------------------------------------------
  // IFahrtRepository
  // ------------------------------------------------------------------

  /// Gibt den lokalen Cache synchron zurück.
  @override
  List<FahrtDaten> getAll() => List.unmodifiable(_cache);

  /// Echtzeit-Stream: feuert bei jeder Änderung in Firestore.
  @override
  Stream<List<FahrtDaten>> watch() {
    return _firestore.collection(_collection).snapshots().map((snap) {
      final fahrten =
          snap.docs.map((doc) => FahrtDaten.fromMap(doc.data())).toList();
      if (kDebugMode) {
        debugPrint('🚗 FirestoreFahrtRepository: ${fahrten.length} Fahrten (stream)');
      }
      _cache
        ..clear()
        ..addAll(fahrten);
      return List.unmodifiable(_cache);
    });
  }

  /// Schreibt nach Firestore und fügt dem Cache hinzu.
  @override
  Future<void> add(FahrtDaten fahrt) async {
    await _firestore.collection(_collection).doc(fahrt.id).set(fahrt.toMap());
    _cache.add(fahrt);
  }

  /// Aktualisiert Firestore und den Cache.
  @override
  Future<void> update(FahrtDaten fahrt) async {
    await _firestore
        .collection(_collection)
        .doc(fahrt.id)
        .update(fahrt.toMap());
    final index = _cache.indexWhere((f) => f.id == fahrt.id);
    if (index != -1) _cache[index] = fahrt;
  }

  /// Löscht aus Firestore und aus dem Cache.
  @override
  Future<void> delete(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
    _cache.removeWhere((f) => f.id == id);
  }
}
