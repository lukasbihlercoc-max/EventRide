// lib/data/interessenten_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:my_app/data/interessenten_daten.dart';
import 'package:my_app/data/interfaces/i_interessenten_repository.dart';

class InteressentenService extends ChangeNotifier {
  final IInteressentenRepository _repository;

  /// eventId → Interessenten-Liste (aus aktiven Streams)
  final Map<String, List<InteressentenDaten>> _cache = {};

  /// Aktive Stream-Subscriptions pro eventId
  final Map<String, StreamSubscription<List<InteressentenDaten>>> _subs = {};

  InteressentenService(this._repository);

  /// Gibt die gecachte Interessenten-Liste für ein Event zurück.
  /// Startet beim ersten Aufruf automatisch den Firestore-Stream.
  List<InteressentenDaten> getForEvent(String eventId) {
    _ensureWatching(eventId);
    return _cache[eventId] ?? [];
  }

  int countForEvent(String eventId) => getForEvent(eventId).length;

  bool isInteressiert(String eventId, String userId) {
    final id = InteressentenDaten.buildId(eventId, userId);
    return getForEvent(eventId).any((i) => i.id == id);
  }

  /// Toggled den "Ich will hin"-Status für den aktuellen User.
  /// Gibt [true] zurück wenn neu eingetragen, [false] wenn ausgetragen.
  /// Verwendet den In-Memory-Cache statt eines Firestore-Reads.
  Future<bool> toggle({
    required String eventId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? bezirk,
  }) async {
    final id = InteressentenDaten.buildId(eventId, userId);
    final existsInCache = (_cache[eventId] ?? []).any((i) => i.id == id);

    if (existsInCache) {
      await _repository.remove(id).timeout(const Duration(seconds: 8));
      return false;
    } else {
      await _repository
          .add(InteressentenDaten(
            id: id,
            eventId: eventId,
            userId: userId,
            userName: userName,
            userPhotoUrl: userPhotoUrl,
            timestamp: DateTime.now(),
            bezirk: bezirk,
          ))
          .timeout(const Duration(seconds: 8));
      return true;
    }
  }

  /// Entfernt den User aus allen Events (z. B. wenn er eine Fahrt bekommt).
  /// Macht nichts, wenn der User gar nicht in der Liste ist.
  Future<void> removeForUser(String eventId, String userId) async {
    final id = InteressentenDaten.buildId(eventId, userId);
    final existing = await _repository.get(id);
    if (existing != null) {
      await _repository.remove(id);
    }
  }

  void _ensureWatching(String eventId) {
    if (_subs.containsKey(eventId)) return;
    _subs[eventId] = _repository.watchForEvent(eventId).listen(
      (list) {
        _cache[eventId] = list;
        notifyListeners();
      },
      onError: (_) {
        // Stream hatte Fehler (z.B. PERMISSION_DENIED vor Auth-Init)
        // → Subscription entfernen damit beim nächsten Aufruf neu gestartet wird
        _subs.remove(eventId);
      },
      onDone: () {
        // Stream geschlossen → ebenfalls neu startbar machen
        _subs.remove(eventId);
      },
    );
  }

  @override
  void dispose() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
