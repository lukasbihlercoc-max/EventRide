// fahrt_finden_page.dart
import 'package:flutter/material.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/fahrt_service.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/utils/geo_utils.dart';
import 'package:my_app/views/auth/auth_guard.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/fahrtencard_widget.dart';
import 'package:my_app/views/widgets/fading_backdrop_filter.dart';
import 'package:provider/provider.dart';

class FahrtFindenPage extends StatelessWidget {
  final Event event;

  const FahrtFindenPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppBackground(child: Container()),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.5),
                const Color(0xFF0F172A).withValues(alpha: 0.72),
              ],
            ),
          ),
        ),
        const FadingBackdropFilter(sigma: 6),

        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Fahrten finden'),
            leading: BackButton(onPressed: () => Navigator.pop(context)),
          ),
          body: Consumer<FahrtService>(
            builder: (context, fahrtService, child) {
              final fahrtenFuerEvent = fahrtService.alleFahrten
                  .where((fahrt) =>
                      fahrt.eventId == event.stabileId &&
                      fahrt.freiePlaetze > 0)
                  .toList();

              final user = context.watch<IAuthRepository>().currentUser;

              if (user == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.4)),
                        const SizedBox(height: 20),
                        Text(
                          'Anmeldung erforderlich',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Melde dich an, um verfügbare\nMitfahrgelegenheiten zu sehen.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => requiresLogin(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Jetzt anmelden',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final homeLat = user.homeTownLat;
              final homeLng = user.homeTownLng;
              final hasHome = homeLat != null && homeLng != null;

              double? distFor(FahrtDaten f) {
                if (homeLat == null || homeLng == null || f.abfahrtsortLat == null || f.abfahrtsortLng == null) return null;
                return haversineKm(homeLat, homeLng, f.abfahrtsortLat!, f.abfahrtsortLng!);
              }

              int minutesOf(FahrtDaten f) => f.uhrzeitHour * 60 + f.uhrzeitMinute;

              // Kopie erstellen – Original-Liste aus Provider NICHT mutieren
              final sortedFahrten = [...fahrtenFuerEvent];
              if (hasHome) {
                sortedFahrten.sort((a, b) {
                  final distA = distFor(a) ?? double.infinity;
                  final distB = distFor(b) ?? double.infinity;
                  return distA != distB
                      ? distA.compareTo(distB)
                      : minutesOf(a).compareTo(minutesOf(b));
                });
              }

              if (sortedFahrten.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_filled_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine Mitfahrgelegenheiten\nfür dieses Event',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  // ── Event-Header ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fahrten zu',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () =>
                                showEventDetailsPopup(context, event),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    event.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 3),
                                  child: Icon(
                                    Icons.info_outline,
                                    color: Colors.white38,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${sortedFahrten.length} Fahrt${sortedFahrten.length == 1 ? '' : 'en'} verfügbar',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Karten ──
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 32, top: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final fahrt = sortedFahrten[index];
                          final dist = distFor(fahrt);
                          return RepaintBoundary(
                            key: ValueKey(fahrt.id),
                            child: FahrtenCard(
                              fahrt: fahrt,
                              homeTownDistanceKm: dist,
                            ),
                          );
                        },
                        childCount: sortedFahrten.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
