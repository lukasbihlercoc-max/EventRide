// lib/data/seen_anfragen_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Speichert, welche Anfragen-Ereignisse Requester bzw. Fahrer schon gesehen haben.
/// Requester-Seite: Einladungen und Statusänderungen (akzeptiert/abgelehnt/fahrtGeloescht).
/// Fahrer-Seite: vom Fahrer verschickte Einladungen, die mittlerweile akzeptiert wurden.
class SeenAnfragenService with ChangeNotifier {
  static const _requesterKey = 'seen_anfragen_requester';
  static const _fahrerKey = 'seen_anfragen_fahrer';

  // userId → Set von gesehenen Anfrage-IDs
  Map<String, Set<String>> _seenRequester = {};

  // userId → Set von Anfrage-IDs, deren Annahme der Fahrer schon gesehen hat
  Map<String, Set<String>> _seenFahrer = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _seenRequester = _decode(prefs.getString(_requesterKey));
    _seenFahrer = _decode(prefs.getString(_fahrerKey));
  }

  static Map<String, Set<String>> _decode(String? json) {
    if (json == null) return {};
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, Set<String>.from(v as List)));
    } catch (_) {
      return {};
    }
  }

  /// Gibt zurück, ob es für den Requester ungesehene Statusänderungen gibt.
  bool hasUnseenRequester(String userId, Iterable<String> anfragenIds) {
    final seen = _seenRequester[userId] ?? {};
    return anfragenIds.any((id) => !seen.contains(id));
  }

  Future<void> markRequesterAsSeen(String userId, List<String> ids) async {
    if (ids.isEmpty) return;
    final set = _seenRequester.putIfAbsent(userId, () => {});
    final before = set.length;
    set.addAll(ids);
    if (set.length != before) {
      notifyListeners();
      await _persist(_requesterKey, _seenRequester);
    }
  }

  /// Gibt zurück, wie viele der übergebenen (vom Fahrer selbst eingeladenen
  /// und mittlerweile akzeptierten) Anfragen der Fahrer noch nicht gesehen hat.
  int unseenFahrerCount(String userId, Iterable<String> anfragenIds) {
    final seen = _seenFahrer[userId] ?? {};
    return anfragenIds.where((id) => !seen.contains(id)).length;
  }

  Future<void> markFahrerAsSeen(String userId, List<String> ids) async {
    if (ids.isEmpty) return;
    final set = _seenFahrer.putIfAbsent(userId, () => {});
    final before = set.length;
    set.addAll(ids);
    if (set.length != before) {
      notifyListeners();
      await _persist(_fahrerKey, _seenFahrer);
    }
  }

  Future<void> _persist(String key, Map<String, Set<String>> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(map.map((k, v) => MapEntry(k, v.toList()))),
    );
  }
}
