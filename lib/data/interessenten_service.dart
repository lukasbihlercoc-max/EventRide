// lib/data/interessenten_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/interessenten_daten.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/interfaces/i_interessenten_repository.dart';

class InteressentenService extends ChangeNotifier {
  final IInteressentenRepository _repository;

  /// eventId → Interessenten-Liste (aus aktiven Streams)
  final Map<String, List<InteressentenDaten>> _cache = {};

  /// Aktive Stream-Subscriptions pro eventId
  final Map<String, StreamSubscription<List<InteressentenDaten>>> _subs = {};

  /// eventIds für die gerade ein Toggle läuft – verhindert Doppel-Taps.
  final Set<String> _pendingToggles = {};

  StreamSubscription<AppUser?>? _authSub;

  InteressentenService(this._repository);

  /// Auth-Listener aufsetzen: bei Logout alle Streams + Cache leeren.
  /// Analog zu AnfrageService.init().
  void init(IAuthRepository auth) {
    _authSub?.cancel();
    _authSub = auth.authStateChanges.listen((user) {
      if (user == null) {
        for (final sub in _subs.values) {
          sub.cancel();
        }
        _subs.clear();
        _cache.clear();
        notifyListeners();
      }
    });
  }

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
  /// Aktualisiert den Cache sofort (optimistisch) und rollt bei Fehler zurück.
  Future<bool> toggle({
    required String eventId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? bezirk,
  }) async {
    if (_pendingToggles.contains(eventId)) return isInteressiert(eventId, userId);
    _pendingToggles.add(eventId);

    try {
      final id = InteressentenDaten.buildId(eventId, userId);
      final snapshot = List<InteressentenDaten>.from(_cache[eventId] ?? []);
      final existsInCache = snapshot.any((i) => i.id == id);

      if (existsInCache) {
        _cache[eventId] = snapshot.where((i) => i.id != id).toList();
        notifyListeners();
        try {
          await _repository.remove(id).timeout(const Duration(seconds: 8));
        } catch (e) {
          _cache[eventId] = snapshot;
          notifyListeners();
          rethrow;
        }
        return false;
      } else {
        final entry = InteressentenDaten(
          id: id,
          eventId: eventId,
          userId: userId,
          userName: userName,
          userPhotoUrl: userPhotoUrl,
          timestamp: DateTime.now(),
          bezirk: bezirk,
        );
        _cache[eventId] = [...snapshot, entry];
        notifyListeners();
        try {
          await _repository.add(entry).timeout(const Duration(seconds: 8));
        } catch (e) {
          _cache[eventId] = snapshot;
          notifyListeners();
          rethrow;
        }
        return true;
      }
    } finally {
      _pendingToggles.remove(eventId);
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
        _subs.remove(eventId);
        notifyListeners(); // Widget neu bauen → _ensureWatching startet Stream neu
      },
      onDone: () {
        // Stream vom Repository geschlossen (z.B. nach PERMISSION_DENIED).
        // notifyListeners() triggert Widget-Rebuild → _ensureWatching startet neu.
        _subs.remove(eventId);
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    for (final sub in _subs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
