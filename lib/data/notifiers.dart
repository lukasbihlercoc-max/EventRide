// notifiers.dart
//ValueNotifier: hold the data
//ValueListenableBuilder: listen to the date (dont need the setState)

import 'dart:convert';

import 'package:flutter/material.dart';
import "package:my_app/data/event_daten.dart";
import 'package:shared_preferences/shared_preferences.dart';

ValueNotifier<int> selectedPageNotifier = ValueNotifier(0);
ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(true);
ValueNotifier<List<Event>> eventListNotifier = ValueNotifier([]);
final searchTextNotifier = ValueNotifier<String>("");

// 🔹 Radius
final selectedRadiusNotifier = ValueNotifier<int?>(null);

// 🔹 Datum-Filter: null = Alle, 'heute', 'wochenende', 'datum'
final selectedDatumModeNotifier = ValueNotifier<String?>(null);
final selectedDatumNotifier = ValueNotifier<DateTime?>(null);

// 🔹 Eventtyp-Filter: null = Alle, 'e1'..'e5'
final selectedTypNotifier = ValueNotifier<String?>(null);

// 🔹 Favoriten: Set von Event-IDs
final favouriteEventsNotifier = ValueNotifier<Set<String>>(<String>{});

/// ID der aktuell geöffneten Chat-Konversation.
/// null = kein Chat aktiv geöffnet
final activeChatConversationId = ValueNotifier<String?>(null);

/// Explizite Auf-/Zuklapp-Wahl des Nutzers für mehrtägige Event-Container.
/// Key = Container-id, value = true (explizit geöffnet) / false (explizit
/// geschlossen). Fehlt ein Eintrag, wird der Container automatisch
/// aufgeklappt angezeigt, wenn heute einer seiner Tage ist.
final expandedEventContainersNotifier = ValueNotifier<Map<String, bool>>(<String, bool>{});

const _favouritesKey = 'event_favourites';
bool _favouritesListenerRegistered = false;

Future<void> initFavouriteEvents() async {
  final prefs = await SharedPreferences.getInstance();
  final storedList = prefs.getStringList(_favouritesKey) ?? [];

  favouriteEventsNotifier.value = storedList.toSet();

  if (_favouritesListenerRegistered) return;
  _favouritesListenerRegistered = true;

  favouriteEventsNotifier.addListener(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favouritesKey,
      favouriteEventsNotifier.value.toList(),
    );
  });
}

const _expandedEventContainersKey = 'expanded_event_containers';
bool _expandedEventContainersListenerRegistered = false;

Future<void> initExpandedEventContainers() async {
  final prefs = await SharedPreferences.getInstance();
  final storedJson = prefs.getString(_expandedEventContainersKey);

  if (storedJson != null) {
    try {
      final decoded = jsonDecode(storedJson) as Map<String, dynamic>;
      expandedEventContainersNotifier.value =
          decoded.map((key, value) => MapEntry(key, value == true));
    } catch (_) {
      // korrupte/alte Daten ignorieren, mit leerer Map weitermachen
    }
  }

  if (_expandedEventContainersListenerRegistered) return;
  _expandedEventContainersListenerRegistered = true;

  expandedEventContainersNotifier.addListener(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _expandedEventContainersKey,
      jsonEncode(expandedEventContainersNotifier.value),
    );
  });
}
