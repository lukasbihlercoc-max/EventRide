// lib/data/anfrage_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/interessenten_daten.dart';
import 'package:my_app/data/interfaces/i_anfrage_repository.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';

class AnfrageService with ChangeNotifier {
  AnfrageService();

  late IAnfrageRepository _repository;
  final List<AnfrageDaten> _alleAnfragen = [];
  StreamSubscription<List<AnfrageDaten>>? _streamSub;
  StreamSubscription<AppUser?>? _authSub;

  /// Unveränderliche Kopie nach außen
  List<AnfrageDaten> get alleAnfragen => List.unmodifiable(_alleAnfragen);

  /// Muss vor der ersten Benutzung aufgerufen werden (z. B. in main).
  Future<void> init(IAnfrageRepository repository, IAuthRepository auth) async {
    _repository = repository;
    _startListening();

    _authSub?.cancel();
    _authSub = auth.authStateChanges.listen((user) {
      if (user != null) {
        _startListening();
      } else {
        // Logout: Stream stoppen, damit keine Permission-Denied-Fehler entstehen
        _streamSub?.cancel();
        _streamSub = null;
        _alleAnfragen.clear();
        notifyListeners();
      }
    });
  }

  void _startListening() {
    _streamSub?.cancel();
    _streamSub = _repository.watch().listen((anfragen) {
      _alleAnfragen
        ..clear()
        ..addAll(anfragen);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------
  // CRUD
  // -------------------------------------------------------------

  Future<void> addAnfrage(AnfrageDaten anfrage) async {
    try {
      await _repository.add(anfrage);
      // Stream-Update kommt automatisch via _startListening().
    } catch (_) {
      rethrow;
    }
  }

  /// Rückgabe: true wenn erfolgreich, false wenn nicht gefunden oder Fehler.
  Future<bool> updateAnfrage(String id, AnfrageDaten updated) async {
    try {
      final index = _alleAnfragen.indexWhere((a) => a.id == id);
      if (index == -1) return false;

      await _repository.update(updated);
      _alleAnfragen[index] = updated;
      notifyListeners();

      return true;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------
  // FILTER-FUNKTIONEN
  // -------------------------------------------------------------

  /// Gibt true zurück wenn für diese Fahrt bereits eine offene
  /// Einladung an den Interessenten existiert (Spam-Schutz).
  bool hatOffeneEinladungFuer(String fahrtId, String interessentId) {
    return _alleAnfragen.any((a) =>
        a.fahrtId == fahrtId &&
        a.requesterId == interessentId &&
        a.status == AnfrageStatus.offen);
  }

  /// Fahrer lädt einen Interessenten ein (vonFahrer = true).
  /// Gibt false zurück wenn bereits eine offene Einladung existiert.
  Future<bool> einladenVomFahrer({
    required FahrtDaten fahrt,
    required InteressentenDaten interessent,
    required String fahrerName,
  }) async {
    if (hatOffeneEinladungFuer(fahrt.id, interessent.userId)) return false;
    final anfrage = AnfrageDaten.create(
      fahrtId: fahrt.id,
      eventId: fahrt.eventId,
      requesterId: interessent.userId,
      requesterName: interessent.userName,
      seatsRequested: 1,
      fahrtOwnerId: fahrt.ownerId,
      eventName: fahrt.eventName,
      startOrt: fahrt.abfahrtsortAnzeige,
      zielOrt: fahrt.standort,
      fahrerName: fahrerName,
      vonFahrer: true,
    );
    await addAnfrage(anfrage);
    return true;
  }

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

    if (erlaubtePlaetze <= 0) return false;

    final updated = anfrage.copyWith(
      status: AnfrageStatus.akzeptiert,
      seatsAccepted: erlaubtePlaetze,
    );

    await _repository.update(updated);
    final index = _alleAnfragen.indexWhere((a) => a.id == anfrage.id);
    if (index != -1) _alleAnfragen[index] = updated;
    notifyListeners();

    return true;
  }

  Future<bool> ablehnenAnfrage(AnfrageDaten anfrage) async {
    final updated = anfrage.copyWith(status: AnfrageStatus.abgelehnt);
    return await updateAnfrage(anfrage.id, updated);
  }

  /// Mitfahrer zieht eigene Anfrage zurück (Status → storniert).
  Future<bool> storniereAnfrage(AnfrageDaten anfrage) async {
    final updated = anfrage.copyWith(status: AnfrageStatus.storniert);
    return await updateAnfrage(anfrage.id, updated);
  }

  // -------------------------------------------------------------
  // LÖSCHEN / KASKADIERUNG
  // -------------------------------------------------------------

  Future<bool> cancelAnfragenForFahrt(String fahrtId) async {
    try {
      final relevant = _alleAnfragen.where((a) => a.fahrtId == fahrtId).toList();

      for (final a in relevant) {
        final updated = a.copyWith(status: AnfrageStatus.abgelehnt);
        await _repository.update(updated);
        final index = _alleAnfragen.indexWhere((x) => x.id == a.id);
        if (index != -1) _alleAnfragen[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
