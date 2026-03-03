// lib/data/seen_anfragen_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Speichert, welche Anfragen der jeweilige Nutzer schon gesehen hat.
/// - Owner (Fahrer): "gesehen" = offen-Anfragen, die der Fahrer schon angeschaut hat
/// - Requester (Mitfahrer): "gesehen" = akzeptiert/abgelehnt-Anfragen, die der
///   Mitfahrer schon angeschaut hat
class SeenAnfragenService with ChangeNotifier {
  static const _ownerKey = 'seen_anfragen_owner';
  static const _requesterKey = 'seen_anfragen_requester';

  // userId → Set von gesehenen Anfrage-IDs
  Map<String, Set<String>> _seenOwner = {};
  Map<String, Set<String>> _seenRequester = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _seenOwner = _decode(prefs.getString(_ownerKey));
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

  /// Gibt zurück, ob es für den Owner ungesehene Anfragen-IDs gibt.
  bool hasUnseenOwner(String userId, Iterable<String> anfragenIds) {
    final seen = _seenOwner[userId] ?? {};
    return anfragenIds.any((id) => !seen.contains(id));
  }

  /// Gibt zurück, ob es für den Requester ungesehene Statusänderungen gibt.
  bool hasUnseenRequester(String userId, Iterable<String> anfragenIds) {
    final seen = _seenRequester[userId] ?? {};
    return anfragenIds.any((id) => !seen.contains(id));
  }

  Future<void> markOwnerAsSeen(String userId, List<String> ids) async {
    if (ids.isEmpty) return;
    final set = _seenOwner.putIfAbsent(userId, () => {});
    final before = set.length;
    set.addAll(ids);
    if (set.length != before) {
      notifyListeners();
      await _persist();
    }
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
      _ownerKey,
      jsonEncode(_seenOwner.map((k, v) => MapEntry(k, v.toList()))),
    );
    await prefs.setString(
      _requesterKey,
      jsonEncode(_seenRequester.map((k, v) => MapEntry(k, v.toList()))),
    );
  }
}
