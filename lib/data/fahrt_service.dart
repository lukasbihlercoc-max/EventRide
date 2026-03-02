// fahrt_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'fahrt_daten.dart';
import 'interfaces/i_fahrt_repository.dart';

class FahrtService with ChangeNotifier {
  final IFahrtRepository _repo;

  FahrtService(this._repo);

  final List<FahrtDaten> _fahrten = [];
  StreamSubscription<List<FahrtDaten>>? _subscription;

  List<FahrtDaten> get alleFahrten => List.unmodifiable(_fahrten);

  /// Echtzeit-Stream starten (einmal beim App-Start aufrufen).
  /// Aktualisiert die Liste automatisch bei Änderungen anderer Geräte.
  Future<void> load() async {
    _subscription?.cancel();
    _subscription = _repo.watch().listen((fahrten) {
      _fahrten
        ..clear()
        ..addAll(fahrten);
      _sort();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> add(FahrtDaten fahrt) async {
    debugPrint('🚗 [FahrtService.add] Starte, id=${fahrt.id}');
    await _repo.add(fahrt);
    debugPrint('✅ [FahrtService.add] _repo.add() fertig');
    // Stream-Update kommt automatisch; optimistisch lokal einfügen:
    if (!_fahrten.any((f) => f.id == fahrt.id)) {
      _fahrten.add(fahrt);
      _sort();
      notifyListeners();
    }
    debugPrint('✅ [FahrtService.add] fertig');
  }

  Future<void> update(FahrtDaten fahrt) async {
    await _repo.update(fahrt);
    final index = _fahrten.indexWhere((f) => f.id == fahrt.id);
    if (index != -1) {
      _fahrten[index] = fahrt;
    }
    _sort();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _fahrten.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  List<FahrtDaten> getFahrtenByUser(String userId) {
    return _fahrten.where((f) => f.ownerId == userId).toList();
  }

  List<FahrtDaten> getFahrtenByEvent(String eventId) {
    return _fahrten.where((f) => f.eventId == eventId).toList();
  }

  void _sort() {
    _fahrten.sort((a, b) => a.uhrzeitHour.compareTo(b.uhrzeitHour));
  }
}
