import 'package:flutter/material.dart';
import 'package:my_app/data/fahrt_daten.dart';

class FahrtenCardRoute extends StatelessWidget {
  final FahrtDaten fahrt;

  const FahrtenCardRoute({super.key, required this.fahrt});

  @override
  Widget build(BuildContext context) {
    Icon arrow;
    switch (fahrt.richtung) {
      case Fahrtrichtung.hinfahrt:
        arrow = const Icon(Icons.arrow_forward_rounded, color: Colors.white);
        break;
      case Fahrtrichtung.rueckfahrt:
        arrow = const Icon(Icons.arrow_back_rounded, color: Colors.white);
        break;
      case Fahrtrichtung.hinUndZurueck:
        arrow = const Icon(Icons.swap_horiz_rounded, color: Colors.white);
        break;
    }

    return Row(
      children: [
        Text(
          fahrt.abfahrtsort,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        arrow,
        const SizedBox(width: 8),
        Text(
          fahrt.standort,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
