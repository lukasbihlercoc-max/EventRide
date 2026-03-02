// lib/data/anfrage_service.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/interfaces/i_anfrage_repository.dart';

class AnfrageService with ChangeNotifier {
  static final AnfrageService _instance = AnfrageService._internal();
  factory AnfrageService() => _instance;

  AnfrageService._internal();

  late IAnfrageRepository _repository;
  final List<AnfrageDaten> _alleAnfragen = [];
  StreamSubscription<User?>? _authSub;

  /// Unveränderliche Kopie nach außen
  List<AnfrageDaten> get alleAnfragen => List.unmodifiable(_alleAnfragen);

  /// Muss vor der ersten Benutzung aufgerufen werden (z. B. in main).
  /// Lädt Daten nach Login automatisch nach (z. B. wenn Firestore Auth erfordert).
  Future<void> init(IAnfrageRepository repository) async {
    _repository = repository;
    _loadAnfragen();

    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _repository.reload();
        _loadAnfragen();
      }
    });
  }

  void _loadAnfragen() {
    _alleAnfragen
      ..clear()
      ..addAll(_repository.getAll());
    notifyListeners();
  }

  // -------------------------------------------------------------
  // CRUD
  // -------------------------------------------------------------

  Future<void> addAnfrage(AnfrageDaten anfrage) async {
    try {
      await _repository.add(anfrage);
      _loadAnfragen();

      if (kDebugMode) {
        debugPrint("📨 Neue Anfrage gespeichert: ${anfrage.id}");
        debugPrint("  -> Gesamtanzahl: ${_alleAnfragen.length}");
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('addAnfrage Fehler: $e\n$st');
      rethrow;
    }
  }

  /// Rückgabe: true wenn erfolgreich, false wenn nicht gefunden oder Fehler.
  Future<bool> updateAnfrage(String id, AnfrageDaten updated) async {
    try {
      if (!_alleAnfragen.any((a) => a.id == id)) {
        if (kDebugMode) debugPrint('updateAnfrage: id=$id nicht gefunden');
        return false;
      }

      await _repository.update(updated);
      _loadAnfragen();

      if (kDebugMode) debugPrint('🔄 Anfrage mit ID $id aktualisiert');
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('updateAnfrage Fehler: $e\n$st');
      return false;
    }
  }

  // -------------------------------------------------------------
  // FILTER-FUNKTIONEN
  // -------------------------------------------------------------

  List<AnfrageDaten> getAnfragenForFahrt(String fahrtId) {
    return _alleAnfragen.where((a) => a.fahrtId == fahrtId).toList();
  }

  List<AnfrageDaten> getAnfragenForFahrer(String fahrerId) {
    return _alleAnfragen.where((a) => a.fahrtOwnerId == fahrerId).toList();
  }

  List<AnfrageDaten> getAnfragenByRequester(String requesterId) {
    return _alleAnfragen.where((a) => a.requesterId == requesterId).toList();
  }

  // -------------------------------------------------------------
  // STATUS-HILFSMETHODEN
  // -------------------------------------------------------------

  Future<bool> akzeptiereAnfrage({
    required AnfrageDaten anfrage,
    required FahrtDaten fahrt,
    required int seatsAccepted,
  }) async {
    final erlaubtePlaetze = seatsAccepted.clamp(1, fahrt.freiePlaetze);

    if (erlaubtePlaetze <= 0) {
      if (kDebugMode) {
        debugPrint("❌ Keine freien Plätze mehr für Fahrt ${fahrt.id}");
      }
      return false;
    }

    final updated = anfrage.copyWith(
      status: AnfrageStatus.akzeptiert,
      seatsAccepted: erlaubtePlaetze,
    );

    await _repository.update(updated);
    _loadAnfragen();

    return true;
  }

  Future<bool> ablehnenAnfrage(AnfrageDaten anfrage) async {
    final updated = anfrage.copyWith(status: AnfrageStatus.abgelehnt);
    final ok = await updateAnfrage(anfrage.id, updated);
    if (kDebugMode) {
      if (ok) {
        debugPrint("🚫 Anfrage ${anfrage.id} abgelehnt");
      } else {
        debugPrint("❌ ablehnenAnfrage: Update fehlgeschlagen für ${anfrage.id}");
      }
    }
    return ok;
  }

  // -------------------------------------------------------------
  // LÖSCHEN / KASKADIERUNG
  // -------------------------------------------------------------

  Future<bool> cancelAnfragenForFahrt(String fahrtId) async {
    try {
      final relevant = _alleAnfragen.where((a) => a.fahrtId == fahrtId).toList();

      for (final a in relevant) {
        final updated = a.copyWith(status: AnfrageStatus.abgelehnt);
        await updateAnfrage(a.id, updated);
      }

      if (kDebugMode) {
        debugPrint("🚫 Alle Anfragen für Fahrt $fahrtId wurden auf 'abgelehnt' gesetzt");
      }

      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('cancelAnfragenForFahrt Fehler: $e\n$st');
      return false;
    }
  }
}
