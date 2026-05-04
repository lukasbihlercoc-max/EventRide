// lib/data/seen_anfragen_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Speichert, welche Anfragen der Mitfahrer schon gesehen hat.
/// "gesehen" = Einladungen und Statusänderungen (akzeptiert/abgelehnt/fahrtGeloescht),
/// die der Mitfahrer schon angeschaut hat.
class SeenAnfragenService with ChangeNotifier {
  static const _requesterKey = 'seen_anfragen_requester';

  // userId → Set von gesehenen Anfrage-IDs
  Map<String, Set<String>> _seenRequester = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _seenRequester = _decode(prefs.getString(_requesterKey));
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
      await _persist();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _requesterKey,
      jsonEncode(_seenRequester.map((k, v) => MapEntry(k, v.toList()))),
    );
  }
}
