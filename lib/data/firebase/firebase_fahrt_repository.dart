// firebase_fahrt_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/interfaces/i_fahrt_repository.dart';

/// Firestore-Implementierung von IFahrtRepository.
///
/// Hält einen lokalen In-Memory-Cache, damit [getAll] synchron bleibt
/// und die bestehende Service-API unverändert bleiben kann.
///
/// Verwendung in main.dart (wenn Hive ersetzt wird):
///   final fahrtRepository = await FirestoreFahrtRepository.create();
class FirestoreFahrtRepository implements IFahrtRepository {
  final FirebaseFirestore _firestore;
  final List<FahrtDaten> _cache = [];

  static const _collection = 'fahrten';

  FirestoreFahrtRepository._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Lädt alle Fahrten einmalig aus Firestore, dann ist das Repository bereit.
  static Future<FirestoreFahrtRepository> create({
    FirebaseFirestore? firestore,
  }) async {
    final repo = FirestoreFahrtRepository._(firestore: firestore);
    await repo._loadAll();
    return repo;
  }

  Future<void> _loadAll() async {
    final snapshot = await _firestore.collection(_collection).get();
    _cache
      ..clear()
      ..addAll(snapshot.docs.map((doc) => FahrtDaten.fromMap(doc.data())));
    if (kDebugMode) {
      debugPrint('🚗 FirestoreFahrtRepository: ${_cache.length} Fahrten geladen');
    }
  }

  // ------------------------------------------------------------------
  // IFahrtRepository
  // ------------------------------------------------------------------

  /// Gibt den lokalen Cache synchron zurück (kompatibel mit FahrtService).
  @override
  List<FahrtDaten> getAll() => List.unmodifiable(_cache);

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
