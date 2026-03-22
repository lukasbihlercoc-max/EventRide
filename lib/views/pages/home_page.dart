// home_page.dart
import 'package:flutter/material.dart';
import 'package:my_app/data/notifiers.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/sizehelper_widget.dart';
import 'package:my_app/views/widgets/suchleiste_widget.dart';
import 'package:my_app/views/widgets/eventcard_widget.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:provider/provider.dart';

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
    _loadHomeTown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheImages());
  }

  void _precacheImages() {
    const images = [
      'assets/image/kirchtag2.jpg',
      'assets/image/feuerwehr.png',
      'assets/image/disco.png',
      'assets/image/Ball.png',
      'assets/image/krampus.jpg',
      'assets/image/leer.jpg',
    ];
    for (final path in images) {
      precacheImage(AssetImage(path), context);
    }
  }

  Future<void> _loadHomeTown() async {
    final town = await context.read<IAuthRepository>().getHomeTown();
    if (!mounted) return;
    setState(() {
      _homeTown = town;
    });
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
            selectedColor: Colors.blueAccent.withValues(alpha: 0.8),
            backgroundColor: Colors.black.withValues(alpha: 0.3),
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
                      ? Colors.blueAccent.withValues(alpha: 0.8)
                      : Colors.black,
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
            controller.clear();
            searchTextNotifier.value = '';
          },
          child: ListenableBuilder(
            listenable: Listenable.merge([
              searchTextNotifier,
              eventListNotifier,
              selectedRadiusNotifier,
            ]),
            builder: (context, _) {
              final query = searchTextNotifier.value.toLowerCase();
              final events = eventListNotifier.value;
              final selectedRadius = selectedRadiusNotifier.value;

              // Alle Filter in einem einzigen Durchlauf
              final favourites = _showFavourites ? favouriteEventsNotifier.value : null;
              final townLower = (selectedRadius != null && _homeTown != null && _homeTown!.trim().isNotEmpty)
                  ? _homeTown!.toLowerCase().trim()
                  : null;

              final filteredEvents = events.where((event) {
                if (query.isNotEmpty &&
                    !event.name.toLowerCase().contains(query) &&
                    !event.standort.toLowerCase().contains(query) &&
                    !event.typ.toLowerCase().contains(query)) {
                  return false;
                }
                if (favourites != null && !favourites.contains(event.stabileId)) {
                  return false;
                }
                if (townLower != null && event.standort.toLowerCase().trim() != townLower) {
                  return false;
                }
                return true;
              }).toList();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: SizeHelper.h(context, 0.015)),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SearchBarDelegate(controller: controller),
                  ),
                  SliverToBoxAdapter(child: _buildFilterRow(context)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => RepaintBoundary(
                        child: EventCard(event: filteredEvents[index]),
                      ),
                      childCount: filteredEvents.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: SizeHelper.h(context, 0.13)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
