// detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // Für ImageFilter.blur
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/views/pages/events_page.dart';
import 'package:my_app/views/pages/fahrt_anbieten_page.dart';
import 'package:my_app/views/pages/fahrt_finden_page.dart';
import 'package:my_app/views/auth/auth_guard.dart';
import 'package:my_app/views/widgets/background_widget.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // 🔧 Hintergrundverlauf
        AppBackground(child: Container()),

        // 🔧 Dunkler Overlay gegen Durchscheinen
        Container(color: Colors.black.withOpacity(0.4)),

        // 🔧 Blur-Effekt für weichen Übergang
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(color: Colors.transparent),
        ),

        // 🔧 Eigentlicher Inhalt
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text("Infos"),
            leading: BackButton(onPressed: () => Navigator.pop(context)),
          ),
          body: Column(
            children: [
              Expanded(
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(
                        width * 0.064, // entspricht 24px auf 375px Breite
                        height * 0.016, // entspricht 12px auf 750px Höhe
                        width * 0.064,
                        height * 0.013, // entspricht 10px
                      ),
                      padding: EdgeInsets.all(width * 0.064), // 24/375 = 0.064
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(width * 0.064), // 24px
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: width * 0.032, // 12px
                            spreadRadius: width * 0.0053, // 2px
                            offset: Offset(0, height * 0.008), // 6px
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: event.stabileId,
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                event.name,
                                style: TextStyle(
                                  fontSize: width * 0.064, // 24px
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.016), // 12px

                          Row(
                            children: [
                              Icon(
                                Icons.date_range, 
                                color: Colors.amber, 
                                size: width * 0.06, // 16px
                              ),
                              SizedBox(width: width * 0.016), // 6px
                              Expanded(
                                child: Text(
                                  DateFormat('EEEE, d. MMM yyyy', 'de_DE').format(event.datum),
                                  style: TextStyle(
                                    fontSize: width * 0.043, // 16px
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.013), // 10px

                          Row(
                            children: [
                              Icon(
                                Icons.location_on, 
                                color: Colors.redAccent, 
                                size: width * 0.06, // 16px
                              ),
                              SizedBox(width: width * 0.016), // 6px
                              Expanded(
                                child: Text(
                                  event.adresse,
                                  style: TextStyle(
                                    fontSize: width * 0.043, // 16px
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            color: Colors.white24,
                            thickness: 1,
                            height: height * 0.043, // 32px
                          ),

                          Expanded(
                            child: Scrollbar(
                              thumbVisibility: true,
                              thickness: width * 0.011, // 4px
                              radius: Radius.circular(width * 0.021), // 8px
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.beschreibung,
                                      style: TextStyle(
                                        fontSize: width * 0.048, // 18px
                                        height: 1.4,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: height * 0.043), // 32px
                                    Center(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EventsPage(event: event),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          "Bearbeiten",
                                          style: TextStyle(
                                            fontSize: width * 0.043, // 16px
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.064, // 24px
                  vertical: height * 0.016, // 12px
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => FahrtFindenPage(event: event),
                          ),
                        );
                      },
                      icon: Icon(Icons.search, size: width * 0.043), // 16px
                      label: Text(
                        "Fahrten finden", 
                        style: TextStyle(fontSize: width * 0.04), // 16px
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: height * 0.020, // 16px
                          horizontal: width * 0.05, // 16px
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.011), // 8px Abstand zwischen Buttons
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (!await requiresLogin(context)) return;
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FahrtAnbietenPage(event: event),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.directions_car_filled,
                        size: width * 0.043, // 16px
                      ),
                      label: Text(
                        "Fahrt anbieten", 
                        style: TextStyle(fontSize: width * 0.04), // 16px
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: height * 0.020, // 16px
                          horizontal: width * 0.05, // 16px
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
