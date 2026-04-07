// lib/data/firebase/firestore_anfrage_repository.dart
import 'dart:async';
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

  static FirestoreAnfrageRepository create({FirebaseFirestore? firestore}) {
    return FirestoreAnfrageRepository._(firestore: firestore);
  }

  // ------------------------------------------------------------------
  // IAnfrageRepository
  // ------------------------------------------------------------------

  @override
  List<AnfrageDaten> getAll() => List.unmodifiable(_cache);

  /// Echtzeit-Stream für Anfragen des aktuellen Nutzers.
  /// Firestore erlaubt kein OR über zwei Felder in einer Query,
  /// daher werden zwei Streams gemergt.
  @override
  Stream<List<AnfrageDaten>> watch() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    final controller = StreamController<List<AnfrageDaten>>();

    List<AnfrageDaten> fromRequester = [];
    List<AnfrageDaten> fromOwner = [];

    void emit() {
      final seen = <String>{};
      final combined = [...fromRequester, ...fromOwner]
          .where((a) => seen.add(a.id))
          .toList();
      _cache
        ..clear()
        ..addAll(combined);
      if (kDebugMode) {
        debugPrint('📨 FirestoreAnfrageRepository: ${_cache.length} Anfragen (stream)');
      }
      controller.add(List.unmodifiable(_cache));
    }

    final subA = _firestore
        .collection(_collection)
        .where('requesterId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snap) {
        fromRequester =
            snap.docs.map((d) => AnfrageDaten.fromMap(d.data())).toList();
        emit();
      },
      onError: (_) {},
    );

    final subB = _firestore
        .collection(_collection)
        .where('fahrtOwnerId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snap) {
        fromOwner =
            snap.docs.map((d) => AnfrageDaten.fromMap(d.data())).toList();
        emit();
      },
      onError: (_) {},
    );

    controller.onCancel = () {
      subA.cancel();
      subB.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> add(AnfrageDaten anfrage) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(anfrage.id)
          .set(anfrage.toMap());
      _cache.add(anfrage);
    } on FirebaseException catch (e) {
      debugPrint('Fehler beim Speichern der Anfrage: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> update(AnfrageDaten anfrage) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(anfrage.id)
          .update(anfrage.toMap());
      final index = _cache.indexWhere((a) => a.id == anfrage.id);
      if (index != -1) _cache[index] = anfrage;
    } on FirebaseException catch (e) {
      debugPrint('Fehler beim Aktualisieren der Anfrage: ${e.message}');
      rethrow;
    }
  }
}
