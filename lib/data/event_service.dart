// event_service.dart
import 'package:flutter/foundation.dart';
import 'event_daten.dart';
import 'event_repository.dart';

class EventService with ChangeNotifier {
  final EventRepository _repo;

  EventService(this._repo);

  final List<Event> _events = [];

  List<Event> get events => List.unmodifiable(_events);

  /// Initiales Laden (explizit aufrufen!)
  Future<void> load() async {
    _events
      ..clear()
      ..addAll(_repo.getAll());
    _sort();
    notifyListeners();
  }

  Future<void> add(Event event) async {
    await _repo.add(event);
    _events.add(event);
    _sort();
    notifyListeners();
  }

  Future<void> update(Event event) async {
    await _repo.update(event);
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
    }
    _sort();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void _sort() {
    _events.sort((a, b) => a.datum.compareTo(b.datum));
  }
}
