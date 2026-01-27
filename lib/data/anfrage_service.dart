// lib/data/anfrage_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/fahrt_daten.dart';

/// AnfrageService
/// - Kein async im Konstruktor
/// - public Future<void> init() muss vor der Nutzung aufgerufen werden
/// - speichert Anfragen keyed unter anfrage.id (box.put(id, anfrage))
class AnfrageService with ChangeNotifier {
  static final AnfrageService _instance = AnfrageService._internal();
  factory AnfrageService() => _instance;

  // synchroner privater Konstruktor — KEINE async-Aufrufe hier
  AnfrageService._internal();

  late Box<AnfrageDaten> _anfragenBox;
  final List<AnfrageDaten> _alleAnfragen = [];

  /// Unveränderliche Kopie nach außen
  List<AnfrageDaten> get alleAnfragen => List.unmodifiable(_alleAnfragen);

  /// Muss vor der ersten Benutzung aufgerufen werden (z. B. in main)
  Future<void> init() async {
    // Erwartet, dass die Box in main bereits geöffnet wurde (await Hive.openBox...)
    _anfragenBox = Hive.box<AnfrageDaten>('anfragen');
    _loadAnfragen();
  }

  void _loadAnfragen() {
    _alleAnfragen
      ..clear()
      ..addAll(_anfragenBox.values);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // CRUD
  // -------------------------------------------------------------

  /// Fügt eine Anfrage hinzu. Verwende die eindeutige anfrage.id als Key.
  Future<void> addAnfrage(AnfrageDaten anfrage) async {
    try {
      await _anfragenBox.put(anfrage.id, anfrage);
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

  /// Aktualisiert eine Anfrage anhand ihrer id.
  /// Rückgabe: true wenn erfolgreich, false wenn nicht gefunden oder Fehler.
  Future<bool> updateAnfrage(String id, AnfrageDaten updated) async {
    try {
      if (!_anfragenBox.containsKey(id)) {
        if (kDebugMode) debugPrint('updateAnfrage: id=$id nicht gefunden');
        return false;
      }

      await _anfragenBox.put(id, updated);
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

  /// Alle Anfragen zu einer bestimmten Fahrt
  List<AnfrageDaten> getAnfragenForFahrt(String fahrtId) {
    return _alleAnfragen.where((a) => a.fahrtId == fahrtId).toList();
  }

  /// Alle Anfragen, die ein bestimmter Fahrer erhalten hat
  List<AnfrageDaten> getAnfragenForFahrer(String fahrerId) {
    return _alleAnfragen.where((a) => a.fahrtOwnerId == fahrerId).toList();
  }

  /// Alle Anfragen, die EIN User gestellt hat
  List<AnfrageDaten> getAnfragenByRequester(String requesterId) {
    return _alleAnfragen.where((a) => a.requesterId == requesterId).toList();
  }

  // -------------------------------------------------------------
  // STATUS-HILFSMETHODEN: akzeptieren / ablehnen
  // -------------------------------------------------------------

  /// Akzeptiert eine Anfrage und setzt seatsAccepted
  /// Rückgabe: true wenn erfolgreich
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

    await _anfragenBox.put(anfrage.id, updated);
    _loadAnfragen();

    return true;
  }


  /// Lehnt eine Anfrage ab
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

  /// Setzt alle Anfragen für eine Fahrt auf 'abgelehnt'.
  /// Rückgabe: true wenn mindestens eine Anfrage verarbeitet wurde oder wenn keine relevant war.
  Future<bool> cancelAnfragenForFahrt(String fahrtId) async {
    try {
      // Kopie, damit wir während des Loopens gefahrlos updaten können
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
