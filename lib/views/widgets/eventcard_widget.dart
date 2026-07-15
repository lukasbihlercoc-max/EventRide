// eventcard_widget.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/utils/async_guard.dart';
import 'package:my_app/views/pages/detail_page.dart';
import 'package:my_app/views/pages/events_page.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/data/notifiers.dart';


String? getBackgroundImage(String typ) {
  switch (typ) {
    case "e1":
      return "assets/image/kirchtag6.png";
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
    case "e7":
      return "assets/image/beach.png";
    default:
      return "assets/image/default.jpg";
  }
}

//? Hintergrundhelligkeit anpassen
double hintergrundHelligkeit(String typ)  {
  switch (typ)  {
    case "e5":
      return 0.69;
    case "e1":
      return 0.35;
    default:
      return 0.5;
  }
}



/// Kleiner Hinweis-Chip für Test-Events, die per Firestore-Rules nur für
/// Admin/Manager sichtbar sind (normale Nutzer bekommen das Dokument gar
/// nicht erst geliefert) — kein zusätzlicher isAdmin()-Check hier nötig.
class _AdminOnlyBadge extends StatelessWidget {
  const _AdminOnlyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE63946).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'TEST',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final backgroundImage =
        getBackgroundImage(event.typ) ?? "assets/image/default.jpg";
    final count = event.interessentenCount;
    final isAdmin = context.read<IAuthRepository>().isAdmin;

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
            alignment: Alignment(0.1, 0.05),
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
        title: Row(
          children: [
            if (event.pinned) ...[
              const Icon(Icons.push_pin, size: 15, color: Color(0xFFF5A04A)),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Hero(
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
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (event.adminOnly && isAdmin) ...[
              const SizedBox(width: 6),
              const _AdminOnlyBadge(),
            ],
          ],
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

bool _isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Hauptkarte eines mehrtägigen Events (Container). Zeigt Name, Pin-Badge
/// und Datumsbereich; ein Tap klappt die Liste der Veranstaltungstage
/// (=eigenständige Events) auf/zu. Jeder Tag verhält sich wie ein normales
/// Event (eigene Detailseite über [DetailPage]).
class EventContainerCard extends StatelessWidget {
  final Event container;
  final List<Event> children;

  const EventContainerCard({
    super.key,
    required this.container,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundImage =
        getBackgroundImage(container.typ) ?? "assets/image/default.jpg";
    final sortedChildren = [...children]
      ..sort((a, b) => a.datum.compareTo(b.datum));
    final now = DateTime.now();
    final defaultExpanded =
        sortedChildren.any((c) => _isSameCalendarDay(c.datum, now));

    return ValueListenableBuilder<Map<String, bool>>(
      valueListenable: expandedEventContainersNotifier,
      builder: (context, expandedMap, _) {
        final expanded = expandedMap[container.stabileId] ?? defaultExpanded;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                _buildHeader(context, backgroundImage, sortedChildren, expanded),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: _buildDayList(context, sortedChildren),
                  crossFadeState: expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                  sizeCurve: Curves.easeInOut,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleExpanded(bool currentlyExpanded) {
    final updated =
        Map<String, bool>.from(expandedEventContainersNotifier.value);
    updated[container.stabileId] = !currentlyExpanded;
    expandedEventContainersNotifier.value = updated;
  }

  Future<void> _deleteContainer(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Event löschen?"),
        content: Text(
            '"${container.name}" und alle ${children.length} Tage werden unwiderruflich gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Löschen",
              style: TextStyle(color: Color(0xFFE63946)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await guarded(
        FirebaseFunctions.instance
            .httpsCallable('deleteEventContainer')
            .call({'containerId': container.id}),
      );
    } on AsyncGuardTimeoutException {
      if (context.mounted) {
        AppSnackbar.show(context,
            message: 'Verbindung langsam – wird im Hintergrund synchronisiert');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(context, message: 'Fehler beim Löschen: $e');
      }
    }
  }

  Widget _buildHeader(
    BuildContext context,
    String backgroundImage,
    List<Event> sortedChildren,
    bool expanded,
  ) {
    final rangeLabel = _dateRangeLabel(sortedChildren);
    final isAdmin = context.read<IAuthRepository>().isAdmin;

    return GestureDetector(
      onTap: () => _toggleExpanded(expanded),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(backgroundImage),
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.1, 0.05),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black
                  .withValues(alpha: hintergrundHelligkeit(container.typ)),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Row(
                children: [
                  if (container.pinned) ...[
                    const Icon(Icons.push_pin,
                        size: 15, color: Color(0xFFF5A04A)),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      container.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (container.adminOnly && isAdmin) ...[
                    const SizedBox(width: 6),
                    const _AdminOnlyBadge(),
                  ],
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.date_range,
                        color: Colors.amberAccent, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rangeLabel,
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
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAdmin) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.push(
                        context,
                        AppRoute(builder: (_) => EventsPage(event: container)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit_outlined,
                            size: 18, color: Colors.white70),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _deleteContainer(context),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFFE63946)),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayList(BuildContext context, List<Event> sortedChildren) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Column(
        children: List.generate(sortedChildren.length, (i) {
          return _EventContainerDayRow(
            event: sortedChildren[i],
            dayNumber: i + 1,
            isFirst: i == 0,
          );
        }),
      ),
    );
  }

  String _dateRangeLabel(List<Event> sortedChildren) {
    if (sortedChildren.isEmpty) {
      return DateFormat('dd.MM.yyyy', 'de_DE').format(container.datum.toLocal());
    }
    final first = sortedChildren.first.datum.toLocal();
    final last = sortedChildren.last.datum.toLocal();
    final df = DateFormat('dd.MM.', 'de_DE');
    if (_isSameCalendarDay(first, last)) return df.format(first);
    return '${df.format(first)}–${df.format(last)}';
  }
}

/// Kompakte Zeile für einen einzelnen Veranstaltungstag innerhalb einer
/// aufgeklappten [EventContainerCard]. Datum ist die Hauptinformation,
/// "Tag N" nur eine kleine Sekundärinfo darunter.
class _EventContainerDayRow extends StatelessWidget {
  final Event event;
  final int dayNumber;
  final bool isFirst;

  const _EventContainerDayRow({
    required this.event,
    required this.dayNumber,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          AppRoute(builder: (_) => DetailPage(event: event)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _eventDatumLabel(event.datum),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tag $dayNumber',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
