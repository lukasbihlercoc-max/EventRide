// lib/data/firebase/firestore_anfrage_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/interfaces/i_anfrage_repository.dart';

class FirestoreAnfrageRepository implements IAnfrageRepository {
  final FirebaseFirestore _firestore;
  final List<AnfrageDaten> _cache = [];

  static const _collection = 'anfragen';

  FirestoreAnfrageRepository._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Lädt alle Anfragen einmalig aus Firestore, dann ist das Repository bereit.
  static Future<FirestoreAnfrageRepository> create({
    FirebaseFirestore? firestore,
  }) async {
    final repo = FirestoreAnfrageRepository._(firestore: firestore);
    await repo._loadAll();
    return repo;
  }

  Future<void> _loadAll() async {
    if (FirebaseAuth.instance.currentUser == null) {
      if (kDebugMode) debugPrint('📨 FirestoreAnfrageRepository: kein User → übersprungen');
      return;
    }
    final snapshot = await _firestore.collection(_collection).get();
    _cache
      ..clear()
      ..addAll(snapshot.docs.map((doc) => AnfrageDaten.fromMap(doc.data())));
    if (kDebugMode) {
      debugPrint('📨 FirestoreAnfrageRepository: ${_cache.length} Anfragen geladen');
    }
  }

  // ------------------------------------------------------------------
  // IAnfrageRepository
  // ------------------------------------------------------------------

  @override
  List<AnfrageDaten> getAll() => List.unmodifiable(_cache);

  @override
  Future<void> add(AnfrageDaten anfrage) async {
    await _firestore
        .collection(_collection)
        .doc(anfrage.id)
        .set(anfrage.toMap());
    _cache.add(anfrage);
  }

  @override
  Future<void> update(AnfrageDaten anfrage) async {
    await _firestore
        .collection(_collection)
        .doc(anfrage.id)
        .update(anfrage.toMap());
    final index = _cache.indexWhere((a) => a.id == anfrage.id);
    if (index != -1) _cache[index] = anfrage;
  }

  @override
  Future<void> reload() => _loadAll();
}
