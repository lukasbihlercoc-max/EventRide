import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/fahrt_service.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/chat_service.dart';
import 'package:my_app/data/seen_anfragen_service.dart';
import 'package:my_app/views/pages/login_page.dart';

import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/fahrtencard_widget.dart';
import 'package:my_app/views/pages/chat_page.dart';

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
                      const Icon(Icons.lock_outline, size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      const Text(
                        "Nicht angemeldet",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Melde dich an, um deine Fahrten zu verwalten.",
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
                        label: const Text("Anmelden"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
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

        return _LoggedInFahrtenView(
          key: ValueKey(user.userId),
          user: user,
        );
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
    if (!_tabController.indexIsChanging) {
      _markCurrentTabAsSeen();
    }
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
    final userId = widget.user.userId;

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

        final hasUnseenAngeboten =
            seenService.hasUnseenOwner(userId, ownerIds);
        final hasUnseenAngefragt =
            seenService.hasUnseenRequester(userId, requesterIds);

        return AppBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.amber,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    _tabLabel("Angeboten", hasUnseenAngeboten),
                    _tabLabel("Angefragt", hasUnseenAngefragt),
                  ],
                ),
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
      },
    );
  }
}

/// ------------------------------------------------------------
/// TAB 1 – deine angebotenen Fahrten
/// ------------------------------------------------------------
class _AngeboteneFahrtenTab extends StatelessWidget {
  final String userId;

  const _AngeboteneFahrtenTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Consumer<FahrtService>(
      builder: (context, fahrtService, _) {
        final meineFahrten = fahrtService.getFahrtenByUser(userId);

        if (meineFahrten.isEmpty) {
          return const _EmptyState(
            icon: Icons.directions_car_filled_outlined,
            title: "Noch keine Fahrten erstellt",
            subtitle: "Erstelle eine Fahrt,\num Mitfahrende zu finden.",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: meineFahrten.length,
          itemBuilder: (context, index) {
            return FahrtenCard(
              fahrt: meineFahrten[index],
              isEditable: true,
            );
          },
        );
      },
    );
  }
}

/// ------------------------------------------------------------
/// TAB 2 – Fahrten, bei denen du Mitfahrer bist
/// ------------------------------------------------------------
class _AngefragteFahrtenTab extends StatelessWidget {
  final String userId;

  const _AngefragteFahrtenTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AnfrageService, FahrtService>(
      builder: (context, anfrageService, fahrtService, _) {
        final anfragen = anfrageService.getAnfragenByRequester(userId);

        final fahrtMap = {for (final f in fahrtService.alleFahrten) f.id: f};
        final items = anfragen.map((a) => _RequestedRideItem(a, fahrtMap[a.fahrtId])).toList();

        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.chat_bubble_outline,
            title: "Noch keine Mitfahranfragen",
            subtitle: "Suche dir eine Fahrt aus\nund sende eine Anfrage.",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            if (item.fahrt == null) {
              return _RequestedRideDeletedCard(anfrage: item.anfrage);
            }

            return _RequestedRideCard(
              fahrt: item.fahrt!,
              anfrage: item.anfrage,
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
/// Card: angefragte Fahrt (MITFAHRER) + CHAT
/// ------------------------------------------------------------
class _RequestedRideCard extends StatelessWidget {
  final FahrtDaten fahrt;
  final AnfrageDaten anfrage;

  const _RequestedRideCard({
    required this.fahrt,
    required this.anfrage,
  });

  Color _statusColor(AnfrageStatus status) {
    switch (status) {
      case AnfrageStatus.offen:
        return Colors.blueAccent;
      case AnfrageStatus.akzeptiert:
        return Colors.greenAccent;
      case AnfrageStatus.abgelehnt:
        return Colors.redAccent;
    }
  }

  String _statusText(AnfrageStatus status) {
    switch (status) {
      case AnfrageStatus.offen:
        return "Offen";
      case AnfrageStatus.akzeptiert:
        return "Akzeptiert";
      case AnfrageStatus.abgelehnt:
        return "Abgelehnt";
    }
  }

  /// 🔑 CHAT ÖFFNEN (MITFAHRER → FAHRER)
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
    return Card(
      color: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Titel + Status + Chat
            Row(
              children: [
                Expanded(
                  child: Text(
                    fahrt.eventName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(anfrage.status).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusText(anfrage.status),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: Colors.white),
                  onPressed: () => _openChat(context),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// Plätze
            Row(
              children: [
                const Icon(Icons.event_seat,
                    size: 16, color: Colors.redAccent),
                const SizedBox(width: 6),
                Text(
                  anfrage.status == AnfrageStatus.akzeptiert &&
                          anfrage.seatsAccepted != null
                      ? "${anfrage.seatsAccepted} von ${anfrage.seatsRequested} Plätzen akzeptiert"
                      : "${anfrage.seatsRequested} Plätze angefragt",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),

            if (anfrage.message != null &&
                anfrage.message!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                "Deine Nachricht:",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                anfrage.message!,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ],
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
    return Card(
      color: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                  "${anfrage.startOrt} → ${anfrage.zielOrt}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              "Fahrt wurde gelöscht",
              style: TextStyle(
                color: Colors.redAccent.withOpacity(0.9),
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
