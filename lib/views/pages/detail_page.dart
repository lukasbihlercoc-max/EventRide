// detail_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // Für ImageFilter.blur
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/fahrt_service.dart';
import 'package:my_app/data/interessenten_service.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/views/pages/events_page.dart';
import 'package:my_app/views/pages/fahrt_anbieten_page.dart';
import 'package:my_app/views/pages/fahrt_finden_page.dart';
import 'package:my_app/views/auth/auth_guard.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/background_widget.dart';

Future<void> _openEventNavigation(double lat, double lng) async {
  final mapsUri = Uri.parse('google.navigation:q=$lat,$lng');
  if (await canLaunchUrl(mapsUri)) {
    await launchUrl(mapsUri);
  } else {
    final fallback = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    await launchUrl(fallback, mode: LaunchMode.externalApplication);
  }
}

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
        Container(color: Colors.black.withValues(alpha: 0.4)),

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
            title: const Text("Infos"),
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
                        width * 0.064,
                        height * 0.016,
                        width * 0.064,
                        height * 0.013,
                      ),
                      padding: EdgeInsets.all(width * 0.064),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(width * 0.064),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: width * 0.032,
                            spreadRadius: width * 0.0053,
                            offset: Offset(0, height * 0.008),
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
                                  fontSize: width * 0.064,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.016),

                          Row(
                            children: [
                              Icon(Icons.date_range,
                                  color: Colors.amber, size: width * 0.06),
                              SizedBox(width: width * 0.016),
                              Expanded(
                                child: Text(
                                  DateFormat('EEEE, d. MMM yyyy', 'de_DE')
                                      .format(event.datum),
                                  style: TextStyle(
                                      fontSize: width * 0.043,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.013),

                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  color: Colors.redAccent, size: width * 0.06),
                              SizedBox(width: width * 0.016),
                              Expanded(
                                child: Text(
                                  event.adresse,
                                  style: TextStyle(
                                      fontSize: width * 0.043,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            color: Colors.white24,
                            thickness: 1,
                            height: height * 0.043,
                          ),

                          Expanded(
                            child: Scrollbar(
                              thumbVisibility: true,
                              thickness: width * 0.011,
                              radius: Radius.circular(width * 0.021),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.beschreibung,
                                      style: TextStyle(
                                        fontSize: width * 0.048,
                                        height: 1.4,
                                        color: Colors.white,
                                      ),
                                    ),
                                    // Mini-Karte + Navigationsbutton
                                    if (event.latitude != null &&
                                        event.longitude != null) ...[
                                      SizedBox(height: height * 0.027),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            width * 0.032),
                                        child: SizedBox(
                                          height: 160,
                                          child: GoogleMap(
                                            liteModeEnabled: true,
                                            initialCameraPosition:
                                                CameraPosition(
                                              target: LatLng(event.latitude!,
                                                  event.longitude!),
                                              zoom: 14,
                                            ),
                                            markers: {
                                              Marker(
                                                markerId:
                                                    const MarkerId('event'),
                                                position: LatLng(
                                                    event.latitude!,
                                                    event.longitude!),
                                                infoWindow: InfoWindow(
                                                    title: event.standort),
                                              ),
                                            },
                                            zoomControlsEnabled: false,
                                            scrollGesturesEnabled: false,
                                            zoomGesturesEnabled: false,
                                            myLocationButtonEnabled: false,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: height * 0.016),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _openEventNavigation(
                                            event.latitude!,
                                            event.longitude!,
                                          ),
                                          icon: const Icon(Icons.navigation),
                                          label: const Text(
                                              'Zum Event navigieren'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.greenAccent.shade700,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                vertical: height * 0.018),
                                          ),
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: height * 0.043),
                                    if (FirebaseAuth.instance.currentUser
                                            ?.uid ==
                                        'vA8UdBXsdCPD3ePJ88j4C3MQtjJ2')
                                      Center(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    EventsPage(event: event),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            "Bearbeiten",
                                            style: TextStyle(
                                                fontSize: width * 0.043),
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
                  horizontal: width * 0.064,
                  vertical: height * 0.016,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FahrtFindenPage(event: event),
                          ),
                        );
                      },
                      icon: Icon(Icons.search, size: width * 0.043),
                      label: Text("Fahrten finden",
                          style: TextStyle(fontSize: width * 0.04)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: height * 0.020,
                          horizontal: width * 0.05,
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.011),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (!await requiresLogin(context)) return;
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FahrtAnbietenPage(event: event),
                          ),
                        );
                      },
                      icon: Icon(Icons.directions_car_filled,
                          size: width * 0.043),
                      label: Text("Fahrt anbieten",
                          style: TextStyle(fontSize: width * 0.04)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: height * 0.020,
                          horizontal: width * 0.05,
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.011),
                    // ── "Ich will hin" Button ──
                    _IchWillHinButton(event: event, width: width, height: height),
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

// ---------------------------------------------------------------------------
// "Ich will hin" Button — eigenes Widget für saubere Trennung
// ---------------------------------------------------------------------------
class _IchWillHinButton extends StatelessWidget {
  const _IchWillHinButton({
    required this.event,
    required this.width,
    required this.height,
  });

  final Event event;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<IAuthRepository>().currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final interessentenService = context.watch<InteressentenService>();
    final fahrtService = context.read<FahrtService>();
    final anfrageService = context.read<AnfrageService>();

    // Prüfe ob User schon eine Fahrt für dieses Event hat
    final hatEigeneFahrt = fahrtService.alleFahrten
        .any((f) => f.eventId == event.id && f.ownerId == currentUser.userId);

    final hatAkzeptierteAnfrage = anfrageService.alleAnfragen.any((a) =>
        a.eventId == event.id &&
        a.requesterId == currentUser.userId &&
        a.status == AnfrageStatus.akzeptiert);

    final hatFahrt = hatEigeneFahrt || hatAkzeptierteAnfrage;

    final interessiertList = interessentenService.getForEvent(event.id);
    final count = interessiertList.length;
    final ichBinInteressiert =
        interessentenService.isInteressiert(event.id, currentUser.userId);

    if (hatFahrt) {
      return Opacity(
        opacity: 0.5,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_outline, color: Colors.white70),
          label: Text(
            'Du hast bereits eine Fahrt',
            style: TextStyle(fontSize: width * 0.035, color: Colors.white70),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white30),
            padding: EdgeInsets.symmetric(
              vertical: height * 0.015,
              horizontal: width * 0.04,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ichBinInteressiert
              ? ElevatedButton.icon(
                  onPressed: () => _toggle(context, currentUser.userId,
                      currentUser.name, interessentenService),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    'Ich will hin',
                    style: TextStyle(
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: height * 0.020,
                      horizontal: width * 0.05,
                    ),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () => _toggle(context, currentUser.userId,
                      currentUser.name, interessentenService),
                  icon: Icon(Icons.emoji_people,
                      color: Colors.amber.shade400, size: width * 0.043),
                  label: Text(
                    'Ich will hin',
                    style: TextStyle(
                        fontSize: width * 0.04,
                        color: Colors.amber.shade400),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.amber.shade400),
                    padding: EdgeInsets.symmetric(
                      vertical: height * 0.020,
                      horizontal: width * 0.05,
                    ),
                  ),
                ),
        ),
        if (count > 0) ...[
          SizedBox(width: width * 0.03),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: Colors.amber.shade300,
                  fontSize: width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                count == 1 ? 'will hin' : 'wollen hin',
                style: TextStyle(
                    color: Colors.white54, fontSize: width * 0.03),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _toggle(
    BuildContext context,
    String userId,
    String userName,
    InteressentenService service,
  ) async {
    // Hole HomeTown als Bezirk (optional)
    final authRepo = context.read<IAuthRepository>();
    final bezirk = await authRepo.getHomeTown();

    if (!context.mounted) return;

    final eingetragen = await service.toggle(
      eventId: event.id,
      userId: userId,
      userName: userName,
      bezirk: bezirk,
    );

    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      message: eingetragen
          ? 'Du wurdest als Interessent eingetragen!'
          : 'Interesse zurückgezogen.',
    );
  }
}
