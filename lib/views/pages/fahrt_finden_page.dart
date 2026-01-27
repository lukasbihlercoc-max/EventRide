// fahrt_finden_page.dart
import 'package:flutter/material.dart';
import 'package:my_app/data/event_daten.dart';
import 'dart:ui';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/fahrtencard_widget.dart';
// 🆕 PROVIDER IMPORT
import 'package:provider/provider.dart';
import 'package:my_app/data/fahrt_service.dart';

class FahrtFindenPage extends StatelessWidget {
  final Event event;

  const FahrtFindenPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppBackground(child: Container()),
        Container(color: Colors.black.withOpacity(0.4)),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(color: Colors.transparent),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text("Fahrten zu: ${event.name}"),
            leading: BackButton(onPressed: () => Navigator.pop(context)),
          ),
          // 🆕 CONSUMER FÜR FAHRTSERVICE VERWENDEN
          body: Consumer<FahrtService>(
            builder: (context, fahrtService, child) {
              // 🆕 FAHRTEN AUS DEM SERVICE HOLEN
              final fahrtenFuerEvent = fahrtService.alleFahrten
                  .where(
                    (fahrt) =>
                        fahrt.eventId == event.stabileId &&
                        fahrt.freiePlaetze > 0,
                  ) // 🔥 nur Fahrten mit freien Plätzen
                  .toList();

              // Debug-Ausgabe
              print("🔍 DEBUG: Event ID: ${event.stabileId}");
              print(
                "🔍 DEBUG: Gefundene Fahrten für Event: ${fahrtenFuerEvent.length}",
              );

              return fahrtenFuerEvent.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_filled_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Noch keine Mitfahrgelegenheiten\nfür dieses Event",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: fahrtenFuerEvent.length,
                      itemBuilder: (context, index) {
                        final fahrt = fahrtenFuerEvent[index];
                        return FahrtenCard(
                          fahrt: fahrt,
                          isEditable:
                              false, // Zeigt "Mitfahren" Button (oder weglassen, da false default ist)
                        );
                      },
                    );
            },
          ),
        ),
      ],
    );
  }
}
