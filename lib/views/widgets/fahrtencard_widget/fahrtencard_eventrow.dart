import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:hive/hive.dart';

class FahrtenCardEventRow extends StatelessWidget {
  final String eventId;
  final String fallbackName;

  const FahrtenCardEventRow({
    super.key,
    required this.eventId,
    required this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    final eventBox = Hive.box<Event>('events');
    final event = eventBox.values.firstWhere(
      (e) => e.id == eventId,
      orElse: () => Event(
        name: fallbackName,
        datum: DateTime(2000),
        standort: '',
        beschreibung: '',
        typ: '',
        adresse: '',
      ),
    );

    final dateText = event.datum.year == 2000
        ? ''
        : ' (${DateFormat('dd.MM.yy').format(event.datum)})';

    return Row(
      children: [
        const Icon(Icons.event, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            "${event.name}$dateText",
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
