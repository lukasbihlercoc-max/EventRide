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

class FahrtenCardBackground extends StatelessWidget {
  final FahrtDaten fahrt;

  const FahrtenCardBackground({super.key, required this.fahrt});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        getBackgroundImage(fahrt.richtung),
        fit: BoxFit.cover,
        alignment: const Alignment(0.1, 0.1),
      ),
    );
  }
}
