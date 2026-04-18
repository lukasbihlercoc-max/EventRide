import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/fahrt_service.dart';
import 'package:my_app/views/widgets/trust_shields_widget.dart';
import 'package:my_app/data/chat_service.dart';
import 'package:my_app/data/interessenten_daten.dart';
import 'package:my_app/data/interessenten_service.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/user_avatar_widget.dart';
import 'package:my_app/views/pages/public_profile_page.dart';

import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/pages/chat_page.dart';

class FahrtAnfragenPage extends StatelessWidget {
  final FahrtDaten fahrt;

  const FahrtAnfragenPage({
    super.key,
    required this.fahrt,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppBackground(child: Container()),
        Container(color: Colors.black.withValues(alpha: 0.4)),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(color: Colors.transparent),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("Anfragen zu deiner Fahrt"),
          ),
          body: Consumer3<AnfrageService, InteressentenService, FahrtService>(
            builder: (context, anfrageService, interessentenService, fahrtService, _) {
              final aktuelleFahrt = fahrtService.alleFahrten
                  .firstWhere((f) => f.id == fahrt.id, orElse: () => fahrt);
              final istVoll = aktuelleFahrt.freiePlaetze <= 0;
              final anfragen = anfrageService.getAnfragenForFahrt(fahrt.id);

              // Interessenten für dieses Event laden; Nutzer rausfiltern,
              // die bereits eine akzeptierte Anfrage für eine Fahrt dieses
              // Events beim gleichen Fahrer haben.
              final akzeptierteRequesterIds = anfrageService.alleAnfragen
                  .where((a) =>
                      a.eventId == fahrt.eventId &&
                      a.fahrtOwnerId == fahrt.ownerId &&
                      a.status == AnfrageStatus.akzeptiert)
                  .map((a) => a.requesterId)
                  .toSet();

              final interessenten = interessentenService
                  .getForEvent(fahrt.eventId)
                  .where((i) => !akzeptierteRequesterIds.contains(i.userId))
                  .toList();

              // Wenn Fahrt voll: akzeptierte separat anzeigen, Rest in normaler Liste
              final akzeptierte = istVoll
                  ? anfragen
                      .where((a) => a.status == AnfrageStatus.akzeptiert)
                      .toList()
                  : <AnfrageDaten>[];
              final restlicheAnfragen = istVoll
                  ? anfragen
                      .where((a) => a.status != AnfrageStatus.akzeptiert)
                      .toList()
                  : anfragen;

              final hatContent =
                  anfragen.isNotEmpty || interessenten.isNotEmpty;

              if (!hatContent) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Noch keine Anfragen oder Interessenten",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  // ── Voll-Banner ──
                  if (istVoll)
                    SliverToBoxAdapter(child: _VollBanner()),

                  // ── Mitfahrer-Sektion (nur wenn Fahrt voll) ──
                  if (istVoll && akzeptierte.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Colors.greenAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${akzeptierte.length} Mitfahrer',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _AnfrageCard(
                          anfrage: akzeptierte[index],
                          fahrt: aktuelleFahrt,
                        ),
                        childCount: akzeptierte.length,
                      ),
                    ),
                  ],

                  // ── Interessenten-Sektion (nur wenn noch Plätze frei) ──
                  if (!istVoll && interessenten.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_people,
                                color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${interessenten.length} Interessent'
                              '${interessenten.length == 1 ? '' : 'en'} ohne Fahrt',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _InteressentCard(
                          interessent: interessenten[index],
                          fahrt: aktuelleFahrt,
                          anfrageService: anfrageService,
                        ),
                        childCount: interessenten.length,
                      ),
                    ),
                  ],

                  // ── Anfragen-Sektion ──
                  if (restlicheAnfragen.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.mail_outline,
                                color: Colors.white70, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${restlicheAnfragen.length} Anfrage'
                              '${restlicheAnfragen.length == 1 ? '' : 'n'}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _AnfrageCard(
                          anfrage: restlicheAnfragen[index],
                          fahrt: aktuelleFahrt,
                        ),
                        childCount: restlicheAnfragen.length,
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Interessent-Card (Fahrer-Sicht): Avatar + Name + "Anfragen"-Button
// ---------------------------------------------------------------------------
class _InteressentCard extends StatelessWidget {
  final InteressentenDaten interessent;
  final FahrtDaten fahrt;
  final AnfrageService anfrageService;

  const _InteressentCard({
    required this.interessent,
    required this.fahrt,
    required this.anfrageService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            UserAvatarWidget(
              name: interessent.userName,
              photoUrl: interessent.userPhotoUrl,
              radius: 22,
              backgroundColor: Colors.amber.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicProfilePage(
                    userId: interessent.userId,
                    name: interessent.userName,
                    photoUrl: interessent.userPhotoUrl,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + Bezirk
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          interessent.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const TrustShields(filled: 1, size: 14),
                    ],
                  ),
                  if (interessent.bezirk != null &&
                      interessent.bezirk!.isNotEmpty)
                    Text(
                      interessent.bezirk!,
                      style: TextStyle(
                        color: Colors.amber.shade300,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),

            // "Anfragen"-Button
            _AnfragenButton(
              interessent: interessent,
              fahrt: fahrt,
              anfrageService: anfrageService,
            ),
          ],
        ),
      ),
    );
  }

}

class _AnfragenButton extends StatefulWidget {
  final InteressentenDaten interessent;
  final FahrtDaten fahrt;
  final AnfrageService anfrageService;

  const _AnfragenButton({
    required this.interessent,
    required this.fahrt,
    required this.anfrageService,
  });

  @override
  State<_AnfragenButton> createState() => _AnfragenButtonState();
}

class _AnfragenButtonState extends State<_AnfragenButton> {
  bool _loading = false;

  // Prüft ob bereits eine offene Anfrage vom Fahrer an diesen Interessenten
  // für diese Fahrt existiert (Anti-Spam).
  bool get _hatBereitsOffeneAnfrage {
    return widget.anfrageService
        .getAnfragenForFahrt(widget.fahrt.id)
        .any((a) =>
            a.requesterId == widget.interessent.userId &&
            a.status == AnfrageStatus.offen);
  }

  Future<void> _sendAnfrage() async {
    if (_loading || _hatBereitsOffeneAnfrage) return;
    setState(() => _loading = true);

    try {
      // Fahrer erstellt Anfrage an den Interessenten:
      // requesterId = Interessent, fahrtOwnerId = Fahrer
      final anfrage = AnfrageDaten.create(
        fahrtId: widget.fahrt.id,
        eventId: widget.fahrt.eventId,
        requesterId: widget.interessent.userId,
        requesterName: widget.interessent.userName,
        seatsRequested: 1,
        fahrtOwnerId: widget.fahrt.ownerId,
        eventName: widget.fahrt.eventName,
        startOrt: widget.fahrt.abfahrtsort,
        zielOrt: widget.fahrt.standort,
        fahrerName: widget.fahrt.ownerName,
        message: 'Ich habe noch einen Platz frei — möchtest du mitfahren?',
        vonFahrer: true,
      );

      await widget.anfrageService.addAnfrage(anfrage);

      if (mounted) {
        AppSnackbar.show(context,
            message: 'Anfrage an ${widget.interessent.userName} gesendet!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: 'Fehler beim Senden der Anfrage.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schonAngefragt = _hatBereitsOffeneAnfrage;

    if (_loading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.amber,
        ),
      );
    }

    if (schonAngefragt) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Angefragt',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _sendAnfrage,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: const Text('Anfragen'),
    );
  }
}

// ---------------------------------------------------------------------------
// Anfrage-Card (unverändert)
// ---------------------------------------------------------------------------
class _AnfrageCard extends StatefulWidget {
  final AnfrageDaten anfrage;
  final FahrtDaten fahrt;

  const _AnfrageCard({
    required this.anfrage,
    required this.fahrt,
  });

  @override
  State<_AnfrageCard> createState() => _AnfrageCardState();
}

class _AnfrageCardState extends State<_AnfrageCard> {
  late int _acceptedSeats;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final freie = widget.fahrt.freiePlaetze;
    _acceptedSeats =
        widget.anfrage.seatsRequested.clamp(1, freie > 0 ? freie : 1);
  }

  void _openChat(BuildContext context) {
    final chatService = context.read<ChatService>();

    final conversationId = chatService.buildConversationId(
      fahrtId: widget.fahrt.id,
      userA: widget.fahrt.ownerId,
      userB: widget.anfrage.requesterId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: conversationId,
          otherUserName: widget.anfrage.requesterName,
          otherUserId: widget.anfrage.requesterId,
        ),
      ),
    );

    chatService.ensureConversation(
      fahrtId: widget.fahrt.id,
      ownerId: widget.fahrt.ownerId,
      requesterId: widget.anfrage.requesterId,
      eventName: widget.fahrt.eventName,
      startOrt: widget.fahrt.abfahrtsort,
      zielOrt: widget.fahrt.standort,
      seatsRequested: widget.anfrage.seatsRequested,
    ).then((_) => chatService.updateSystemMessage(
      conversationId: conversationId,
      eventName: widget.fahrt.eventName,
      startOrt: widget.fahrt.abfahrtsort,
      zielOrt: widget.fahrt.standort,
      seatsRequested: widget.anfrage.seatsRequested,
      seatsAccepted: widget.anfrage.seatsAccepted ?? 0,
      uhrzeit:
          '${widget.fahrt.uhrzeitHour.toString().padLeft(2, '0')}:${widget.fahrt.uhrzeitMinute.toString().padLeft(2, '0')}',
      richtung: switch (widget.fahrt.richtung) {
        Fahrtrichtung.hinfahrt => 'Hinfahrt',
        Fahrtrichtung.rueckfahrt => 'Rückfahrt',
        Fahrtrichtung.hinUndZurueck => 'Hin und Zurück',
      },
      ownerName: widget.fahrt.ownerName,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.anfrage;

    return Card(
      color: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          a.requesterName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const TrustShields(filled: 1, size: 15),
                    ],
                  ),
                ),
                buildStatusChip(a.status),
                if (a.status != AnfrageStatus.abgelehnt)
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: Colors.white),
                    onPressed: () => _openChat(context),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.event_seat, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Builder(
                  builder: (_) {
                    if (a.status == AnfrageStatus.akzeptiert &&
                        a.seatsAccepted != null) {
                      return Text(
                        "${a.seatsAccepted} von ${a.seatsRequested} Platz"
                        "${a.seatsRequested > 1 ? 'en' : ''} akzeptiert",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                    return Text(
                      "${a.seatsRequested} Platz"
                      "${a.seatsRequested > 1 ? 'e' : ''} angefragt",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 16),
                    );
                  },
                ),
              ],
            ),

            if (a.message != null && a.message!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                "Nachricht:",
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(a.message!,
                  style: const TextStyle(color: Colors.white)),
            ],

            if (a.status == AnfrageStatus.offen && !a.vonFahrer) ...[
              const SizedBox(height: 12),
              const Text(
                "Plätze annehmen",
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),

              Row(
                children: [
                  _seatButton(
                    icon: Icons.remove,
                    onTap: _acceptedSeats > 1
                        ? () => setState(() => _acceptedSeats--)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "$_acceptedSeats",
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  _seatButton(
                    icon: Icons.add,
                    onTap: _acceptedSeats >= a.seatsRequested
                        ? null
                        : () {
                            final freie = widget.fahrt.freiePlaetze;
                            if (_acceptedSeats >= freie) {
                              AppSnackbar.show(context,
                                  message:
                                      'Nur noch $freie Platz${freie == 1 ? '' : 'e'} verfügbar');
                              return;
                            }
                            setState(() => _acceptedSeats++);
                          },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "von ${a.seatsRequested} angefragt",
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _loading
                        ? null
                        : () async {
                            setState(() => _loading = true);
                            try {
                              final chatService = context.read<ChatService>();
                              await context
                                  .read<AnfrageService>()
                                  .ablehnenAnfrage(a);
                              if (!mounted) return;
                              // Benachrichtigung im Chat senden (fire-and-forget)
                              chatService.sendStatusNotification(
                                fahrtId: widget.fahrt.id,
                                ownerId: widget.fahrt.ownerId,
                                requesterId: a.requesterId,
                                eventName: widget.fahrt.eventName,
                                startOrt: widget.fahrt.abfahrtsort,
                                zielOrt: widget.fahrt.standort,
                                seatsRequested: a.seatsRequested,
                                text: 'Deine Anfrage wurde leider abgelehnt.',
                              );
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          },
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    label: const Text("Ablehnen",
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _loading
                        ? null
                        : () async {
                            setState(() => _loading = true);
                            try {
                              final anfrageService =
                                  context.read<AnfrageService>();
                              final fahrtService =
                                  context.read<FahrtService>();
                              final chatService = context.read<ChatService>();
                              final interessentenService =
                                  context.read<InteressentenService>();

                              final aktuelleFahrt =
                                  fahrtService.alleFahrten.firstWhere(
                                (f) => f.id == widget.fahrt.id,
                                orElse: () => widget.fahrt,
                              );

                              final freie = aktuelleFahrt.freiePlaetze;
                              if (_acceptedSeats > freie) return;

                              final ok = await anfrageService.akzeptiereAnfrage(
                                anfrage: a,
                                fahrt: aktuelleFahrt,
                                seatsAccepted: _acceptedSeats,
                              );

                              if (!ok) return;

                              // Interessent aus Warteliste entfernen
                              await interessentenService.removeForUser(
                                widget.fahrt.eventId,
                                a.requesterId,
                              );

                              final convo =
                                  await chatService.ensureConversation(
                                fahrtId: widget.fahrt.id,
                                ownerId: widget.fahrt.ownerId,
                                requesterId: a.requesterId,
                                eventName: widget.fahrt.eventName,
                                startOrt: widget.fahrt.abfahrtsort,
                                zielOrt: widget.fahrt.standort,
                                seatsRequested: a.seatsRequested,
                              );

                              final updatedFahrt = aktuelleFahrt.copyWith(
                                freiePlaetze: freie - _acceptedSeats,
                              );
                              await fahrtService.update(updatedFahrt);

                              await chatService.updateSystemMessage(
                                conversationId: convo.id,
                                eventName: widget.fahrt.eventName,
                                startOrt: widget.fahrt.abfahrtsort,
                                zielOrt: widget.fahrt.standort,
                                seatsRequested: a.seatsRequested,
                                seatsAccepted: _acceptedSeats,
                                uhrzeit:
                                    '${widget.fahrt.uhrzeitHour.toString().padLeft(2, '0')}:${widget.fahrt.uhrzeitMinute.toString().padLeft(2, '0')}',
                                richtung: switch (widget.fahrt.richtung) {
                                  Fahrtrichtung.hinfahrt => 'Hinfahrt',
                                  Fahrtrichtung.rueckfahrt => 'Rückfahrt',
                                  Fahrtrichtung.hinUndZurueck =>
                                    'Hin und Zurück',
                                },
                                ownerName: widget.fahrt.ownerName,
                              );

                              if (!context.mounted) return;
                              AppSnackbar.show(context,
                                  message: 'Anfrage angenommen');

                              // Wenn Fahrt jetzt voll: alle offenen Anfragen auto-ablehnen
                              final newFreie = freie - _acceptedSeats;
                              if (newFreie <= 0) {
                                final offene = anfrageService
                                    .getAnfragenForFahrt(widget.fahrt.id)
                                    .where((x) =>
                                        x.id != a.id &&
                                        x.status == AnfrageStatus.offen)
                                    .toList();
                                for (final offeneAnfrage in offene) {
                                  await anfrageService
                                      .ablehnenAnfrage(offeneAnfrage);
                                  if (!mounted) break;
                                  chatService.sendStatusNotification(
                                    fahrtId: widget.fahrt.id,
                                    ownerId: widget.fahrt.ownerId,
                                    requesterId: offeneAnfrage.requesterId,
                                    eventName: widget.fahrt.eventName,
                                    startOrt: widget.fahrt.abfahrtsort,
                                    zielOrt: widget.fahrt.standort,
                                    seatsRequested:
                                        offeneAnfrage.seatsRequested,
                                    text: 'Fahrt ist leider voll.',
                                  );
                                }
                              }
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          },
                    icon: const Icon(Icons.check, color: Colors.greenAccent),
                    label: const Text("Annehmen",
                        style: TextStyle(color: Colors.greenAccent)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _seatButton({required IconData icon, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Voll-Banner
// ---------------------------------------------------------------------------
class _VollBanner extends StatelessWidget {
  const _VollBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fahrt ist voll',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Alle Plätze sind vergeben.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildStatusChip(AnfrageStatus status) {
  switch (status) {
    case AnfrageStatus.offen:
      return _chip("Offen", Colors.blueAccent);
    case AnfrageStatus.akzeptiert:
      return _chip("Akzeptiert", Colors.green);
    case AnfrageStatus.abgelehnt:
      return _chip("Abgelehnt", Colors.red);
    case AnfrageStatus.storniert:
      return _chip("Storniert", Colors.blueGrey);
  }
}

Widget _chip(String text, Color color) {
  return Container(
    margin: const EdgeInsets.only(left: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}
