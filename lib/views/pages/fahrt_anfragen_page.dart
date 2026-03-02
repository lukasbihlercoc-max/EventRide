import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/fahrt_service.dart';
import 'package:my_app/data/chat_service.dart';

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
            title: const Text("Anfragen zu deiner Fahrt"),
          ),
          body: Consumer<AnfrageService>(
            builder: (context, anfrageService, _) {
              final anfragen =
                  anfrageService.getAnfragenForFahrt(fahrt.id);

              if (anfragen.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Noch keine Anfragen für diese Fahrt",
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

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: anfragen.length,
                itemBuilder: (context, index) {
                  return _AnfrageCard(
                    anfrage: anfragen[index],
                    fahrt: fahrt,
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

    _acceptedSeats = widget.anfrage.seatsRequested
    .clamp(1, freie > 0 ? freie : 1);

  }

  Future<void> _openChat(BuildContext context) async {
    final chatService = context.read<ChatService>();
    final otherUserId = widget.anfrage.requesterId;

    final convo = await chatService.ensureConversation(
      fahrtId: widget.fahrt.id,
      ownerId: widget.fahrt.ownerId,
      requesterId: otherUserId,
      eventName: widget.fahrt.eventName,
      startOrt: widget.fahrt.abfahrtsort,
      zielOrt: widget.fahrt.standort,
      seatsRequested: widget.anfrage.seatsRequested,
    );


    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: convo.id,
          otherUserName: widget.anfrage.requesterName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.anfrage;

    return Card(
      color: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 12),
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
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                    ),
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
        // ✔ akzeptiert + Teilannahme
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

        // ✔ offen oder abgelehnt
        return Text(
          "${a.seatsRequested} Platz"
          "${a.seatsRequested > 1 ? 'e' : ''} angefragt",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
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
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                a.message!,
                style: const TextStyle(color: Colors.white),
              ),
            ],

            if (a.status == AnfrageStatus.offen) ...[
              const SizedBox(height: 12),

              const Text(
                "Plätze annehmen",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
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
                      fontWeight: FontWeight.bold,
                    ),
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
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  /// ❌ Ablehnen
                  TextButton.icon(
                    onPressed: () async {
                      await context.read<AnfrageService>().ablehnenAnfrage(a);
                    },
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    label: const Text(
                      "Ablehnen",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// ✅ Annehmen
                  TextButton.icon(
                    onPressed: () async {
                      final anfrageService = context.read<AnfrageService>();
                      final fahrtService = context.read<FahrtService>();
                      final chatService = context.read<ChatService>();

                      final aktuelleFahrt = fahrtService.alleFahrten.firstWhere(
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

                      final conversationId = chatService.buildConversationId(
                        fahrtId: widget.fahrt.id,
                        userA: widget.fahrt.ownerId,
                        userB: a.requesterId,
                      );


                      final updatedFahrt = aktuelleFahrt.copyWith(
                        freiePlaetze: freie - _acceptedSeats,
                      );

                      await fahrtService.update(updatedFahrt);

                      await chatService.updateSystemMessage(
                        conversationId: conversationId,
                        eventName: widget.fahrt.eventName,
                        startOrt: widget.fahrt.abfahrtsort,
                        zielOrt: widget.fahrt.standort,
                        seatsRequested: a.seatsRequested,
                        seatsAccepted: _acceptedSeats,
                      );



                    },
                    icon: const Icon(Icons.check, color: Colors.greenAccent),
                    label: const Text(
                      "Annehmen",
                      style: TextStyle(color: Colors.greenAccent),
                    ),
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
        color: Colors.white.withOpacity(0.15),
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
      color: color.withOpacity(0.7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}
