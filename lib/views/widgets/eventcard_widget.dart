// eventcard_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/interessenten_service.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/views/pages/detail_page.dart';
import 'package:my_app/data/notifiers.dart';


String? getBackgroundImage(String typ) {
  switch (typ) {
    case "e1":
      return "assets/image/kirchtag2.jpg";
    case "e2":
      return "assets/image/feuerwehr.png";
    case "e3":
      return "assets/image/disco.png";
    case "e4":
      return "assets/image/Ball.png";
    case "e5":
      return "assets/image/krampus.jpg";
    case "e6":
      return "assets/image/festival4.png";
    default:
      return "assets/image/default.jpg";
  }
}

//? Hintergrundhelligkeit anpassen
double hintergrundHelligkeit(String typ)  {
  switch (typ)  {
    case "e5":
      return 0.69;
    default:
      return 0.5;
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final backgroundImage =
        getBackgroundImage(event.typ) ?? "assets/image/default.jpg";
    final count =
        context.watch<InteressentenService>().countForEvent(event.id);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ), 
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
  clipBehavior: Clip.none, // optional
  children: [
    // 1) Hintergrundbild-Container
    Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
            alignment: Alignment(0.1, 0.2),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),

    // 2) Halbtransparenter Overlay für Inhalte + ListTile
    Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: hintergrundHelligkeit(event.typ)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        title: Hero(
          tag: event.stabileId,
          child: Material(
            color: Colors.transparent,
            child: Text(
              event.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.date_range,
                  color: Colors.amberAccent,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _eventDatumLabel(event.datum),
                    style: const TextStyle(
                      color: Color.fromARGB(232, 255, 255, 255),
                      fontSize: 16,
                      fontWeight: FontWeight.w200,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.redAccent,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.standort,
                    style: const TextStyle(
                      color: Color.fromARGB(232, 255, 255, 255),
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (count > 0) ...[
                  const Icon(Icons.people, size: 13, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white70,
        ),
        onTap: () {
          Navigator.push(
            context,
            AppRoute(builder: (_) => DetailPage(event: event)),
          );
        },
      ),
    ),

    // 3) ⭐ FAVORITEN-STERN – JETZT GANZ ZUM SCHLUSS
    Positioned(
      right: 12,
      top: 12,
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: favouriteEventsNotifier,
        builder: (context, favourites, _) {
          final isFav = favourites.contains(event.stabileId);

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              final newSet = Set<String>.from(favourites);
              if (isFav) {
                newSet.remove(event.stabileId);
              } else {
                newSet.add(event.stabileId);
              }
              favouriteEventsNotifier.value = newSet;
            },
            child: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? Colors.amber : Colors.white,
              size: 26,
            ),
          );
        },
      ),
    ),
  ],
),

      ),
    );
  }
}

String _eventDatumLabel(DateTime datum) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(datum.year, datum.month, datum.day);
  final diff = d.difference(today).inDays;
  final ds = DateFormat('dd.MM.', 'de_DE').format(datum);
  if (diff == 0) return 'Heute, $ds';
  if (diff == 1) return 'Morgen, $ds';
  if (diff == 2) return 'Übermorgen, $ds';
  if (diff > 2 && diff <= 6) return DateFormat('E, dd.MM.', 'de_DE').format(datum);
  return DateFormat('E dd.MM.yy', 'de_DE').format(datum);
}
