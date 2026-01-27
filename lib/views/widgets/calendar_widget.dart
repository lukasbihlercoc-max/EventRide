// calendar_widget.dart
import 'package:flutter/material.dart';

class CalendarOverlay extends StatelessWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarOverlay( {
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(209, 34, 31, 30),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blue, blurRadius: 12)],
      ),
      child: CalendarDatePicker(
        initialDate: initialDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        onDateChanged: onDateSelected,
      ),
    );
  }
}

void showCalendarOverlay(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return CalendarOverlay(
        initialDate: DateTime.now(),
        onDateSelected: (date) {
          // Hier kannst du z. B. Events filtern oder das Datum speichern
          Navigator.pop(context); // Schließt das Overlay
        },
      );
    },
  );
}
