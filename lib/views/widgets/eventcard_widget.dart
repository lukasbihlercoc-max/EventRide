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
      return "assets/image/kirchtag6.jpg";
    case "e2":
      return "assets/image/feuerwehr.png";
    case "e3":
      return "assets/image/disco.jpg";
    case "e4":
      return "assets/image/Ball.jpg";
    case "e5":
      return "assets/image/krampus.jpg";
    case "e6":
      return "assets/image/festival4.jpg";
    case "e7":
      return "assets/image/beach.jpg";
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



// ── Angepinnt: dezente Kennzeichnung mit der App-eigenen Akzentfarbe ───────
// Gleiche Farbe wie aktive Filter-Chips etc. (siehe home_page.dart _kAccent)
// statt einer eigenen Gold-Palette — fühlt sich dadurch wie Teil der App an.
const _kPinAccent = Color(0xFFF5A04A);

/// No-op — Pin-Kennzeichnung läuft jetzt über [_pinnedAccentStripe] und das
/// kleine Pin-Icon direkt im Titel, nicht mehr über einen Rahmen ums Ganze.
Widget _pinnedFrame({required bool pinned, required Widget child}) => child;

/// Schmaler Akzentstreifen am linken Kartenrand für gepinnte Events —
/// gleiches Muster wie der linke Akzentstreifen in chat_page.dart /
/// fahrten_page.dart, nur eben mit der Pin-Akzentfarbe. Muss NACH dem
/// dunklen Overlay im Stack stehen, sonst wird er davon abgedunkelt.
Widget _pinnedAccentStripe({required bool pinned}) {
  if (!pinned) return const SizedBox.shrink();
  return const Positioned(
    left: 0,
    top: 0,
    bottom: 0,
    width: 4,
    child: ColoredBox(color: _kPinAccent),
  );
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
        title: Row(
          children: [
            if (event.pinned) ...[
              const Icon(
                Icons.push_pin,
                size: 16,
                color: _kPinAccent,
                shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
              ),
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
                if (event.adminOnly && isAdmin) ...[
                  const SizedBox(width: 6),
                  const _AdminOnlyBadge(),
                ],
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

    // 3) Akzentstreifen für gepinnte Events (muss nach dem Overlay stehen)
    _pinnedAccentStripe(pinned: event.pinned),

    // 4) ⭐ FAVORITEN-STERN – JETZT GANZ ZUM SCHLUSS
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
            // Schatten liegt außerhalb des ClipRRect, sonst würde er
            // mitgeclippt und wäre unsichtbar.
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  // Kräftigere, dunklere neutrale Fläche (kein Blur/Verlauf)
                  // — füllt außerdem die Ecken-Lücke, wo der eigenständig
                  // gerundete Header unten "wegschneidet".
                  color: Colors.black.withValues(alpha: 0.32),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildHeader(
                            context, backgroundImage, sortedChildren, expanded,
                            interactive: !forceExpanded),
                      ),
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
              title: Row(
                children: [
                  if (container.pinned) ...[
                    const Icon(
                      Icons.push_pin,
                      size: 16,
                      color: _kPinAccent,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                    ),
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
                ],
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
                        if (container.adminOnly && isAdmin) ...[
                          const SizedBox(width: 6),
                          const _AdminOnlyBadge(),
                        ],
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
                            container.standort,
                            style: const TextStyle(
                              color: Color.fromARGB(232, 255, 255, 255),
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
          _pinnedAccentStripe(pinned: container.pinned),
        ],
      ),
    );
  }

  /// Tage-Liste unter dem Header. Kein BackdropFilter mehr — echter Blur
  /// über einer scrollenden Liste hat beim Overscroll-Bounce (Feder-Physik
  /// oben) immer wieder zu kurzem Farbflackern geführt, weil neu sampled
  /// wird, was gerade dahinterliegt. Feste, leicht transparente Fläche
  /// (wie an anderen Stellen im Projekt, z.B. `_kGlassAlpha` in
  /// events_page.dart) sieht optisch fast identisch aus und ist stabil.
  /// Rundung der unteren Ecken übernimmt der äußere ClipRRect in [build].
  Widget _buildDayList(
    BuildContext context,
    List<Event> displayChildren,
    Map<String, int> dayNumberByChildId,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(displayChildren.length, (i) {
          final child = displayChildren[i];
          return Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: _EventContainerDayRow(
                event: child,
                dayNumber: dayNumberByChildId[child.stabileId] ?? (i + 1),
              ),
            ),
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

  const _EventContainerDayRow({
    required this.event,
    required this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    final count = event.interessentenCount;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
