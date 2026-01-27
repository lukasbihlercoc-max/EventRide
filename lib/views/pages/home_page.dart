// home_page.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/notifiers.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/sizehelper_widget.dart';
import 'package:my_app/views/widgets/suchleiste_widget.dart';
import 'package:my_app/views/widgets/eventcard_widget.dart';
import 'package:my_app/data/user_service.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = TextEditingController();
  String? _homeTown; // 🔹 gespeicherter Wohnort
  bool _showFavourites = false; // 🔹 für Stern
  String _radiusLabel(int? value) {
  if (value == null) return "Alle";
  return "$value km";
}


  @override
  void initState() {
    super.initState();
    ladeEventsAusHive(); //!Events beim Start laden
    _loadHomeTown(); // 🔹 Wohnort laden
  }

  Future<void> _loadHomeTown() async {
    final town = await UserService().getHomeTown();
    if (!mounted) return;
    setState(() {
      _homeTown = town;
    });
  }

  Future<void> ladeEventsAusHive() async {
    final box = Hive.box<Event>("events");
    final alleEvents = box.values.toList();
    alleEvents.sort((a, b) => a.datum.compareTo(b.datum));
    eventListNotifier.value = alleEvents;
  }

  Future<void> reloadEvents() async {
    final box = Hive.box<Event>('events');
    final aktualisiert = box.values.toList();
    aktualisiert.sort((a, b) => a.datum.compareTo(b.datum));
    eventListNotifier.value = aktualisiert;
  }

  //! Filterzeile
  Widget _buildFilterRow(BuildContext context) {
  final currentRadius = selectedRadiusNotifier.value;
  final bool hasRadiusFilter = currentRadius != null; // 🔹 aktiv ja/nein

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // 🔹 Favoriten-Chip nur mit Stern
          ChoiceChip(
            label: Icon(
              Icons.star,
              size: 20,
              color: _showFavourites ? Colors.amber : Colors.white70,
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            selected: _showFavourites,
            onSelected: (selected) {
              setState(() {
                _showFavourites = selected;
              });
            },
            selectedColor: Colors.blueAccent.withOpacity(0.8),
            backgroundColor: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: _showFavourites ? Colors.blueAccent : Colors.white24,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 🔹 Radius-Auswahl als "Dropdown" direkt am Chip
          PopupMenuButton<int>(
            // 0 = "Alle", 10/20/50 = km
            onSelected: (value) {
              setState(() {
                selectedRadiusNotifier.value =
                    value == 0 ? null : value; // 0 -> Alle (null)
              });
            },
            color: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 8),
            itemBuilder: (ctx) {
              final options = [0, 10, 20, 50];

              return options.map((value) {
                final isSelected = (value == 0 && currentRadius == null) ||
                    (value != 0 && currentRadius == value);

                return PopupMenuItem<int>(
                  value: value,
                  child: Row(
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check,
                            color: Colors.blueAccent, size: 18),
                        const SizedBox(width: 8),
                      ] else
                        const SizedBox(width: 26),
                      Text(
                        value == 0 ? "Alle" : "$value km",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList();
            },

            // 🔹 Der Chip-Button selbst
            child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: hasRadiusFilter
                      ? Colors.blueAccent.withOpacity(0.8)
                      : Colors.black, // ← WICHTIG
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasRadiusFilter ? Colors.blueAccent : Colors.white24,
                  ),
                ),

              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ❌ Kein Häkchen mehr im Chip
                  Text(
                    _radiusLabel(currentRadius),
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () async {
            await reloadEvents(); // ✅ Jetzt wird sie wirklich aufgerufen
            controller.clear(); // ✅ Textfeld leeren
            searchTextNotifier.value = ''; // ✅ Filter zurücksetzen
          },
          child: ValueListenableBuilder<String>(
            valueListenable: searchTextNotifier,
            builder: (context, searchText, _) {
              return ValueListenableBuilder<List<Event>>(
                valueListenable: eventListNotifier,
                builder: (context, events, _) {
                  return ValueListenableBuilder<int?>(
                    valueListenable: selectedRadiusNotifier,
                    builder: (context, selectedRadius, _) {
                      final query = searchText.toLowerCase();


                      // 🔹 Textsuche
                      var filteredEvents = events.where((event) {
                        return event.name.toLowerCase().contains(query) ||
                            event.standort.toLowerCase().contains(query) ||
                            event.typ.toLowerCase().contains(query);
                      }).toList();


                      // 🔹 Nur Favoriten, falls aktiviert
                      if (_showFavourites) {
                        final favourites = favouriteEventsNotifier.value;
                        filteredEvents = filteredEvents
                            .where((event) => favourites.contains(event.stabileId))
                            .toList();
                      }

                      // 🔹 Radius-Filter (Platzhalter: gleicher Ort = "im Umkreis")
                      if (selectedRadius != null &&
                          _homeTown != null &&
                          _homeTown!.trim().isNotEmpty) {
                        final townLower = _homeTown!.toLowerCase().trim();
                        filteredEvents = filteredEvents.where((event) {
                          return event.standort.toLowerCase().trim() ==
                              townLower;
                        }).toList();
                      }

                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: SizeHelper.h(context, 0.015),
                            ), // *12
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: SearchBarDelegate(controller: controller),
                          ),

                          // 🔹 Filterzeile: Favoriten + Radius
                          SliverToBoxAdapter(child: _buildFilterRow(context)),


                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  EventCard(event: filteredEvents[index]),
                              childCount: filteredEvents.length,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: SizeHelper.h(context, 0.13),
                            ), // *100
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
