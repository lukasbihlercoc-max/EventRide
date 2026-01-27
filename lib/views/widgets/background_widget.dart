// background_widget.dart
import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;

  const AppBackground({super.key, required this.child, this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Wir verwenden hier voll deckende Farben (Alpha 255), 
        // um das Durchscheinen der vorherigen Seite während der Navigation zu verhindern.
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 237, 209, 175), // Opak gemacht (vorher 128)
            Color.fromARGB(255, 82, 161, 239),  // Opak gemacht (vorher 201)
            Color.fromARGB(255, 64, 108, 251),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}



/*Farb versuche:
-) farbverlauf
gradient: gradient ??
            const LinearGradient(
              colors: [Color.fromARGB(109, 0, 208, 255), Color.fromARGB(80, 213, 58, 112)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),

Color.fromARGB(197, 213, 58, 112), Color.fromARGB(205, 0, 208, 255)

gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(0, 208, 255, 0.3),
            Color.fromRGBO(58, 169, 213, 0.4),
            Color.fromRGBO(50, 0, 100, 0.2),
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,


-) farbe kommt von unten:
gradient: RadialGradient(
          colors: [Colors.blueAccent.withOpacity(0.5), Colors.transparent],
          radius: 2.5,
          center: Alignment.bottomCenter,
        ),

gradient: RadialGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.5),
            const Color.fromARGB(255, 64, 108, 251).withOpacity(0.1),
            Colors.transparent,
          ],
          radius: 2.5,
          center: Alignment.bottomCenter,
        ),
      
//!Nicht schlecht
[
      Color.fromARGB(128, 255, 230, 200),
      Color.fromARGB(202, 74, 144, 214),
      Color.fromARGB(255, 64, 108, 251),
    ],

*/
