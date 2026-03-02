// fahrt_service.dart
import 'package:flutter/foundation.dart';
import 'fahrt_daten.dart';
import 'interfaces/i_fahrt_repository.dart';

class FahrtService with ChangeNotifier {
  final IFahrtRepository _repo;

  FahrtService(this._repo);

  final List<FahrtDaten> _fahrten = [];

  List<FahrtDaten> get alleFahrten => List.unmodifiable(_fahrten);

  /// Initiales Laden (einmal beim App-Start aufrufen)
  Future<void> load() async {
    _fahrten
      ..clear()
      ..addAll(_repo.getAll());
    _sort();
    notifyListeners();
  }

  Future<void> add(FahrtDaten fahrt) async {
    await _repo.add(fahrt);
    _fahrten.add(fahrt);
    _sort();
    notifyListeners();
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
