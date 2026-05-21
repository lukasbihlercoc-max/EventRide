import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/views/widgets/app_card.dart';
import 'package:my_app/views/widgets/trust_shields_widget.dart';

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
import 'package:my_app/views/widgets/user_avatar_widget.dart';
import 'package:my_app/views/pages/public_profile_page.dart';
import 'package:my_app/views/pages/fahrt_finden_page.dart';

import 'package:my_app/views/auth/verification_guard.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/pages/chat_page.dart';
import 'package:my_app/views/pages/detail_page.dart';
import 'package:my_app/data/interessenten_service.dart';
import 'package:my_app/data/interessenten_daten.dart';

// ---------------------------------------------------------------------------
// Hilfsfunktion: Event-Detail-Dialog
// ---------------------------------------------------------------------------
void _showEventInfoDialog(BuildContext context, Event event) {
  bool ichWillHinExpanded = false;
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final size = MediaQuery.of(ctx).size;
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final interessenten =
              Provider.of<InteressentenService>(ctx, listen: false)
                  .getForEvent(event.id);
          final sorted = [...interessenten]
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          final extraCount = sorted.length - 1;

          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                                AppRoute(
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
                          const Icon(Icons.place,
                              color: Colors.white70, size: 18),
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
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15),
                        ),
                      ],
                      // ── Ich will hin ──
                      if (sorted.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white24, thickness: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.people_outline,
                                size: 14, color: Colors.white54),
                            const SizedBox(width: 6),
                            const Text(
                              'Ich will hin',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${sorted.length}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _IchWillHinRow(person: sorted[0]),
                        if (extraCount > 0) ...[
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: ichWillHinExpanded
                                ? Column(
                                    children: sorted
                                        .skip(1)
                                        .map((p) => _IchWillHinRow(person: p))
                                        .toList(),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          GestureDetector(
                            onTap: () => setDialogState(
                                () => ichWillHinExpanded = !ichWillHinExpanded),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    ichWillHinExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 14,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ichWillHinExpanded
                                        ? 'Weniger anzeigen'
                                        : '+ $extraCount weitere anzeigen',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
    },
  );
}

// ---------------------------------------------------------------------------
// Hilfsfunktion: Eventdatum für Sortierung (unbekannte Events ans Ende)
// ---------------------------------------------------------------------------

/// Gibt true zurück wenn das Event bereits vorbei ist (+ 3h Puffer)
/// UND weniger als 30 Tage her ist → Anzeige-Grenze.
bool _istVergangen(DateTime eventDatum) {
  if (eventDatum.year == 2000) return false; // unbekanntes Datum → aktiv lassen
  final ende = eventDatum.add(const Duration(hours: 3));
  final anzeigeGrenze = ende.add(const Duration(days: 30));
  final now = DateTime.now();
  return ende.isBefore(now) && anzeigeGrenze.isAfter(now);
}

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
                          AppRoute(builder: (_) => const LoginPage()),
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
    if (_tabController.index != 0) return;
    final anfrageService = context.read<AnfrageService>();
    final seenService = context.read<SeenAnfragenService>();
    final userId = widget.user.userId;

    final ids = anfrageService
        .getAnfragenByRequester(userId)
        .where((a) =>
            (a.status != AnfrageStatus.offen &&
                a.status != AnfrageStatus.storniert) ||
            a.vonFahrer)
        .map((a) => a.id)
        .toList();
    seenService.markRequesterAsSeen(userId, ids);
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
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _AngefragteFahrtenTab(userId: userId),
                  _AngeboteneFahrtenTab(userId: userId),
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
        final requesterIds = anfrageService
            .getAnfragenByRequester(userId)
            .where((a) =>
              (a.status != AnfrageStatus.offen &&
                  a.status != AnfrageStatus.storniert) ||
              a.vonFahrer)
            .map((a) => a.id);

        return TabBar(
          controller: tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            _tabLabel('Mitfahrten', seenService.hasUnseenRequester(userId, requesterIds)),
            const Tab(child: Text('Meine Fahrten')),
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
      AppRoute(
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

        // Aktive vs. vergangene Fahrten trennen
        final aktiveFahrten = meineFahrten
            .where((f) =>
                !_istVergangen(datumCache[f.eventId] ?? DateTime(9999)))
            .toList();
        final vergangeneFahrten = meineFahrten
            .where((f) =>
                _istVergangen(datumCache[f.eventId] ?? DateTime(9999)))
            .toList()
          ..sort((a, b) => (datumCache[b.eventId] ?? DateTime(2000))
              .compareTo(datumCache[a.eventId] ?? DateTime(2000)));

        if (aktiveFahrten.isEmpty && vergangeneFahrten.isEmpty) {
          return const _EmptyState(
            icon: Icons.directions_car_filled_outlined,
            title: 'Noch keine Fahrten erstellt',
            subtitle: 'Erstelle eine Fahrt,\num Mitfahrende zu finden.',
          );
        }

        return Column(
          children: [
            if (aktiveFahrten.isNotEmpty) const _SwipeHint(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final fahrt = aktiveFahrten[index];
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
                      childCount: aktiveFahrten.length,
                    ),
                  ),
                  if (vergangeneFahrten.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _VergangeneGlassSection(
                        fahrten: vergangeneFahrten,
                        datumCache: datumCache,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 130)),
                ],
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

  /// Unabhängig vom SeenAnfragenService — wird nur durch echte Interaktion geleert.
  final Set<String> _unseenCardIds = {};

  /// Fügt neue unseen-IDs aus dem SeenService hinzu (ohne setState — wird in build aufgerufen).
  /// Nur Status-Änderungen (akzeptiert/abgelehnt) und Fahrer-Einladungen lösen den Dot aus —
  /// eigene offene Anfragen werden bewusst ignoriert.
  void _syncUnseenIds(List<_RequestedRideItem> items, SeenAnfragenService seenService) {
    for (final item in items) {
      if (item.fahrt == null) continue;
      final a = item.anfrage;
      final isRelevant = (a.status != AnfrageStatus.offen &&
                          a.status != AnfrageStatus.storniert) ||
                         a.vonFahrer;
      if (!isRelevant) continue;
      if (seenService.hasUnseenRequester(widget.userId, [a.id])) {
        _unseenCardIds.add(a.id);
      }
    }
  }

  /// Wird aufgerufen wenn der User mit der Card interagiert (Chat öffnen / Annehmen / Ablehnen).
  void _markCardSeen(String anfrageId) {
    if (_unseenCardIds.contains(anfrageId)) {
      setState(() => _unseenCardIds.remove(anfrageId));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer3<AnfrageService, FahrtService, SeenAnfragenService>(
      builder: (context, anfrageService, fahrtService, seenService, _) {
        final fahrtMap = {for (final f in fahrtService.alleFahrten) f.id: f};
        final es = context.read<EventService>();
        final eventDatumCache = {for (final e in es.events) e.id: e.datum};

        final items = anfrageService
            .getAnfragenByRequester(widget.userId)
            .map((a) => _RequestedRideItem(a, fahrtMap[a.fahrtId]))
            .toList();

        _syncUnseenIds(items, seenService);

        // Einladungen: vonFahrer && offen (mit vorhandener Fahrt)
        final einladungen = items
            .where((i) =>
                i.fahrt != null &&
                i.anfrage.vonFahrer &&
                i.anfrage.status == AnfrageStatus.offen)
            .toList()
          ..sort((a, b) {
            final aUnseen = _unseenCardIds.contains(a.anfrage.id) ? 0 : 1;
            final bUnseen = _unseenCardIds.contains(b.anfrage.id) ? 0 : 1;
            if (aUnseen != bUnseen) return aUnseen - bUnseen;
            return b.anfrage.updatedAt.compareTo(a.anfrage.updatedAt);
          });

        // Alle restlichen Anfragen (keine offene Fahrereinladung)
        final alleNormal = items
            .where((i) =>
                !(i.anfrage.vonFahrer &&
                    i.anfrage.status == AnfrageStatus.offen))
            .toList();

        // Vergangene: akzeptiert + Event vorbei + innerhalb 30 Tage
        final vergangeneAnfragen = alleNormal
            .where((i) =>
                i.fahrt != null &&
                i.anfrage.status == AnfrageStatus.akzeptiert &&
                _istVergangen(
                    eventDatumCache[i.fahrt!.eventId] ?? DateTime(9999)))
            .toList()
          ..sort((a, b) =>
              (eventDatumCache[b.fahrt!.eventId] ?? DateTime(2000))
                  .compareTo(
                      eventDatumCache[a.fahrt!.eventId] ?? DateTime(2000)));

        // Aktive: alles andere (ohne vergangene)
        final vergangeneSet = vergangeneAnfragen.toSet();
        final normalAnfragen = alleNormal
            .where((i) => !vergangeneSet.contains(i))
            .toList()
          ..sort((a, b) {
            if (a.fahrt == null && b.fahrt == null) return 0;
            if (a.fahrt == null) return 1;
            if (b.fahrt == null) return -1;
            return b.anfrage.updatedAt.compareTo(a.anfrage.updatedAt);
          });

        if (einladungen.isEmpty &&
            normalAnfragen.isEmpty &&
            vergangeneAnfragen.isEmpty) {
          return const _EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Noch keine Mitfahranfragen',
            subtitle: 'Suche dir eine Fahrt aus\nund sende eine Anfrage.',
          );
        }

        return CustomScrollView(
          slivers: [
            if (einladungen.isNotEmpty)
              SliverToBoxAdapter(
                child: _EinladungsSection(
                  items: einladungen,
                  unseenCardIds: _unseenCardIds,
                  onMarkSeen: _markCardSeen,
                ),
              ),
            if (normalAnfragen.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                            color: Colors.white.withValues(alpha: 0.25),
                            thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: const [
                            Icon(Icons.list_alt_outlined,
                                size: 13, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              'DEINE ANFRAGEN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Divider(
                            color: Colors.white.withValues(alpha: 0.25),
                            thickness: 1),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = normalAnfragen[index];
                    if (item.fahrt == null) {
                      return RepaintBoundary(
                        child: _RequestedRideDeletedCard(anfrage: item.anfrage),
                      );
                    }
                    final anfrageId = item.anfrage.id;
                    return RepaintBoundary(
                      child: _RequestedRideCard(
                        fahrt: item.fahrt!,
                        anfrage: item.anfrage,
                        isUnseen: _unseenCardIds.contains(anfrageId),
                        onInteracted: () => _markCardSeen(anfrageId),
                      ),
                    );
                  },
                  childCount: normalAnfragen.length,
                ),
              ),
            ],
            if (vergangeneAnfragen.isNotEmpty)
              SliverToBoxAdapter(
                child: _VergangeneAnfragenSection(
                  items: vergangeneAnfragen,
                  eventDatumCache: eventDatumCache,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
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
/// Einladungs-Sektion (collapsible, oben im Mitfahrten-Tab)
/// ------------------------------------------------------------
class _EinladungsSection extends StatefulWidget {
  final List<_RequestedRideItem> items;
  final Set<String> unseenCardIds;
  final void Function(String) onMarkSeen;

  const _EinladungsSection({
    required this.items,
    required this.unseenCardIds,
    required this.onMarkSeen,
  });

  @override
  State<_EinladungsSection> createState() => _EinladungsSectionState();
}

class _EinladungsSectionState extends State<_EinladungsSection> {
  bool _expanded = false;

  static const _orange = Color(0xFFFFB74D);

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final extraCount = items.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section-Header — zentriert mit Trennlinien
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                    color: Colors.white.withValues(alpha: 0.25), thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: const [
                    Icon(Icons.mail_outline, size: 13, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'EINLADUNGEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Divider(
                    color: Colors.white.withValues(alpha: 0.25), thickness: 1),
              ),
            ],
          ),
        ),
        // Erste Einladung — immer sichtbar
        RepaintBoundary(
          child: _EinladungsCard(
            fahrt: items[0].fahrt!,
            anfrage: items[0].anfrage,
            isUnseen: widget.unseenCardIds.contains(items[0].anfrage.id),
            onInteracted: () => widget.onMarkSeen(items[0].anfrage.id),
          ),
        ),
        // Weitere Einladungen — collapsible
        if (extraCount > 0) ...[
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _expanded
                ? Column(
                    children: items
                        .skip(1)
                        .map((item) => RepaintBoundary(
                              child: _EinladungsCard(
                                fahrt: item.fahrt!,
                                anfrage: item.anfrage,
                                isUnseen: widget.unseenCardIds
                                    .contains(item.anfrage.id),
                                onInteracted: () =>
                                    widget.onMarkSeen(item.anfrage.id),
                              ),
                            ))
                        .toList(),
                  )
                : const SizedBox.shrink(),
          ),
          // Button — immer sichtbar wenn >1 Einladung, toggle expand/collapse
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: _orange.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 16,
                      color: _orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _expanded
                          ? 'Weniger anzeigen'
                          : '+ $extraCount weitere anzeigen',
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// ------------------------------------------------------------
/// Einladungs-Card (ausklappbar, kein Richtungsstreifen)
/// ------------------------------------------------------------
class _EinladungsCard extends StatefulWidget {
  final FahrtDaten fahrt;
  final AnfrageDaten anfrage;
  final bool isUnseen;
  final VoidCallback? onInteracted;

  const _EinladungsCard({
    required this.fahrt,
    required this.anfrage,
    this.isUnseen = false,
    this.onInteracted,
  });

  @override
  State<_EinladungsCard> createState() => _EinladungsCardState();
}

class _EinladungsCardState extends State<_EinladungsCard> {
  bool _expanded = false;

  static const _orange = Color(0xFFFFB74D);

  FahrtDaten get fahrt => widget.fahrt;
  AnfrageDaten get anfrage => widget.anfrage;

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

    final rueckuhrzeit = fahrt.rueckuhrzeit?.format(context);
    final istHinUndZurueck =
        fahrt.richtung == Fahrtrichtung.hinUndZurueck && rueckuhrzeit != null;

    final cardChild = GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kopfzeile: Eventname | Badge rechts | Pfeil
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
                            DateFormat('dd. MMMM yyyy', 'de')
                                .format(event.datum),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Badge "Einladung" — rechts, leuchtender Stil
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                        color: _orange.withValues(alpha: 0.55), width: 1),
                  ),
                  child: const Text(
                    'Einladung',
                    style: TextStyle(
                      color: _orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white38,
                  size: 18,
                ),
              ],
            ),
            const Divider(color: Colors.white12, thickness: 1, height: 16),
            _FahrerProfilRow(userId: fahrt.ownerId, name: fahrt.ownerName),
            // Ausgeklappter Bereich
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 8),
                  Text(
                    '${fahrt.abfahrtsortAnzeige}  →  ${fahrt.standort}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _TimeBadge(
                          icon: Icons.schedule,
                          text: fahrt.uhrzeit.format(context)),
                      if (istHinUndZurueck)
                        _TimeBadge(icon: Icons.sync, text: rueckuhrzeit),
                      _TimeBadge(
                        icon: Icons.event_seat,
                        text:
                            '${anfrage.seatsRequested} Platz${anfrage.seatsRequested > 1 ? 'e' : ''}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _EinladungButtons(
                    anfrage: anfrage,
                    fahrt: fahrt,
                    onInteracted: widget.onInteracted,
                  ),
                ],
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            borderRadius: 22,
            child: cardChild,
          ),
          Positioned(
            right: 6,
            top: 6,
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
            .fold<int>(0, (acc, a) => acc + (a.seatsAccepted ?? 0)),
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
                                  AppRoute(
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
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.18,
                                          ),
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
class _RequestedRideCard extends StatefulWidget {
  final FahrtDaten fahrt;
  final AnfrageDaten anfrage;
  final bool isUnseen;
  final VoidCallback? onInteracted;

  const _RequestedRideCard({
    required this.fahrt,
    required this.anfrage,
    required this.isUnseen,
    this.onInteracted,
  });

  @override
  State<_RequestedRideCard> createState() => _RequestedRideCardState();
}

class _RequestedRideCardState extends State<_RequestedRideCard> {
  bool _expanded = false;

  FahrtDaten get fahrt => widget.fahrt;
  AnfrageDaten get anfrage => widget.anfrage;

  void _openChat(BuildContext context) {
    if (!requireVerified(context)) return;
    widget.onInteracted?.call();
    final chatService = context.read<ChatService>();

    final conversationId = chatService.buildConversationId(
      fahrtId: fahrt.id,
      userA: fahrt.ownerId,
      userB: anfrage.requesterId,
    );

    Navigator.of(context).push(
      AppRoute(
        builder: (_) => ChatPage(
          conversationId: conversationId,
          otherUserName: fahrt.ownerName,
          otherUserId: fahrt.ownerId,
        ),
      ),
    );

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
      uhrzeit:
          '${fahrt.uhrzeitHour.toString().padLeft(2, '0')}:${fahrt.uhrzeitMinute.toString().padLeft(2, '0')}',
      richtung: switch (fahrt.richtung) {
        Fahrtrichtung.hinfahrt => 'Hinfahrt',
        Fahrtrichtung.rueckfahrt => 'Rückfahrt',
        Fahrtrichtung.hinUndZurueck => 'Hin und Zurück',
      },
      ownerName: fahrt.ownerName,
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

    final isOffen = anfrage.status == AnfrageStatus.offen;
    final isAkzeptiert = anfrage.status == AnfrageStatus.akzeptiert;

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

    final bool isEinladung = anfrage.vonFahrer &&
        anfrage.status == AnfrageStatus.offen &&
        context.read<IAuthRepository>().currentUser?.userId ==
            anfrage.requesterId;

    final aktionenWidget = isEinladung
        ? _EinladungButtons(
            anfrage: anfrage,
            fahrt: fahrt,
            onInteracted: widget.onInteracted,
          )
        : _MitfahrerAktionen(
            anfrage: anfrage,
            event: event,
            openChat: () => _openChat(context),
            onInteracted: widget.onInteracted,
          );

    // ── Einladungs-Label ──
    Widget? einladungsLabel;
    if (anfrage.vonFahrer && anfrage.status == AnfrageStatus.offen) {
      einladungsLabel = Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline, color: Colors.amber.shade400, size: 11),
            const SizedBox(width: 3),
            Text(
              'Einladung',
              style: TextStyle(
                color: Colors.amber.shade400,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // ── Card-Inhalt je Status ──
    Widget cardChild;

    if (isAkzeptiert) {
      // Volle Card mit linkem Richtungsstreifen
      cardChild = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
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
            Container(width: 1, color: Colors.white.withValues(alpha: 0.12)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (einladungsLabel != null) einladungsLabel,
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
                                    DateFormat('dd. MMMM yyyy', 'de')
                                        .format(event.datum),
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 11),
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
                    const Divider(color: Colors.white12, thickness: 1, height: 16),
                    _FahrerProfilRow(userId: fahrt.ownerId, name: fahrt.ownerName),
                    const SizedBox(height: 6),
                    Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                    const SizedBox(height: 6),
                    Text(
                      '${fahrt.abfahrtsortAnzeige}  →  ${fahrt.standort}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _TimeBadge(
                            icon: Icons.schedule,
                            text: fahrt.uhrzeit.format(context)),
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
                    const SizedBox(height: 8),
                    aktionenWidget,
                    // Review-Prompt: nur nach abgeschlossener Fahrt anzeigen
                    _ReviewPrompt(
                      fahrtId: fahrt.id,
                      reviewedId: fahrt.ownerId,
                      reviewedName: fahrt.ownerName,
                      reviewedPhotoUrl: null,
                      eventDatum: event.datum,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isOffen) {
      // Minimale, expandierbare Card – kein Richtungsstreifen
      cardChild = GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: anfrage.status),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white38,
                    size: 18,
                  ),
                ],
              ),
              const Divider(color: Colors.white12, thickness: 1, height: 16),
              _FahrerProfilRow(userId: fahrt.ownerId, name: fahrt.ownerName),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                    const SizedBox(height: 8),
                    Text(
                      '${fahrt.abfahrtsortAnzeige}  →  ${fahrt.standort}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _TimeBadge(
                            icon: Icons.schedule,
                            text: fahrt.uhrzeit.format(context)),
                        if (istHinUndZurueck)
                          _TimeBadge(icon: Icons.sync, text: rueckuhrzeit),
                        _TimeBadge(
                          icon: Icons.event_seat,
                          text:
                              '${anfrage.seatsRequested} Platz${anfrage.seatsRequested > 1 ? 'e' : ''}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    aktionenWidget,
                  ],
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
            ],
          ),
        ),
      );
    } else {
      // Inaktiv (abgelehnt / storniert) – Farben via _InaktivStyles
      cardChild = Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (einladungsLabel != null) einladungsLabel,
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
                                  color: _InaktivStyles.titelFarbe,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.info_outline,
                                color: _InaktivStyles.infoIconFarbe, size: 12),
                          ],
                        ),
                        if (event.datum.year != 2000) ...[
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd. MMMM yyyy', 'de').format(event.datum),
                            style: const TextStyle(
                                color: _InaktivStyles.datumFarbe, fontSize: 11),
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
                color: _InaktivStyles.dividerFarbe, thickness: 1, height: 20),
            _FahrerProfilRow(
              userId: fahrt.ownerId,
              name: fahrt.ownerName,
              nameFarbe: _InaktivStyles.fahrerNameFarbe,
              chevronFarbe: _InaktivStyles.fahrerChevronFarbe,
              avatarBg: _InaktivStyles.fahrerAvatarBg,
              avatarRadius: _InaktivStyles.fahrerAvatarRadius,
            ),
            const SizedBox(height: 8),
            aktionenWidget,
          ],
        ),
      );
    }

    final bool isInaktiv = !isOffen && !isAkzeptiert;

    final Widget card = isInaktiv
        ? Opacity(
            opacity: _InaktivStyles.cardOpacity,
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: _InaktivStyles.cardDecoration(),
              child: cardChild,
            ),
          )
        : AppCard(
            padding: EdgeInsets.zero,
            borderRadius: 22,
            child: cardChild,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          card,

          // ── Rahmen aktive Card ────────────────────────────────────────────
          // Liegt als letztes Layer über der Card → unabhängig vom Gradient
          // alpha: 0.0–1.0 · width in Pixeln ← hier anpassen
          if (!isInaktiv)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),

          if (widget.isUnseen)
            Positioned(
              right: 6,
              top: 6,
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
}

/// ------------------------------------------------------------
/// Annehmen / Ablehnen — nur für offene Einladungen (vonFahrer)
/// ------------------------------------------------------------
class _EinladungButtons extends StatefulWidget {
  final AnfrageDaten anfrage;
  final FahrtDaten fahrt;
  final VoidCallback? onInteracted;

  const _EinladungButtons({
    required this.anfrage,
    required this.fahrt,
    this.onInteracted,
  });

  @override
  State<_EinladungButtons> createState() => _EinladungButtonsState();
}

class _EinladungButtonsState extends State<_EinladungButtons> {
  bool _loading = false;

  Future<void> _annehmen() async {
    if (!requireVerified(context)) return;
    setState(() => _loading = true);
    final anfrageService = context.read<AnfrageService>();
    try {
      final ok = await anfrageService.acceptAnfrageAtomisch(
        anfrage: widget.anfrage,
        seatsAccepted: 1,
      );
      if (!ok || !mounted) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (mounted) {
        widget.onInteracted?.call();
        AppSnackbar.show(context, message: 'Einladung angenommen!');
      }
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'already-exists' => 'Du hast bereits eine Fahrt für dieses Event.',
        'failed-precondition' => e.message ?? 'Einladung wurde zurückgezogen.',
        'not-found' => 'Fahrt oder Einladung nicht mehr vorhanden.',
        _ => 'Fehler: ${e.message ?? e.code}',
      };
      AppSnackbar.show(context, message: msg);
      setState(() => _loading = false);
    }
  }

  Future<void> _ablehnen() async {
    setState(() => _loading = true);
    await context.read<AnfrageService>().ablehnenAnfrage(widget.anfrage);
    if (mounted) {
      widget.onInteracted?.call();
      AppSnackbar.show(context, message: 'Einladung abgelehnt.');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _ablehnen,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white54,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Ablehnen', style: TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _annehmen,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Annehmen', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// Status-abhängige Aktionen (Mitfahrer-Sicht)
/// ------------------------------------------------------------
class _MitfahrerAktionen extends StatefulWidget {
  final AnfrageDaten anfrage;
  final Event event;
  final VoidCallback openChat;
  final VoidCallback? onInteracted;

  const _MitfahrerAktionen({
    required this.anfrage,
    required this.event,
    required this.openChat,
    this.onInteracted,
  });

  @override
  State<_MitfahrerAktionen> createState() => _MitfahrerAktionenState();
}

class _MitfahrerAktionenState extends State<_MitfahrerAktionen> {
  bool _loading = false;

  Future<void> _stornieren() async {
    setState(() => _loading = true);
    await context.read<AnfrageService>().storniereAnfrage(widget.anfrage);
    widget.onInteracted?.call();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
        ),
      );
    }

    switch (widget.anfrage.status) {
      // ── OFFEN: warten + zurückziehen ──────────────────────────
      case AnfrageStatus.offen:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: widget.openChat,
              icon: const Icon(Icons.chat_bubble_outline,
                  color: Colors.white38, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              tooltip: 'Chat öffnen',
            ),
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1F2E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Anfrage zurückziehen?',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    content: const Text(
                      'Möchtest du deine Anfrage wirklich zurückziehen?',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Abbrechen',
                            style: TextStyle(color: Colors.white54)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Zurückziehen',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) _stornieren();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white38,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
              ),
              child: const Text(
                'Anfrage zurückziehen',
                style: TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white24,
                ),
              ),
            ),
          ],
        );

      // ── AKZEPTIERT: mit Fahrer chatten ────────────────────────
      case AnfrageStatus.akzeptiert:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.chat_bubble_outline, size: 14),
            label: const Text(
              'Mit Fahrer chatten',
              style: TextStyle(fontSize: 12),
            ),
            onPressed: widget.openChat,
          ),
        );

      // ── ABGELEHNT: andere Fahrt finden ────────────────────────
      case AnfrageStatus.abgelehnt:
        return TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            AppRoute(
              builder: (_) => FahrtFindenPage(event: widget.event),
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: _InaktivStyles.andereFahrtFarbe,
            overlayColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: Size.zero,
          ),
          icon: const Icon(Icons.search, size: 15,
              color: Color.fromARGB(255, 255, 170, 60)),
          label: const Text(
            'Andere Fahrt finden',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        );

      // ── STORNIERT / FAHRT GELÖSCHT: andere Fahrt finden ─────
      case AnfrageStatus.storniert:
      case AnfrageStatus.fahrtGeloescht:
        return TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            AppRoute(
              builder: (_) => FahrtFindenPage(event: widget.event),
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: _InaktivStyles.andereFahrtFarbe,
            overlayColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: Size.zero,
          ),
          icon: const Icon(Icons.search, size: 15,
              color: Color.fromARGB(255, 255, 170, 60)),
          label: const Text(
            'Andere Fahrt finden',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        );
    }
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
    final event = context.read<EventService>().events.firstWhere(
          (e) => e.id == anfrage.eventId,
          orElse: () => Event(
            name: anfrage.eventName,
            datum: DateTime(2000),
            standort: anfrage.zielOrt,
            beschreibung: '',
            typ: '',
            adresse: '',
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Opacity(
        opacity: _InaktivStyles.cardOpacity,
        child: Container(
          decoration: _InaktivStyles.cardDecoration(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                    anfrage.eventName,
                                    style: const TextStyle(
                                      color: _InaktivStyles.titelFarbe,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.info_outline,
                                    color: _InaktivStyles.infoIconFarbe,
                                    size: 12),
                              ],
                            ),
                            if (event.datum.year != 2000) ...[
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd. MMMM yyyy', 'de')
                                    .format(event.datum),
                                style: const TextStyle(
                                    color: _InaktivStyles.datumFarbe,
                                    fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _InaktivStyles.geloeschtColor
                            .withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Gelöscht',
                        style: TextStyle(
                          color: _InaktivStyles.geloeschtTextFarbe,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(
                    color: _InaktivStyles.dividerFarbe,
                    thickness: 1,
                    height: 20),
                _FahrerProfilRow(
                  userId: anfrage.fahrtOwnerId,
                  name: anfrage.fahrerName,
                  nameFarbe: _InaktivStyles.fahrerNameFarbe,
                  chevronFarbe: _InaktivStyles.fahrerChevronFarbe,
                  avatarBg: _InaktivStyles.fahrerAvatarBg,
                  avatarRadius: _InaktivStyles.fahrerAvatarRadius,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    AppRoute(
                      builder: (_) => FahrtFindenPage(event: event),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _InaktivStyles.andereFahrtFarbe,
                    overlayColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 0, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.search, size: 15,
                      color: Color.fromARGB(255, 255, 170, 60)),
                  label: const Text(
                    'Andere Fahrt finden',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
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
    final Color color = freiePlaetze == 0 ? Colors.blueGrey : Colors.green;

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
// ════════════════════════════════════════════════════════════════════════════
// Einstellungen für inaktive Cards (abgelehnt / storniert / gelöscht)
// Alle Farben hier zentral anpassen — kein anderer Ort nötig.
// ════════════════════════════════════════════════════════════════════════════
class _InaktivStyles {
  // ── Badge-Farben ──────────────────────────────────────────────────────────
  static const Color abgelehntColor      = Color(0xFFEF5B5B);
  static const Color abgelehntTextFarbe  = Color.fromARGB(200, 255, 255, 255);
  static const Color storniertColor      = Color(0xFF7A8FA3);
  static const Color storniertTextFarbe  = Color.fromARGB(200, 255, 255, 255);
  static const Color geloeschtColor      = Color(0xFFEF5B5B);
  static const Color geloeschtTextFarbe  = Color.fromARGB(200, 255, 255, 255);

  // ── Event-Titel ───────────────────────────────────────────────────────────
  static const Color titelFarbe      = Colors.white70;

  // ── Datum ─────────────────────────────────────────────────────────────────
  static const Color datumFarbe      = Colors.white38;

  // ── Info-Icon ─────────────────────────────────────────────────────────────
  static const Color infoIconFarbe   = Colors.white38;

  // ── Trennstrich ───────────────────────────────────────────────────────────
  static const Color dividerFarbe    = Colors.white10;

  // ── Fahrerprofil ──────────────────────────────────────────────────────────
  static const Color fahrerNameFarbe    = Colors.white60;
  static const Color fahrerChevronFarbe = Colors.white38;
  static const Color fahrerAvatarBg     = Color(0x26FFFFFF); // white ~15 %
  static const double fahrerAvatarRadius = 15.0; // ← Avatar-Größe anpassen

  // ── Gesamt-Transparenz der Card ───────────────────────────────────────────
  // 1.0 = voll sichtbar · 0.6 = deutlich abgedunkelt ← hier anpassen
  static const double cardOpacity = 0.95;

  // ── Link „Andere Fahrt finden" ────────────────────────────────────────────
  static const Color andereFahrtFarbe = Color.fromARGB(180, 255, 170, 60);

  // ── Kartenhintergrund ─────────────────────────────────────────────────────
  static BoxDecoration cardDecoration() => BoxDecoration(
    borderRadius: BorderRadius.circular(22),
    color: Colors.black.withValues(alpha: 0.6),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment(0.8, 1),
      colors: [
        Color(0xFF161E29), // etwas grauer
        Color(0xFF1E2C3D),
      ],
    ),
    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.14),
        blurRadius: 10,
        spreadRadius: -3,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

class _StatusBadge extends StatelessWidget {
  final AnfrageStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color textFarbe;
    final String text;

    switch (status) {
      case AnfrageStatus.offen:
        color = Colors.blueAccent;
        textFarbe = Colors.white;
        text = 'Offen';
      case AnfrageStatus.akzeptiert:
        color = Colors.green;
        textFarbe = Colors.white;
        text = 'Akzeptiert';
      case AnfrageStatus.abgelehnt:
        color = _InaktivStyles.abgelehntColor;
        textFarbe = _InaktivStyles.abgelehntTextFarbe;
        text = 'Abgelehnt';
      case AnfrageStatus.storniert:
        color = _InaktivStyles.storniertColor;
        textFarbe = _InaktivStyles.storniertTextFarbe;
        text = 'Zurückgezogen';
      case AnfrageStatus.fahrtGeloescht:
        color = Colors.deepOrange.withValues(alpha: 0.2);
        textFarbe = Colors.deepOrange;
        text = 'Fahrt abgesagt';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textFarbe,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white60),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _IchWillHinRow — kompakter Eintrag im Event-Info-Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _IchWillHinRow extends StatelessWidget {
  final InteressentenDaten person;
  const _IchWillHinRow({required this.person});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          UserAvatarWidget(
            name: person.userName,
            photoUrl: person.userPhotoUrl,
            radius: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (person.bezirk != null && person.bezirk!.isNotEmpty)
                  Text(
                    person.bezirk!,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FahrerProfilRow
// Avatar + Name + Rating — ganzer Block führt zur PublicProfilePage.
// Speichert die geladene photoUrl im State, damit kein zweiter Fetch nötig ist.
// ─────────────────────────────────────────────────────────────────────────────

class _FahrerProfilRow extends StatefulWidget {
  final String userId;
  final String name;
  final Color nameFarbe;
  final Color chevronFarbe;
  final Color avatarBg;
  final double avatarRadius;

  const _FahrerProfilRow({
    required this.userId,
    required this.name,
    this.nameFarbe = Colors.white,
    this.chevronFarbe = Colors.white38,
    this.avatarBg = const Color(0x26FFFFFF),
    this.avatarRadius = 19.0,
  });

  @override
  State<_FahrerProfilRow> createState() => _FahrerProfilRowState();
}

class _FahrerProfilRowState extends State<_FahrerProfilRow> {
  String? _photoUrl;

  void _navigate() {
    Navigator.push(
      context,
      AppRoute(
        builder: (_) => PublicProfilePage(
          userId: widget.userId,
          name: widget.name,
          photoUrl: _photoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigate,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          UserAvatarById(
            userId: widget.userId,
            name: widget.name,
            radius: widget.avatarRadius,
            backgroundColor: widget.avatarBg,
            onPhotoLoaded: (url) => _photoUrl = url,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.name,
                        style: TextStyle(
                          color: widget.nameFarbe,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    TrustShieldsByUserId(userId: widget.userId, size: 12),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: widget.chevronFarbe, size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ReviewPrompt
// Erscheint nach abgeschlossener Fahrt (Event + 3h vorbei), wenn noch kein
// Review für diesen Fahrer abgegeben wurde. Navigiert zur PublicProfilePage.
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewPrompt extends StatefulWidget {
  final String fahrtId;
  final String reviewedId;
  final String reviewedName;
  final String? reviewedPhotoUrl;
  final DateTime eventDatum;
  /// Wenn true: zeigt "Bewertet ✓" an statt nichts wenn Review bereits existiert.
  final bool showReviewedStatus;

  const _ReviewPrompt({
    required this.fahrtId,
    required this.reviewedId,
    required this.reviewedName,
    required this.reviewedPhotoUrl,
    required this.eventDatum,
    this.showReviewedStatus = false,
  });

  @override
  State<_ReviewPrompt> createState() => _ReviewPromptState();
}

class _ReviewPromptState extends State<_ReviewPrompt> {
  static final _cache = <String, bool>{};
  bool? _reviewExists; // null = loading, true = schon bewertet, false = ausstehend

  @override
  void initState() {
    super.initState();
    final cached = _cache[widget.fahrtId];
    if (cached != null) {
      _reviewExists = cached;
    } else {
      _check();
    }
  }

  Future<void> _check() async {
    final cutoff = widget.eventDatum.add(const Duration(hours: 3));
    final reviewDeadline = cutoff.add(const Duration(days: 14));
    final now = DateTime.now();

    // Event noch nicht vorbei → kein CTA
    if (cutoff.isAfter(now)) {
      _cache[widget.fahrtId] = true;
      if (mounted) setState(() => _reviewExists = true);
      return;
    }
    // 14-Tage-Frist abgelaufen → kein CTA (aber "Bewertet" bleibt sichtbar wenn nötig)
    if (reviewDeadline.isBefore(now)) {
      // Wenn showReviewedStatus aktiv, trotzdem prüfen ob bewertet → Status anzeigen
      if (widget.showReviewedStatus) {
        // weiter zum Firestore-Check
      } else {
        _cache[widget.fahrtId] = true;
        if (mounted) setState(() => _reviewExists = true);
        return;
      }
    }

    final currentUid = context.read<IAuthRepository>().currentUser?.userId;
    if (currentUid == null) {
      _cache[widget.fahrtId] = true;
      if (mounted) setState(() => _reviewExists = true);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('reviewerId', isEqualTo: currentUid)
          .where('reviewedId', isEqualTo: widget.reviewedId)
          .where('fahrtId', isEqualTo: widget.fahrtId)
          .limit(1)
          .get();
      final exists = snap.docs.isNotEmpty;
      _cache[widget.fahrtId] = exists;
      if (mounted) setState(() => _reviewExists = exists);
    } catch (_) {
      if (mounted) setState(() => _reviewExists = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bereits bewertet: optional kleinen Status zeigen
    if (_reviewExists == true) {
      if (widget.showReviewedStatus) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: const [
              Icon(Icons.check_circle_outline, size: 13, color: Colors.white30),
              SizedBox(width: 4),
              Text('Bewertet',
                  style: TextStyle(color: Colors.white30, fontSize: 12)),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }
    if (_reviewExists != false) return const SizedBox.shrink(); // loading

    // 14-Tage-Frist abgelaufen → kein CTA mehr
    final reviewDeadline = widget.eventDatum
        .add(const Duration(hours: 3))
        .add(const Duration(days: 14));
    if (reviewDeadline.isBefore(DateTime.now())) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            AppRoute(
              builder: (_) => PublicProfilePage(
                userId: widget.reviewedId,
                name: widget.reviewedName,
                photoUrl: widget.reviewedPhotoUrl,
              ),
            ),
          ).then((_) => _check());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_border_rounded,
                  color: Colors.amber, size: 14),
              const SizedBox(width: 6),
              const Text(
                'Fahrt bewerten',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.chevron_right,
                  color: Colors.amber.withValues(alpha: 0.5), size: 13),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vergangene Fahrten — Mitfahrer-Tab
// ─────────────────────────────────────────────────────────────────────────────

class _VergangeneAnfragenSection extends StatefulWidget {
  final List<_RequestedRideItem> items;
  final Map<String, DateTime> eventDatumCache;

  const _VergangeneAnfragenSection({
    required this.items,
    required this.eventDatumCache,
  });

  @override
  State<_VergangeneAnfragenSection> createState() =>
      _VergangeneAnfragenSectionState();
}

class _VergangeneAnfragenSectionState
    extends State<_VergangeneAnfragenSection>
    with SingleTickerProviderStateMixin {
  static const _kInitialCount = 2;
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _iconTurns;

  static const _grey = Colors.white38;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _sizeFactor =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final hasMore = items.length > _kInitialCount;
    final restItems = items.skip(_kInitialCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section-Header mit Trennlinien
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                    color: Colors.white.withValues(alpha: 0.25), thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: const [
                    Icon(Icons.history, size: 13, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'VERGANGENE FAHRTEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Divider(
                    color: Colors.white.withValues(alpha: 0.25), thickness: 1),
              ),
            ],
          ),
        ),
        // Immer sichtbare Karten
        for (var i = 0; i < items.length.clamp(0, _kInitialCount); i++)
          RepaintBoundary(
            child: _VergangeneAnfrageCard(
              fahrt: items[i].fahrt!,
              eventDatum:
                  widget.eventDatumCache[items[i].fahrt!.eventId] ??
                      DateTime(2000),
            ),
          ),
        // Ausklappbare Karten
        if (restItems.isNotEmpty)
          ClipRect(
            child: SizeTransition(
              sizeFactor: _sizeFactor,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    for (final item in restItems)
                      RepaintBoundary(
                        child: _VergangeneAnfrageCard(
                          fahrt: item.fahrt!,
                          eventDatum:
                              widget.eventDatumCache[item.fahrt!.eventId] ??
                                  DateTime(2000),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        // Expand-Button
        if (hasMore)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: GestureDetector(
              onTap: _toggle,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotationTransition(
                      turns: _iconTurns,
                      child: const Icon(
                        Icons.expand_more,
                        size: 15,
                        color: _grey,
                      ),
                    ),
                    const SizedBox(width: 5),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _expanded
                            ? 'Weniger anzeigen'
                            : '+ ${items.length - _kInitialCount} weitere',
                        key: ValueKey(_expanded),
                        style: const TextStyle(
                          color: _grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VergangeneAnfrageCard extends StatelessWidget {
  final FahrtDaten fahrt;
  final DateTime eventDatum;

  const _VergangeneAnfrageCard({
    required this.fahrt,
    required this.eventDatum,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Opacity(
        opacity: 0.88,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: _InaktivStyles.cardDecoration(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Eventname + Datum
                  GestureDetector(
                    onTap: () {
                      final es = context.read<EventService>();
                      final event = es.events.firstWhere(
                        (e) => e.id == fahrt.eventId,
                        orElse: () => Event(
                          name: fahrt.eventName,
                          datum: eventDatum,
                          standort: fahrt.standort,
                          beschreibung: '',
                          typ: '',
                          adresse: '',
                        ),
                      );
                      _showEventInfoDialog(context, event);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fahrt.eventName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (eventDatum.year != 2000) ...[
                          const SizedBox(height: 1),
                          Text(
                            DateFormat('dd. MMMM yyyy', 'de')
                                .format(eventDatum),
                            style: const TextStyle(
                                color: Color(0x73FFFFFF), fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(
                      color: Color(0x1AFFFFFF),
                      thickness: 1,
                      height: 12),
                  // Fahrerprofil
                  _FahrerProfilRow(
                    userId: fahrt.ownerId,
                    name: fahrt.ownerName,
                    nameFarbe: Colors.white70,
                    chevronFarbe: Colors.white38,
                    avatarBg: _InaktivStyles.fahrerAvatarBg,
                    avatarRadius: 15,
                  ),
                  // Bewertungs-CTA
                  _ReviewPrompt(
                    fahrtId: fahrt.id,
                    reviewedId: fahrt.ownerId,
                    reviewedName: fahrt.ownerName,
                    reviewedPhotoUrl: null,
                    eventDatum: eventDatum,
                    showReviewedStatus: true,
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vergangene Fahrten — Fahrer-Tab
// ─────────────────────────────────────────────────────────────────────────────

class _VergangeneGlassSection extends StatefulWidget {
  final List<FahrtDaten> fahrten;
  final Map<String, DateTime> datumCache;

  const _VergangeneGlassSection({
    required this.fahrten,
    required this.datumCache,
  });

  @override
  State<_VergangeneGlassSection> createState() =>
      _VergangeneGlassSectionState();
}

class _VergangeneGlassSectionState extends State<_VergangeneGlassSection>
    with SingleTickerProviderStateMixin {
  static const _kInitialCount = 2;
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _iconTurns;

  static const _grey = Colors.white38;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _sizeFactor =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final fahrten = widget.fahrten;
    final hasMore = fahrten.length > _kInitialCount;
    final restFahrten = fahrten.skip(_kInitialCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section-Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                    color: Colors.white.withValues(alpha: 0.25), thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: const [
                    Icon(Icons.history, size: 13, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'VERGANGENE FAHRTEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Divider(
                    color: Colors.white.withValues(alpha: 0.25), thickness: 1),
              ),
            ],
          ),
        ),
        // Immer sichtbare Karten
        for (var i = 0; i < fahrten.length.clamp(0, _kInitialCount); i++)
          RepaintBoundary(
            child: _VergangeneGlassCard(
              fahrt: fahrten[i],
              eventDatum: widget.datumCache[fahrten[i].eventId] ?? DateTime(2000),
            ),
          ),
        // Ausklappbare Karten
        if (restFahrten.isNotEmpty)
          ClipRect(
            child: SizeTransition(
              sizeFactor: _sizeFactor,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    for (final fahrt in restFahrten)
                      RepaintBoundary(
                        child: _VergangeneGlassCard(
                          fahrt: fahrt,
                          eventDatum:
                              widget.datumCache[fahrt.eventId] ?? DateTime(2000),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        // Expand-Button
        if (hasMore)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: GestureDetector(
              onTap: _toggle,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotationTransition(
                      turns: _iconTurns,
                      child: const Icon(
                        Icons.expand_more,
                        size: 15,
                        color: _grey,
                      ),
                    ),
                    const SizedBox(width: 5),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _expanded
                            ? 'Weniger anzeigen'
                            : '+ ${fahrten.length - _kInitialCount} weitere',
                        key: ValueKey(_expanded),
                        style: const TextStyle(
                          color: _grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VergangeneGlassCard extends StatelessWidget {
  final FahrtDaten fahrt;
  final DateTime eventDatum;

  const _VergangeneGlassCard({
    required this.fahrt,
    required this.eventDatum,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Opacity(
        opacity: 0.88,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: _InaktivStyles.cardDecoration(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Eventname + Datum
                  GestureDetector(
                    onTap: () {
                      final es = context.read<EventService>();
                      final event = es.events.firstWhere(
                        (e) => e.id == fahrt.eventId,
                        orElse: () => Event(
                          name: fahrt.eventName,
                          datum: eventDatum,
                          standort: fahrt.standort,
                          beschreibung: '',
                          typ: '',
                          adresse: '',
                        ),
                      );
                      _showEventInfoDialog(context, event);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fahrt.eventName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (eventDatum.year != 2000) ...[
                          const SizedBox(height: 1),
                          Text(
                            DateFormat('dd. MMMM yyyy', 'de')
                                .format(eventDatum),
                            style: const TextStyle(
                                color: Color(0x73FFFFFF), fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(
                      color: Color(0x1AFFFFFF),
                      thickness: 1,
                      height: 12),
                  // Anfragen-Link (klein, kein voller Button)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        AppRoute(
                          builder: (_) => FahrtAnfragenPage(fahrt: fahrt, istVergangen: true),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 13, color: Colors.white30),
                          SizedBox(width: 4),
                          Text(
                            'Anfragen ansehen',
                            style:
                                TextStyle(color: Colors.white30, fontSize: 12),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right,
                              size: 14, color: Colors.white24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }
}
