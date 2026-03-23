import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _hintKey = 'swipe_delete_hint_shown';
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _loadHintState();
  }

  Future<void> _loadHintState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted && !(prefs.getBool(_hintKey) ?? false)) {
      setState(() => _showHint = true);
    }
  }

  Future<void> _markHintSeen() async {
    if (!_showHint) return;
    setState(() => _showHint = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hintKey, true);
  }

  /// Zeigt Bestätigungs-Dialog und gibt true zurück wenn löschen bestätigt.
  Future<bool?> _confirmDelete(FahrtDaten fahrt) async {
    await _markHintSeen();
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
            if (_showHint) const _SwipeHint(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: meineFahrten.length,
                itemBuilder: (context, index) {
                  final fahrt = meineFahrten[index];
                  return RepaintBoundary(
                    child: Dismissible(
                      key: ValueKey(fahrt.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmDelete(fahrt),
                      onDismissed: (_) => _deleteFahrt(fahrt),
                      background: const _SwipeDeleteBackground(),
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

/// Einmaliger Hinweis oberhalb der Liste
class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.swipe_left_outlined,
              color: Colors.white38, size: 16),
          const SizedBox(width: 6),
          Text(
            'Fahrt nach links wischen zum Löschen',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
            ),
          ),
        ],
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
          padding: const EdgeInsets.only(bottom: 120),
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
/// Gemeinsame Glas-Hülle (dynamische Höhe)
/// ------------------------------------------------------------
class _GlassShell extends StatelessWidget {
  final Widget child;

  const _GlassShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: child,
          ),
        ),
      ),
    );
  }
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
    final istHinUndZurueck = fahrt.richtung == Fahrtrichtung.hinUndZurueck &&
        rueckuhrzeit != null;

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

    return _GlassShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zeile 1: Event-Name (kursiv, anklickbar) + Auslastungs-Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showEventInfoDialog(context, event),
                  child: Text(
                    fahrt.eventName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
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

          // Zeile 2: Datum (hervorgehoben)
          if (event.datum.year != 2000) ...[
            const SizedBox(height: 2),
            Text(
              DateFormat('dd. MMMM yyyy', 'de').format(event.datum),
              style: const TextStyle(
                color: Color(0xFFFFD180),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 6),

          // Route – größter Text, darf umbrechen
          Text(
            '${fahrt.abfahrtsortAnzeige}  →  ${fahrt.standort}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          // Uhrzeit(en) – bei Hin+Rück untereinander
          if (istHinUndZurueck) ...[
            _TimeRow(label: 'Hin', time: uhrzeit),
            const SizedBox(height: 2),
            _TimeRow(label: 'Rück', time: rueckuhrzeit),
          ] else
            _TimeRow(label: null, time: uhrzeit),

          // Offene Anfragen (nur wenn vorhanden)
          if (counts.offen > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.inbox_outlined,
                    size: 13, color: Colors.lightBlueAccent),
                const SizedBox(width: 3),
                Text(
                  '${counts.offen} offene ${counts.offen == 1 ? 'Anfrage' : 'Anfragen'}',
                  style: const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FahrtAnfragenPage(fahrt: fahrt),
                    ),
                  ),
                  child: const Text('Anfragen', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _handleEdit(context),
                  child:
                      const Text('Bearbeiten', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleEdit(BuildContext context) {
    final event = context.read<EventService>().events.firstWhere(
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
}

/// ------------------------------------------------------------
/// Card: angefragte Fahrt (MITFAHRER)
/// ------------------------------------------------------------
class _RequestedRideCard extends StatelessWidget {
  final FahrtDaten fahrt;
  final AnfrageDaten anfrage;

  const _RequestedRideCard({required this.fahrt, required this.anfrage});

  Future<void> _openChat(BuildContext context) async {
    final chatService = context.read<ChatService>();

    final conversation = await chatService.ensureConversation(
      fahrtId: fahrt.id,
      ownerId: fahrt.ownerId,
      requesterId: anfrage.requesterId,
      eventName: fahrt.eventName,
      startOrt: fahrt.abfahrtsort,
      zielOrt: fahrt.standort,
      seatsRequested: anfrage.seatsRequested,
    );

    await chatService.updateSystemMessage(
      conversationId: conversation.id,
      eventName: fahrt.eventName,
      startOrt: fahrt.abfahrtsort,
      zielOrt: fahrt.standort,
      seatsRequested: anfrage.seatsRequested,
      seatsAccepted: anfrage.seatsAccepted ?? 0,
    );

    if (!context.mounted) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => ChatPage(
          conversationId: conversation.id,
          otherUserName: anfrage.requesterName,
        ),
      ),
    );
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

    return _GlassShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zeile 1: Event-Name (kursiv, anklickbar) + Status-Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showEventInfoDialog(context, event),
                  child: Text(
                    fahrt.eventName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: anfrage.status),
            ],
          ),

          // Zeile 2: Datum (hervorgehoben)
          if (event.datum.year != 2000) ...[
            const SizedBox(height: 2),
            Text(
              DateFormat('dd. MMMM yyyy', 'de').format(event.datum),
              style: const TextStyle(
                color: Color(0xFFFFD180),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 5),

          // Fahrername + Sterne (kleiner als Route)
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white54, size: 13),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  fahrt.ownerName,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.star, color: Colors.amber, size: 12),
              const Icon(Icons.star, color: Colors.amber, size: 12),
              const Icon(Icons.star, color: Colors.amber, size: 12),
            ],
          ),

          const SizedBox(height: 3),

          // Route – größter Text, darf umbrechen
          Text(
            '${fahrt.abfahrtsortAnzeige}  →  ${fahrt.standort}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 5),

          // Zeit
          _TimeRow(label: null, time: fahrt.uhrzeit.format(context)),

          const SizedBox(height: 12),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _openChat(context),
              child:
                  const Text('Chat öffnen', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
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
    return Card(
      color: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
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
/// Zeile: Uhrzeit mit optionalem Label (Hin / Rück)
/// ------------------------------------------------------------
class _TimeRow extends StatelessWidget {
  final String? label;
  final String time;

  const _TimeRow({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.access_time, color: Colors.amberAccent, size: 13),
        const SizedBox(width: 3),
        if (label != null) ...[
          Text(
            '$label  ',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        Text(
          time,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
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
