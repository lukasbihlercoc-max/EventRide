// eventcard_widget.dart
import 'dart:ui';

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



// ── Angepinnt: dezenter "Premium"-Look (goldener Rahmen + Badge) ───────────
const _kGoldColor = Color(0xFFD4AF37);
const _kGoldColorLight = Color(0xFFF0D890);
const _kGoldTextColor = Color(0xFF3D2E00);

/// Legt bei gepinnten Events einen dezenten goldenen Rahmen samt leichtem
/// Glanz-Schatten um die Karte — signalisiert "bewusst hier platziert",
/// ohne aufdringlich zu wirken.
Widget _pinnedFrame({required bool pinned, required Widget child}) {
  if (!pinned) return child;
  return Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _kGoldColor.withValues(alpha: 0.65), width: 1.4),
      boxShadow: [
        BoxShadow(
          color: _kGoldColor.withValues(alpha: 0.22),
          blurRadius: 14,
          spreadRadius: 0.5,
        ),
      ],
    ),
    child: child,
  );
}

/// Kleines Goldbadge mit Pin-Icon + "Angepinnt"-Schriftzug, oben links auf
/// der Karte (spiegelbildlich zum Favoriten-Stern oben rechts).
class _PinnedBadge extends StatelessWidget {
  const _PinnedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGoldColorLight, _kGoldColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.push_pin, size: 12, color: _kGoldTextColor),
          SizedBox(width: 4),
          Text(
            'Angepinnt',
            style: TextStyle(
              color: _kGoldTextColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
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

    final hasDescription = event.beschreibung.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: _pinnedFrame(
        pinned: event.pinned,
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: event.pinned ? 16 : 12,
        ),
        title: Padding(
          padding: EdgeInsets.only(top: event.pinned ? 22 : 0),
          child: Row(
            children: [
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
            if (event.pinned && hasDescription) ...[
              const SizedBox(height: 8),
              Text(
                event.beschreibung.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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

    // 4) 📌 ANGEPINNT-BADGE – oben links
    if (event.pinned)
      const Positioned(
        left: 12,
        top: 12,
        child: _PinnedBadge(),
      ),
  ],
),
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

  /// Wenn gesetzt (aktiver Datums- oder Favoriten-Filter, der nur einen Teil
  /// der Tage betrifft), wird NUR diese Teilmenge angezeigt und die Karte
  /// zwangsweise aufgeklappt — unabhängig vom gespeicherten Auf-/Zuklapp-
  /// Zustand. null = normales Verhalten (alle Tage, normale Auf/Zu-Logik).
  final List<Event>? visibleChildren;

  const EventContainerCard({
    super.key,
    required this.container,
    required this.children,
    this.visibleChildren,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundImage =
        getBackgroundImage(container.typ) ?? "assets/image/default.jpg";
    final sortedChildren = [...children]
      ..sort((a, b) => a.datum.compareTo(b.datum));
    // "Tag N" bezieht sich immer auf die Position im vollständigen Zeitraum,
    // auch wenn wegen eines Filters nur ein Teil der Tage angezeigt wird.
    final dayNumberByChildId = <String, int>{
      for (var i = 0; i < sortedChildren.length; i++)
        sortedChildren[i].stabileId: i + 1,
    };
    final forceExpanded = visibleChildren != null;
    final displayChildren = forceExpanded
        ? ([...visibleChildren!]..sort((a, b) => a.datum.compareTo(b.datum)))
        : sortedChildren;
    final now = DateTime.now();
    final defaultExpanded =
        sortedChildren.any((c) => _isSameCalendarDay(c.datum, now));

    return ValueListenableBuilder<Map<String, bool>>(
      valueListenable: expandedEventContainersNotifier,
      builder: (context, expandedMap, _) {
        final expanded = forceExpanded
            ? true
            : (expandedMap[container.stabileId] ?? defaultExpanded);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _pinnedFrame(
            pinned: container.pinned,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _buildHeader(
                      context, backgroundImage, sortedChildren, expanded,
                      interactive: !forceExpanded),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: _buildDayList(
                        context, displayChildren, dayNumberByChildId),
                    crossFadeState: expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                    sizeCurve: Curves.easeInOut,
                  ),
                ],
              ),
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
    bool expanded, {
    required bool interactive,
  }) {
    final rangeLabel = _dateRangeLabel(sortedChildren);
    final isAdmin = context.read<IAuthRepository>().isAdmin;
    final hasDescription = container.beschreibung.trim().isNotEmpty;

    return GestureDetector(
      onTap: interactive ? () => _toggleExpanded(expanded) : null,
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: container.pinned ? 16 : 12,
              ),
              title: Padding(
                padding: EdgeInsets.only(top: container.pinned ? 22 : 0),
                child: Row(
                  children: [
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
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
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
                    if (container.pinned && hasDescription) ...[
                      const SizedBox(height: 8),
                      Text(
                        container.beschreibung.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
          if (container.pinned)
            const Positioned(
              left: 12,
              top: 12,
              child: _PinnedBadge(),
            ),
        ],
      ),
    );
  }

  /// Verschwommener Bereich (gleiche Breite wie die Header-Karte), in dem
  /// jeder Tag als eigene, etwas schmälere, abgerundete Mini-Karte liegt —
  /// dezent voneinander getrennt statt flächig aneinandergereiht.
  Widget _buildDayList(
    BuildContext context,
    List<Event> displayChildren,
    Map<String, int> dayNumberByChildId,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          color: Colors.black.withValues(alpha: 0.38),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            children: List.generate(displayChildren.length, (i) {
              final child = displayChildren[i];
              return Padding(
                padding: EdgeInsets.only(
                    top: i == 0 ? 0 : 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.07),
                    child: _EventContainerDayRow(
                      event: child,
                      dayNumber: dayNumberByChildId[child.stabileId] ?? (i + 1),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
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

  const _EventContainerDayRow({
    required this.event,
    required this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    final count = event.interessentenCount;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          AppRoute(builder: (_) => DetailPage(event: event)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  Row(
                    children: [
                      Text(
                        'Tag $dayNumber',
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.people, size: 12, color: Colors.white54),
                        const SizedBox(width: 3),
                        Text(
                          '$count',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<Set<String>>(
              valueListenable: favouriteEventsNotifier,
              builder: (context, favourites, _) {
                final isFav = favourites.contains(event.stabileId);
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final newSet = Set<String>.from(favourites);
                    if (isFav) {
                      newSet.remove(event.stabileId);
                    } else {
                      newSet.add(event.stabileId);
                    }
                    favouriteEventsNotifier.value = newSet;
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav ? Colors.amber : Colors.white70,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
