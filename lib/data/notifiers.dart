// notifiers.dart
//ValueNotifier: hold the data
//ValueListenableBuilder: listen to the date (dont need the setState)

import 'package:flutter/material.dart';
import "package:my_app/data/event_daten.dart";
import 'package:shared_preferences/shared_preferences.dart';

ValueNotifier<int> selectedPageNotifier = ValueNotifier(0);
ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(true);
ValueNotifier<List<Event>> eventListNotifier = ValueNotifier([]);
final searchTextNotifier = ValueNotifier<String>("");

// 🔹 Radius
final selectedRadiusNotifier = ValueNotifier<int?>(null);

// 🔹 Favoriten: Set von Event-IDs
final favouriteEventsNotifier = ValueNotifier<Set<String>>(<String>{});

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
