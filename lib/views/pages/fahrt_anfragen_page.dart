import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/fahrt_service.dart';
import 'package:my_app/data/chat_service.dart';
import 'package:my_app/data/interessenten_daten.dart';
import 'package:my_app/data/interessenten_service.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';

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
          body: Consumer2<AnfrageService, InteressentenService>(
            builder: (context, anfrageService, interessentenService, _) {
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
                  // ── Interessenten-Sektion ──
                  if (interessenten.isNotEmpty) ...[
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
                          fahrt: fahrt,
                          anfrageService: anfrageService,
                        ),
                        childCount: interessenten.length,
                      ),
                    ),
                  ],

                  // ── Anfragen-Sektion ──
                  if (anfragen.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            16, interessenten.isNotEmpty ? 16 : 16, 16, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.mail_outline,
                                color: Colors.white70, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${anfragen.length} Anfrage'
                              '${anfragen.length == 1 ? '' : 'n'}',
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
                          anfrage: anfragen[index],
                          fahrt: fahrt,
                        ),
                        childCount: anfragen.length,
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
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.amber.shade700,
              child: Text(
                _initials(interessent.userName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + Bezirk
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    interessent.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
    );
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
                  child: Text(
                    a.requesterName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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

            if (a.status == AnfrageStatus.offen) ...[
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
                    onTap: _acceptedSeats < a.seatsRequested
                        ? () => setState(() => _acceptedSeats++)
                        : null,
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
                    onPressed: () async {
                      await context.read<AnfrageService>().ablehnenAnfrage(a);
                    },
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    label: const Text("Ablehnen",
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () async {
                      final anfrageService = context.read<AnfrageService>();
                      final fahrtService = context.read<FahrtService>();
                      final chatService = context.read<ChatService>();

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

                      final convo = await chatService.ensureConversation(
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
                      );
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

Widget buildStatusChip(AnfrageStatus status) {
  switch (status) {
    case AnfrageStatus.offen:
      return _chip("Offen", Colors.blueAccent);
    case AnfrageStatus.akzeptiert:
      return _chip("Akzeptiert", Colors.green);
    case AnfrageStatus.abgelehnt:
      return _chip("Abgelehnt", Colors.red);
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
