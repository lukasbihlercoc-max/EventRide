import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:my_app/views/widgets/app_card.dart';

import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/fahrt_service.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/event_service.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/chat_service.dart';
import 'package:my_app/data/seen_anfragen_service.dart';
import 'package:my_app/views/pages/login_page.dart';
import 'package:my_app/views/pages/fahrt_anfragen_page.dart';
import 'package:my_app/views/pages/fahrt_anbieten_page.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';

import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/pages/chat_page.dart';
import 'package:my_app/views/pages/detail_page.dart';

// ---------------------------------------------------------------------------
// Hilfsfunktion: Event-Detail-Dialog
// ---------------------------------------------------------------------------
void _showEventInfoDialog(BuildContext context, Event event) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final size = MediaQuery.of(ctx).size;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              width: size.width * 0.85,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailPage(event: event),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.open_in_full,
                          color: Colors.white54,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (event.datum.year != 2000)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd.MM.yyyy').format(event.datum),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.adresse,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  if (event.beschreibung.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24, thickness: 1),
                    const SizedBox(height: 12),
                    Text(
                      event.beschreibung,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Schließen',
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Hilfsfunktion: Eventdatum für Sortierung (unbekannte Events ans Ende)
// ---------------------------------------------------------------------------

class MeineFahrtenPage extends StatelessWidget {
  const MeineFahrtenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: context.read<IAuthRepository>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppBackground(
            child: Scaffold(backgroundColor: Colors.transparent),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return AppBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      const Text(
                        'Nicht angemeldet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Melde dich an, um deine Fahrten zu verwalten.',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
                        icon: const Icon(Icons.login),
                        label: const Text('Anmelden'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return _LoggedInFahrtenView(key: ValueKey(user.userId), user: user);
      },
    );
  }
}

/// ------------------------------------------------------------
/// Eingeloggter Bereich mit TabController + Unseen-Logik
/// ------------------------------------------------------------
class _LoggedInFahrtenView extends StatefulWidget {
  final AppUser user;

  const _LoggedInFahrtenView({super.key, required this.user});

  @override
  State<_LoggedInFahrtenView> createState() => _LoggedInFahrtenViewState();
}

class _LoggedInFahrtenViewState extends State<_LoggedInFahrtenView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChange);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _markCurrentTabAsSeen());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) _markCurrentTabAsSeen();
  }

  void _markCurrentTabAsSeen() {
    if (!mounted) return;
    final anfrageService = context.read<AnfrageService>();
    final seenService = context.read<SeenAnfragenService>();
    final userId = widget.user.userId;

    if (_tabController.index == 0) {
      final ids = anfrageService
          .getAnfragenForFahrer(userId)
          .where((a) => a.status == AnfrageStatus.offen)
          .map((a) => a.id)
          .toList();
      seenService.markOwnerAsSeen(userId, ids);
    } else {
      final ids = anfrageService
          .getAnfragenByRequester(userId)
          .where((a) => a.status != AnfrageStatus.offen)
          .map((a) => a.id)
          .toList();
      seenService.markRequesterAsSeen(userId, ids);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.user.userId;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _FahrtenTabBar(userId: userId, tabController: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AngeboteneFahrtenTab(userId: userId),
                  _AngefragteFahrtenTab(userId: userId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eigener Widget für die TabBar — hört nur auf AnfrageService + SeenAnfragenService.
/// AppBackground, Scaffold und TabBarView werden dadurch nicht mehr neu gebaut.
class _FahrtenTabBar extends StatelessWidget {
  final String userId;
  final TabController tabController;

  const _FahrtenTabBar({required this.userId, required this.tabController});

  Widget _tabLabel(String text, bool showDot) {
    return Tab(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(text),
          ),
          if (showDot)
            Positioned(
              right: -2,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AnfrageService, SeenAnfragenService>(
      builder: (context, anfrageService, seenService, _) {
        final ownerIds = anfrageService
            .getAnfragenForFahrer(userId)
            .where((a) => a.status == AnfrageStatus.offen)
            .map((a) => a.id);

        final requesterIds = anfrageService
            .getAnfragenByRequester(userId)
            .where((a) => a.status != AnfrageStatus.offen)
            .map((a) => a.id);

        return TabBar(
          controller: tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            _tabLabel('Angeboten', seenService.hasUnseenOwner(userId, ownerIds)),
            _tabLabel('Angefragt', seenService.hasUnseenRequester(userId, requesterIds)),
          ],
        );
      },
    );
  }
}

/// ------------------------------------------------------------
/// TAB 1 – angebotene Fahrten (nach Datum sortiert, swipe-to-delete)
/// ------------------------------------------------------------
class _AngeboteneFahrtenTab extends StatefulWidget {
  final String userId;

  const _AngeboteneFahrtenTab({required this.userId});

  @override
  State<_AngeboteneFahrtenTab> createState() => _AngeboteneFahrtenTabState();
}

class _AngeboteneFahrtenTabState extends State<_AngeboteneFahrtenTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  /// Zeigt Bestätigungs-Dialog und gibt true zurück wenn löschen bestätigt.
  Future<bool?> _confirmDelete(FahrtDaten fahrt) async {
    if (!mounted) return false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.delete_forever,
                          color: Colors.redAccent, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fahrt löschen?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Wenn du diese Fahrt löscht, werden auch alle Mitfahr-Anfragen dafür abgebrochen.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Abbrechen',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Löschen',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteFahrt(FahrtDaten fahrt) async {
    final fahrtService = context.read<FahrtService>();
    final anfrageService = context.read<AnfrageService>();
    await anfrageService.cancelAnfragenForFahrt(fahrt.id);
    await fahrtService.delete(fahrt.id);
    if (mounted) {
      AppSnackbar.show(context, message: 'Fahrt wurde gelöscht');
    }
  }

  void _handleEdit(FahrtDaten fahrt) {
    final es = context.read<EventService>();
    final event = es.events.firstWhere(
      (e) => e.id == fahrt.eventId,
      orElse: () => Event(
        name: fahrt.eventName,
        datum: DateTime.now(),
        standort: fahrt.standort,
        beschreibung: '',
        typ: '',
        adresse: '',
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FahrtAnbietenPage(event: event, existingFahrt: fahrt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<FahrtService>(
      builder: (context, fahrtService, _) {
        final es = context.read<EventService>();
        final datumCache = {for (final e in es.events) e.id: e.datum};
        final meineFahrten = List<FahrtDaten>.from(
          fahrtService.getFahrtenByUser(widget.userId),
        )..sort((a, b) =>
            (datumCache[a.eventId] ?? DateTime(9999))
                .compareTo(datumCache[b.eventId] ?? DateTime(9999)));

        if (meineFahrten.isEmpty) {
          return const _EmptyState(
            icon: Icons.directions_car_filled_outlined,
            title: 'Noch keine Fahrten erstellt',
            subtitle: 'Erstelle eine Fahrt,\num Mitfahrende zu finden.',
          );
        }

        return Column(
          children: [
            const _SwipeHint(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 130),
                itemCount: meineFahrten.length,
                itemBuilder: (context, index) {
                  final fahrt = meineFahrten[index];
                  return RepaintBoundary(
                    child: Dismissible(
                      key: ValueKey(fahrt.id),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _handleEdit(fahrt);
                          return false;
                        }
                        return _confirmDelete(fahrt);
                      },
                      onDismissed: (_) => _deleteFahrt(fahrt),
                      background: const _SwipeEditBackground(),
                      secondaryBackground: const _SwipeDeleteBackground(),
                      child: _FahrerGlassCard(fahrt: fahrt),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Roter Hintergrund beim Wischen (rechts → links)
class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          alignment: Alignment.centerRight,
          color: Colors.redAccent,
          padding: const EdgeInsets.only(right: 24),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_forever, color: Colors.white, size: 28),
              SizedBox(height: 4),
              Text(
                'Löschen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blauer Hintergrund beim Wischen (links → rechts = Bearbeiten)
class _SwipeEditBackground extends StatelessWidget {
  const _SwipeEditBackground();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            ),
          ),
          padding: const EdgeInsets.only(left: 24),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_outlined, color: Colors.white, size: 28),
              SizedBox(height: 4),
              Text(
                'Bearbeiten',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Einmaliger Hinweis oberhalb der Liste
class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swipe_right_outlined,
                color: Color(0xFF42A5F5), size: 15),
            const SizedBox(width: 5),
            const Text(
              'Bearbeiten',
              style: TextStyle(
                color: Color(0xFF42A5F5),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              width: 1,
              height: 12,
              color: Colors.white24,
            ),
            const Icon(Icons.swipe_left_outlined,
                color: Colors.redAccent, size: 15),
            const SizedBox(width: 5),
            const Text(
              'Löschen',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// TAB 2 – angefragte Fahrten (nach Datum sortiert)
/// ------------------------------------------------------------
class _AngefragteFahrtenTab extends StatefulWidget {
  final String userId;

  const _AngefragteFahrtenTab({required this.userId});

  @override
  State<_AngefragteFahrtenTab> createState() => _AngefragteFahrtenTabState();
}

class _AngefragteFahrtenTabState extends State<_AngefragteFahrtenTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer2<AnfrageService, FahrtService>(
      builder: (context, anfrageService, fahrtService, _) {
        final es = context.read<EventService>();
        final fahrtMap = {for (final f in fahrtService.alleFahrten) f.id: f};
        final datumCache = {for (final e in es.events) e.id: e.datum};

        final items = anfrageService
            .getAnfragenByRequester(widget.userId)
            .map((a) => _RequestedRideItem(a, fahrtMap[a.fahrtId]))
            .toList()
          ..sort((a, b) {
            // gelöschte Fahrten ans Ende
            final fA = a.fahrt;
            final fB = b.fahrt;
            if (fA == null && fB == null) return 0;
            if (fA == null) return 1;
            if (fB == null) return -1;
            return (datumCache[fA.eventId] ?? DateTime(9999))
                .compareTo(datumCache[fB.eventId] ?? DateTime(9999));
          });

        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Noch keine Mitfahranfragen',
            subtitle: 'Suche dir eine Fahrt aus\nund sende eine Anfrage.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 130),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item.fahrt == null) {
              return RepaintBoundary(
                child: _RequestedRideDeletedCard(anfrage: item.anfrage),
              );
            }
            return RepaintBoundary(
              child: _RequestedRideCard(fahrt: item.fahrt!, anfrage: item.anfrage),
            );
          },
        );
      },
    );
  }
}

/// ------------------------------------------------------------
/// Helper: Anfrage + Fahrt
/// ------------------------------------------------------------
class _RequestedRideItem {
  final AnfrageDaten anfrage;
  final FahrtDaten? fahrt;

  _RequestedRideItem(this.anfrage, this.fahrt);
}


/// ------------------------------------------------------------
/// Card: angebotene Fahrt (FAHRER)
/// ------------------------------------------------------------
class _FahrerGlassCard extends StatelessWidget {
  final FahrtDaten fahrt;

  const _FahrerGlassCard({required this.fahrt});

  @override
  Widget build(BuildContext context) {
    final counts =
        context.select<AnfrageService, ({int offen, int belegt})>((s) {
      final list = s.getAnfragenForFahrt(fahrt.id);
      return (
        offen: list.where((a) => a.status == AnfrageStatus.offen).length,
        belegt: list
            .where((a) => a.status == AnfrageStatus.akzeptiert)
            .fold<int>(0, (sum, a) => sum + (a.seatsAccepted ?? 0)),
      );
    });

    final gesamtPlaetze = fahrt.freiePlaetze + counts.belegt;
    final uhrzeit = fahrt.uhrzeit.format(context);
    final rueckuhrzeit = fahrt.rueckuhrzeit?.format(context);
    final istHinUndZurueck =
        fahrt.richtung == Fahrtrichtung.hinUndZurueck && rueckuhrzeit != null;

    final event = context.read<EventService>().events.firstWhere(
          (e) => e.id == fahrt.eventId,
          orElse: () => Event(
            name: fahrt.eventName,
            datum: DateTime(2000),
            standort: fahrt.standort,
            beschreibung: '',
            typ: '',
            adresse: '',
          ),
        );

    final accentColor = switch (fahrt.richtung) {
      Fahrtrichtung.hinfahrt => Colors.greenAccent,
      Fahrtrichtung.rueckfahrt => Colors.orangeAccent,
      Fahrtrichtung.hinUndZurueck => Colors.blueAccent,
    };

    final richtungLabel = switch (fahrt.richtung) {
      Fahrtrichtung.hinfahrt => 'Hinfahrt',
      Fahrtrichtung.rueckfahrt => 'Rückfahrt',
      Fahrtrichtung.hinUndZurueck => 'Hin & Zurück',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppCard(
        padding: EdgeInsets.zero,
        borderRadius: 22,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Dünner Farbstreifen ganz links ──
                  Container(width: 4, color: accentColor),

                  // ── Fahrtrichtungstext (Card-Hintergrund) ──
                  SizedBox(
                    width: 26,
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          richtungLabel,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Trennstrich ──
                  Container(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),

                  // ── Hauptinhalt ──
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event-Name + Badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _showEventInfoDialog(context, event),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              fahrt.eventName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.info_outline,
                                              color: Colors.white38, size: 12),
                                        ],
                                      ),
                                      if (event.datum.year != 2000) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('dd. MMMM yyyy', 'de')
                                              .format(event.datum),
                                          style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _AuslastungBadge(
                                freiePlaetze: fahrt.freiePlaetze,
                                gesamtPlaetze: gesamtPlaetze,
                              ),
                            ],
                          ),

                          const Divider(
                            color: Colors.white12,
                            thickness: 1,
                            height: 20,
                          ),

                          // Route
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: fahrt.abfahrtsortAnzeige,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                const TextSpan(
                                  text: '  →  ',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: fahrt.standort,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Uhrzeiten (hervorgehoben, nebeneinander)
                          Wrap(
                            spacing: 8,
                            children: [
                              _TimeBadge(icon: Icons.schedule, text: uhrzeit),
                              if (istHinUndZurueck)
                                _TimeBadge(icon: Icons.sync, text: rueckuhrzeit),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Anfragen-Button
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FahrtAnfragenPage(fahrt: fahrt),
                                  ),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blueAccent
                                            .withValues(alpha: 0.85),
                                        const Color(0xFF1E88E5)
                                            .withValues(alpha: 0.75),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blueAccent
                                            .withValues(alpha: 0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.inbox_outlined,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Anfragen ansehen',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (counts.offen > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(12),
  color: Colors.white.withValues(alpha: 0.08),
  border: Border.all(
    color: Colors.white.withValues(alpha: 0.18),
  ),
),
                                          child: Text(
                                            '${counts.offen}',
                                            style: const TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w600,
  fontSize: 14,
  letterSpacing: 0.2,
),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

/// ------------------------------------------------------------
/// Card: angefragte Fahrt (MITFAHRER)
/// ------------------------------------------------------------
class _RequestedRideCard extends StatelessWidget {
  final FahrtDaten fahrt;
  final AnfrageDaten anfrage;

  const _RequestedRideCard({required this.fahrt, required this.anfrage});

  void _openChat(BuildContext context) {
    final chatService = context.read<ChatService>();

    final conversationId = chatService.buildConversationId(
      fahrtId: fahrt.id,
      userA: fahrt.ownerId,
      userB: anfrage.requesterId,
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => ChatPage(
          conversationId: conversationId,
          otherUserName: anfrage.requesterName,
        ),
      ),
    );

    // Conversation + Systemnachricht im Hintergrund sicherstellen
    chatService.ensureConversation(
      fahrtId: fahrt.id,
      ownerId: fahrt.ownerId,
      requesterId: anfrage.requesterId,
      eventName: fahrt.eventName,
      startOrt: fahrt.abfahrtsort,
      zielOrt: fahrt.standort,
      seatsRequested: anfrage.seatsRequested,
    ).then((_) => chatService.updateSystemMessage(
      conversationId: conversationId,
      eventName: fahrt.eventName,
      startOrt: fahrt.abfahrtsort,
      zielOrt: fahrt.standort,
      seatsRequested: anfrage.seatsRequested,
      seatsAccepted: anfrage.seatsAccepted ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final event = context.read<EventService>().events.firstWhere(
          (e) => e.id == fahrt.eventId,
          orElse: () => Event(
            name: fahrt.eventName,
            datum: DateTime(2000),
            standort: fahrt.standort,
            beschreibung: '',
            typ: '',
            adresse: '',
          ),
        );

    final accentColor = switch (fahrt.richtung) {
      Fahrtrichtung.hinfahrt => Colors.greenAccent,
      Fahrtrichtung.rueckfahrt => Colors.orangeAccent,
      Fahrtrichtung.hinUndZurueck => Colors.blueAccent,
    };

    final richtungLabel = switch (fahrt.richtung) {
      Fahrtrichtung.hinfahrt => 'Hinfahrt',
      Fahrtrichtung.rueckfahrt => 'Rückfahrt',
      Fahrtrichtung.hinUndZurueck => 'Hin & Zurück',
    };

    final rueckuhrzeit = fahrt.rueckuhrzeit?.format(context);
    final istHinUndZurueck =
        fahrt.richtung == Fahrtrichtung.hinUndZurueck && rueckuhrzeit != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppCard(
        padding: EdgeInsets.zero,
        borderRadius: 22,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Dünner Farbstreifen ganz links ──
              Container(width: 4, color: accentColor),

              // ── Fahrtrichtungstext ──
              SizedBox(
                width: 26,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      richtungLabel,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Trennstrich ──
              Container(
                width: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),

              // ── Hauptinhalt ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          // Event-Name (anklickbar) + Status-Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showEventInfoDialog(context, event),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              fahrt.eventName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.info_outline,
                              color: Colors.white38, size: 12),
                        ],
                      ),
                      if (event.datum.year != 2000) ...[
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd. MMMM yyyy', 'de').format(event.datum),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: anfrage.status),
            ],
          ),

          const Divider(
            color: Colors.white12,
            thickness: 1,
            height: 20,
          ),

          // Fahrer-Block (anklickbar, Avatar + Name/Rating + Chevron)
          GestureDetector(
            onTap: () {}, // Platzhalter für spätere Profilnavigation
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  child: Text(
                    fahrt.ownerName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fahrt.ownerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: const [
                          Icon(Icons.star, color: Colors.amber, size: 12),
                          SizedBox(width: 3),
                          Text(
                            '5,0',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 8),

          // Route
          Text(
            '${fahrt.abfahrtsortAnzeige}  →  ${fahrt.standort}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // Zeit & Plätze
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _TimeBadge(
                icon: Icons.schedule,
                text: fahrt.uhrzeit.format(context),
              ),
              if (istHinUndZurueck)
                _TimeBadge(icon: Icons.sync, text: rueckuhrzeit),
              _TimeBadge(
                icon: Icons.event_seat,
                text: anfrage.seatsAccepted != null
                    ? '${anfrage.seatsAccepted} / ${anfrage.seatsRequested} Plätze'
                    : '${anfrage.seatsRequested} Plätze',
              ),
            ],
          ),

                  const SizedBox(height: 12),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withValues(alpha: 0.75),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _openChat(context),
                      child: const Text('Chat öffnen', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

/// ------------------------------------------------------------
/// Card: Fahrt gelöscht
/// ------------------------------------------------------------
class _RequestedRideDeletedCard extends StatelessWidget {
  final AnfrageDaten anfrage;

  const _RequestedRideDeletedCard({required this.anfrage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment(0.8, 1),
            colors: [Color(0xFF1F2A3C), Color(0xFF243A5E)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 22,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              anfrage.eventName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.route, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  '${anfrage.startOrt} → ${anfrage.zielOrt}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Fahrt wurde gelöscht',
              style: TextStyle(
                color: Colors.redAccent.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Badge: Auslastung – „frei / gesamt Plätze"
/// ------------------------------------------------------------
class _AuslastungBadge extends StatelessWidget {
  final int freiePlaetze;
  final int gesamtPlaetze;

  const _AuslastungBadge({
    required this.freiePlaetze,
    required this.gesamtPlaetze,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (freiePlaetze == 0) {
      color = Colors.redAccent;
    } else if (freiePlaetze == 1) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        freiePlaetze == 0
            ? 'Ausgebucht'
            : '$freiePlaetze / $gesamtPlaetze Plätze',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Badge: Anfrage-Status
/// ------------------------------------------------------------
class _StatusBadge extends StatelessWidget {
  final AnfrageStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;

    switch (status) {
      case AnfrageStatus.offen:
        color = Colors.blueAccent;
        text = 'Offen';
      case AnfrageStatus.akzeptiert:
        color = Colors.green;
        text = 'Akzeptiert';
      case AnfrageStatus.abgelehnt:
        color = Colors.redAccent;
        text = 'Abgelehnt';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


/// ------------------------------------------------------------
/// Empty State
/// ------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TimeBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white60),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
