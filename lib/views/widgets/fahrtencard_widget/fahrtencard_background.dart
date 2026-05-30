import 'package:flutter/material.dart';
import 'package:my_app/data/fahrt_daten.dart';

String getBackgroundImage(Fahrtrichtung richtung) {
  switch (richtung) {
    case Fahrtrichtung.hinfahrt:
      return "assets/image/hinfahrt3.png";
    case Fahrtrichtung.rueckfahrt:
      return "assets/image/rueckfahrt3.png";
    case Fahrtrichtung.hinUndZurueck:
      return "assets/image/hinundrueck2.png";
  }
}

// y: -1.0 = ganz oben, 0.0 = Mitte, 1.0 = ganz unten
// Anpassen bis Sonne/Mond immer sichtbar ist, egal wie hoch die Card ist.
Alignment getBackgroundAlignment(Fahrtrichtung richtung) {
  switch (richtung) {
    case Fahrtrichtung.hinfahrt:
      return const Alignment(0.0, -0.7); // Sonne oben mittig
    case Fahrtrichtung.rueckfahrt:
      return const Alignment(0.0, -0.7); // Mond oben mittig
    case Fahrtrichtung.hinUndZurueck:
      return const Alignment(0.0, -0.5); // Sonne + Mond beide sichtbar
  }
}

class FahrtenCardBackground extends StatelessWidget {
  final FahrtDaten fahrt;

  const FahrtenCardBackground({super.key, required this.fahrt});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        getBackgroundImage(fahrt.richtung),
        fit: BoxFit.cover,
        alignment: getBackgroundAlignment(fahrt.richtung),
      ),
    );
  }
}
