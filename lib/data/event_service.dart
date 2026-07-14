// event_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'event_daten.dart';
import 'interfaces/i_event_repository.dart';

class EventService with ChangeNotifier {
  final IEventRepository _repo;

  EventService(this._repo);

  final List<Event> _events = [];
  StreamSubscription<List<Event>>? _subscription;

  List<Event> get events => List.unmodifiable(_events);

  /// Echtzeit-Stream starten (einmal beim App-Start aufrufen).
  /// Aktualisiert die Liste automatisch bei Änderungen anderer Geräte.
  Future<void> load() async {
    _subscription?.cancel();
    _subscription = _repo.watch().listen(
      (events) {
        _events
          ..clear()
          ..addAll(events);
        _sort();
        notifyListeners();
      },
      onError: (_) {
        // z. B. Firestore PERMISSION_DENIED im ausgeloggten Zustand → ignorieren
        _events.clear();
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> add(Event event) async {
    await _repo.add(event);
    if (!_events.any((e) => e.id == event.id)) {
      _events.add(event);
      _sort();
      notifyListeners();
    }
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
    _events.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return a.datum.compareTo(b.datum);
    });
  }
}
