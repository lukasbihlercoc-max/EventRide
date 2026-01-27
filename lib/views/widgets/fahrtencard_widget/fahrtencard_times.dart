import 'package:flutter/material.dart';
import 'package:my_app/data/fahrt_daten.dart';

class FahrtenCardTimes extends StatelessWidget {
  final FahrtDaten fahrt;

  const FahrtenCardTimes({super.key, required this.fahrt});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.access_time, color: Colors.amberAccent, size: 16),
        const SizedBox(width: 6),
        Text(
          fahrt.uhrzeit.format(context),
          style: const TextStyle(color: Colors.white),
        ),
        if (fahrt.richtung == Fahrtrichtung.hinUndZurueck &&
            fahrt.rueckuhrzeit != null) ...[
          const SizedBox(width: 20),
          const Icon(Icons.access_time,
              color: Colors.amberAccent, size: 16),
          const SizedBox(width: 6),
          Text(
            fahrt.rueckuhrzeit!.format(context),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ],
    );
  }
}
