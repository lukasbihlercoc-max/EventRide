// calendar_widget.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/notifiers.dart';

// ---------------------------------------------------------------------------
// CalendarOverlay Widget
// ---------------------------------------------------------------------------

class CalendarOverlay extends StatefulWidget {
  final DateTime initialDate;

  const CalendarOverlay({super.key, required this.initialDate});

  @override
  State<CalendarOverlay> createState() => _CalendarOverlayState();
}

class _CalendarOverlayState extends State<CalendarOverlay> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth =
        DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  void _prevMonth() => setState(() {
        _displayedMonth =
            DateTime(_displayedMonth.year, _displayedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _displayedMonth =
            DateTime(_displayedMonth.year, _displayedMonth.month + 1);
      });

  Map<int, List<Event>> _favDaysInMonth(
      List<Event> events, Set<String> favourites) {
    final map = <int, List<Event>>{};
    for (final event in events) {
      if (!favourites.contains(event.stabileId)) continue;
      final local = event.datum.toLocal();
      if (local.year == _displayedMonth.year &&
          local.month == _displayedMonth.month) {
        map.putIfAbsent(local.day, () => []).add(event);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Event>>(
      valueListenable: eventListNotifier,
      builder: (context, events, _) {
        return ValueListenableBuilder<Set<String>>(
          valueListenable: favouriteEventsNotifier,
          builder: (context, favourites, _) {
            return _buildContent(
                context, _favDaysInMonth(events, favourites));
          },
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context, Map<int, List<Event>> favEvents) {
    final today = DateTime.now();
    final daysInMonth =
        DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final offset =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday - 1;
    final rows = ((offset + daysInMonth) / 7).ceil();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildWeekdayRow(),
              const SizedBox(height: 6),
              ...List.generate(
                rows,
                (row) => _buildWeekRow(
                    context, row, offset, daysInMonth, today, favEvents),
              ),
              if (favEvents.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildLegend(),
              ] else ...[
                const SizedBox(height: 12),
                const Text(
                  'Gespeicherte Events erscheinen hier im Kalender',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _headerButton(Icons.chevron_left, _prevMonth),
        Text(
          DateFormat('MMMM yyyy', 'de_DE').format(_displayedMonth),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        _headerButton(Icons.chevron_right, _nextMonth),
      ],
    );
  }

  Widget _headerButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildWeekdayRow() {
    const labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: labels
          .map((l) => SizedBox(
                width: 38,
                child: Center(
                  child: Text(
                    l,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildWeekRow(BuildContext context, int row, int offset,
      int daysInMonth, DateTime today, Map<int, List<Event>> favEvents) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (col) {
          final index = row * 7 + col;
          if (index < offset || index >= offset + daysInMonth) {
            return const SizedBox(width: 38, height: 46);
          }
          final day = index - offset + 1;
          final date =
              DateTime(_displayedMonth.year, _displayedMonth.month, day);
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          return _buildDayCell(context, day, isToday, favEvents[day] ?? []);
        }),
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, int day, bool isToday,
      List<Event> dayEvents) {
    final hasFav = dayEvents.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final tapped = DateTime(_displayedMonth.year, _displayedMonth.month, day);
        selectedDatumModeNotifier.value = 'datum';
        selectedDatumNotifier.value = tapped;
        selectedPageNotifier.value = 0;
        Navigator.pop(context);
      },
      child: SizedBox(
        width: 38,
        height: 46,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFFF5A623).withValues(alpha: 0.85)
                    : hasFav
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isToday || hasFav
                        ? FontWeight.bold
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: hasFav ? Colors.amber : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Gespeichertes Event',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// showCalendarOverlay
// ---------------------------------------------------------------------------

void showCalendarOverlay(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.fromLTRB(16, 72, 16, 0),
        child: CalendarOverlay(initialDate: DateTime.now()),
      );
    },
  );
}
