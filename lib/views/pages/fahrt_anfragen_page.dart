import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/utils/app_route.dart';
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
import 'package:my_app/views/widgets/fading_backdrop_filter.dart';
import 'package:my_app/data/chat_conversation.dart';
import 'package:my_app/views/pages/chat_page.dart';

class FahrtAnfragenPage extends StatelessWidget {
  final FahrtDaten fahrt;
  final bool istVergangen;

  const FahrtAnfragenPage({
    super.key,
    required this.fahrt,
    this.istVergangen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppBackground(child: Container()),
        Container(color: Colors.black.withValues(alpha: 0.4)),
        const FadingBackdropFilter(sigma: 8),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(istVergangen ? "Mitfahrer deiner Fahrt" : "Anfragen zu deiner Fahrt"),
          ),
          body: Consumer3<AnfrageService, InteressentenService, FahrtService>(
            builder: (context, anfrageService, interessentenService, fahrtService, _) {
              final aktuelleFahrt = fahrtService.alleFahrten
                  .firstWhere((f) => f.id == fahrt.id, orElse: () => fahrt);
              final istVoll = aktuelleFahrt.freiePlaetze <= 0;
              final anfragen = anfrageService.getAnfragenForFahrt(fahrt.id);

              // Vergangene Fahrt: nur akzeptierte Mitfahrer anzeigen
              if (istVergangen) {
                final mitfahrer = anfragen
                    .where((a) => a.status == AnfrageStatus.akzeptiert)
                    .toList();

                final hatContent = mitfahrer.isNotEmpty;

                if (!hatContent) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sentiment_neutral,
                            size: 64, color: Colors.white38),
                        SizedBox(height: 16),
                        Text(
                          "Niemand ist mitgefahren",
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: mitfahrer.length,
                  itemBuilder: (context, index) => _AnfrageCard(
                    key: ValueKey(mitfahrer[index].id),
                    anfrage: mitfahrer[index],
                    fahrt: aktuelleFahrt,
                    conversation: null,
                    istVergangen: true,
                  ),
                );
              }

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

              final chatService = context.read<ChatService>();

              return StreamBuilder<List<ChatConversation>>(
                stream: chatService.conversationsStream(fahrt.ownerId),
                builder: (context, convoSnap) {
                  final convos = convoSnap.data ?? [];
                  final convoMap = {for (final c in convos) c.id: c};

                  ChatConversation? getConvo(AnfrageDaten a) =>
                      convoMap[chatService.buildConversationId(
                        fahrtId: fahrt.id,
                        userA: fahrt.ownerId,
                        userB: a.requesterId,
                      )];

                  int cmpUnread(AnfrageDaten a, AnfrageDaten b) {
                    final ua = getConvo(a)?.isUnreadFor(fahrt.ownerId) ?? false;
                    final ub = getConvo(b)?.isUnreadFor(fahrt.ownerId) ?? false;
                    return ua == ub ? 0 : (ua ? -1 : 1);
                  }

                  final sortedAkzeptierte = [...akzeptierte]..sort(cmpUnread);
                  final sortedRest = [...restlicheAnfragen]..sort(cmpUnread);

                  return CustomScrollView(
                    slivers: [
                      // ── Voll-Banner ──
                      if (istVoll)
                        SliverToBoxAdapter(child: _VollBanner()),

                      // ── Mitfahrer-Sektion (nur wenn Fahrt voll) ──
                      if (istVoll && sortedAkzeptierte.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: Colors.greenAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${sortedAkzeptierte.length} Mitfahrer',
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
                              key: ValueKey(sortedAkzeptierte[index].id),
                              anfrage: sortedAkzeptierte[index],
                              fahrt: aktuelleFahrt,
                              conversation: getConvo(sortedAkzeptierte[index]),
                            ),
                            childCount: sortedAkzeptierte.length,
                          ),
                        ),
                      ],

                      // ── Anfragen-Sektion ──
                      if (sortedRest.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                const Icon(Icons.mail_outline,
                                    color: Colors.white70, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${sortedRest.length} Anfrage'
                                  '${sortedRest.length == 1 ? '' : 'n'}',
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
                              key: ValueKey(sortedRest[index].id),
                              anfrage: sortedRest[index],
                              fahrt: aktuelleFahrt,
                              conversation: getConvo(sortedRest[index]),
                            ),
                            childCount: sortedRest.length,
                          ),
                        ),
                      ],

                      // ── Interessenten-Sektion (ausklappbar, nach Anfragen) ──
                      if (!istVoll && interessenten.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _KlappbareInteressentenSektion(
                            interessenten: interessenten,
                            fahrt: aktuelleFahrt,
                            anfrageService: anfrageService,
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
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

// ---------------------------------------------------------------------------
// Ausklappbare Interessenten-Sektion
// ---------------------------------------------------------------------------
class _KlappbareInteressentenSektion extends StatefulWidget {
  final List<InteressentenDaten> interessenten;
  final FahrtDaten fahrt;
  final AnfrageService anfrageService;

  const _KlappbareInteressentenSektion({
    required this.interessenten,
    required this.fahrt,
    required this.anfrageService,
  });

  @override
  State<_KlappbareInteressentenSektion> createState() =>
      _KlappbareInteressentenSektionState();
}

class _KlappbareInteressentenSektionState
    extends State<_KlappbareInteressentenSektion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dezenter Trenner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: const [
              Expanded(child: Divider(color: Colors.white12)),
            ],
          ),
        ),

        // Header (anklickbar)
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.emoji_people, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.interessenten.length} Interessent'
                    '${widget.interessenten.length == 1 ? '' : 'en'} ohne Fahrt',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.amber,
                ),
              ],
            ),
          ),
        ),

        // Liste (ausgeklappt)
        if (_expanded)
          ...widget.interessenten.map((i) => _InteressentCard(
                interessent: i,
                fahrt: widget.fahrt,
                anfrageService: widget.anfrageService,
              )),
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
                AppRoute(
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
                      TrustShieldsByUserId(userId: interessent.userId, size: 14),
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
        eventDatum: widget.fahrt.eventDatum,
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
// Anfrage-Card — Status-Strip Design
// ---------------------------------------------------------------------------
class _AnfrageCard extends StatefulWidget {
  final AnfrageDaten anfrage;
  final FahrtDaten fahrt;
  final ChatConversation? conversation;
  final bool istVergangen;

  const _AnfrageCard({
    super.key,
    required this.anfrage,
    required this.fahrt,
    this.conversation,
    this.istVergangen = false,
  });

  @override
  State<_AnfrageCard> createState() => _AnfrageCardState();
}

class _AnfrageCardState extends State<_AnfrageCard> {
  late int _acceptedSeats;
  bool _loading = false;

  static const _stripGreen  = Color(0xFF2FA56A);
  static const _stripRed    = Color(0xFFE05A64);
  static const _stripAmber  = Color(0xFFE0A83A);
  static const _chatAmber   = Color(0xFFF5A04A);

  @override
  void initState() {
    super.initState();
    final freie = widget.fahrt.freiePlaetze;
    _acceptedSeats =
        widget.anfrage.seatsRequested.clamp(1, freie > 0 ? freie : 1);
  }

  Color get _stripColor => switch (widget.anfrage.status) {
        AnfrageStatus.akzeptiert    => _stripGreen,
        AnfrageStatus.abgelehnt     => _stripRed,
        AnfrageStatus.offen         => _stripAmber,
        AnfrageStatus.storniert     => Colors.blueGrey,
        AnfrageStatus.fahrtGeloescht => Colors.deepOrange,
      };

  (String, Color) get _statusInfo => switch (widget.anfrage.status) {
        AnfrageStatus.offen          => ('Offen',         _stripAmber),
        AnfrageStatus.akzeptiert     => ('Akzeptiert',    _stripGreen),
        AnfrageStatus.abgelehnt      => ('Abgelehnt',     _stripRed),
        AnfrageStatus.storniert      => ('Storniert',     Colors.blueGrey),
        AnfrageStatus.fahrtGeloescht => ('Fahrt abgesagt',Colors.deepOrange),
      };

  String get _subtitle {
    final a = widget.anfrage;
    if (a.status == AnfrageStatus.akzeptiert) {
      final accepted = a.seatsAccepted ?? a.seatsRequested;
      return '$accepted/${a.seatsRequested} Platz${a.seatsRequested > 1 ? 'ätze' : ''}';
    }
    return '${a.seatsRequested} Platz${a.seatsRequested > 1 ? 'e' : ''} angefragt';
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
      AppRoute(
        builder: (_) => ChatPage(
          conversationId: conversationId,
          otherUserName: widget.anfrage.requesterName,
          otherUserId: widget.anfrage.requesterId,
        ),
      ),
    );
    chatService
        .ensureConversation(
          fahrtId: widget.fahrt.id,
          ownerId: widget.fahrt.ownerId,
          requesterId: widget.anfrage.requesterId,
          eventName: widget.fahrt.eventName,
          startOrt: widget.fahrt.abfahrtsort,
          zielOrt: widget.fahrt.standort,
          seatsRequested: widget.anfrage.seatsRequested,
        )
        .then((_) => chatService.updateSystemMessage(
              conversationId: conversationId,
              eventName: widget.fahrt.eventName,
              startOrt: widget.fahrt.abfahrtsort,
              zielOrt: widget.fahrt.standort,
              seatsRequested: widget.anfrage.seatsRequested,
              seatsAccepted: widget.anfrage.seatsAccepted ?? 0,
              uhrzeit:
                  '${widget.fahrt.uhrzeitHour.toString().padLeft(2, '0')}:${widget.fahrt.uhrzeitMinute.toString().padLeft(2, '0')}',
              richtung: switch (widget.fahrt.richtung) {
                Fahrtrichtung.hinfahrt      => 'Hinfahrt',
                Fahrtrichtung.rueckfahrt    => 'Rückfahrt',
                Fahrtrichtung.hinUndZurueck => 'Hin und Zurück',
              },
              ownerName: widget.fahrt.ownerName,
            ))
        .catchError((_) {});
  }

  Future<void> _handleAblehnen() async {
    setState(() => _loading = true);
    try {
      final chatService = context.read<ChatService>();
      final a = widget.anfrage;
      await context.read<AnfrageService>().ablehnenAnfrage(a);
      if (!mounted) return;
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
  }

  Future<void> _handleAnnehmen() async {
    final a = widget.anfrage;
    setState(() => _loading = true);
    try {
      final anfrageService      = context.read<AnfrageService>();
      final fahrtService        = context.read<FahrtService>();
      final chatService         = context.read<ChatService>();
      final interessentenService = context.read<InteressentenService>();

      final aktuelleFahrt = fahrtService.alleFahrten
          .firstWhere((f) => f.id == widget.fahrt.id, orElse: () => widget.fahrt);

      final freie = aktuelleFahrt.freiePlaetze;
      if (_acceptedSeats > freie) return;

      final ok = await anfrageService.akzeptiereAnfrage(
        anfrage: a,
        fahrt: aktuelleFahrt,
        seatsAccepted: _acceptedSeats,
      );
      if (!ok) return;

      await interessentenService.removeForUser(widget.fahrt.eventId, a.requesterId);

      final convo = await chatService.ensureConversation(
        fahrtId: widget.fahrt.id,
        ownerId: widget.fahrt.ownerId,
        requesterId: a.requesterId,
        eventName: widget.fahrt.eventName,
        startOrt: widget.fahrt.abfahrtsort,
        zielOrt: widget.fahrt.standort,
        seatsRequested: a.seatsRequested,
      );

      try {
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
            Fahrtrichtung.hinfahrt      => 'Hinfahrt',
            Fahrtrichtung.rueckfahrt    => 'Rückfahrt',
            Fahrtrichtung.hinUndZurueck => 'Hin und Zurück',
          },
          ownerName: widget.fahrt.ownerName,
        );
      } catch (_) {
        // System-Nachricht nicht kritisch – Anfrage wurde bereits angenommen.
      }

      if (!mounted) return;
      AppSnackbar.show(context, message: 'Anfrage angenommen');

      final newFreie = freie - _acceptedSeats;
      if (newFreie <= 0) {
        final offene = anfrageService
            .getAnfragenForFahrt(widget.fahrt.id)
            .where((x) => x.id != a.id && x.status == AnfrageStatus.offen)
            .toList();
        for (final offeneAnfrage in offene) {
          await anfrageService.ablehnenAnfrage(offeneAnfrage);
          if (!mounted) break;
          chatService.sendStatusNotification(
            fahrtId: widget.fahrt.id,
            ownerId: widget.fahrt.ownerId,
            requesterId: offeneAnfrage.requesterId,
            eventName: widget.fahrt.eventName,
            startOrt: widget.fahrt.abfahrtsort,
            zielOrt: widget.fahrt.standort,
            seatsRequested: offeneAnfrage.seatsRequested,
            text: 'Fahrt ist leider voll.',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a           = widget.anfrage;
    final isUnread    = widget.conversation?.isUnreadFor(widget.fahrt.ownerId) ?? false;
    final showDecision = a.status == AnfrageStatus.offen && !a.vonFahrer && !widget.istVergangen;
    final stripColor  = _stripColor;
    final (statusText, statusColor) = _statusInfo;

    final isStorniert = a.status == AnfrageStatus.storniert;

    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment(0.4, 1.0),
          colors: [Color(0xFF243353), Color(0xFF1F2C4A), Color(0xFF1B2742)],
          stops: [0.0, 0.6, 1.0],
        ),
        border: Border.all(
          color: showDecision
              ? _stripAmber.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          if (showDecision)
            BoxShadow(
              color: _stripAmber.withValues(alpha: 0.08),
              blurRadius: 0,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Stack(
        children: [
          // ── Inhalt ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 11, 12, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kopfzeile
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    UserAvatarById(
                      userId: a.requesterId,
                      name: a.requesterName,
                      radius: 21,
                      onTap: (url) => Navigator.push(
                        context,
                        AppRoute(
                          builder: (_) => PublicProfilePage(
                            userId: a.requesterId,
                            name: a.requesterName,
                            photoUrl: url,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  a.requesterName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              TrustShieldsByUserId(userId: a.requesterId, size: 10),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text: statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: ' · $_subtitle',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildChatButton(isUnread, context),
                  ],
                ),

                // Entscheidungsbereich (nur status == offen)
                if (showDecision)
                  Container(
                    margin: const EdgeInsets.only(top: 11),
                    padding: const EdgeInsets.only(top: 11),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stepper — nur bei mehr als 1 angefragtem Platz
                        if (a.seatsRequested > 1) ...[
                          Row(
                            children: [
                              Text(
                                'Plätze annehmen',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              _buildStepper(a),
                              const SizedBox(width: 8),
                              Text(
                                'von ${a.seatsRequested} angefragt',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 11),
                        ],

                        // Aktions-Buttons
                        Row(
                          children: [
                            _buildAblehnenBtn(),
                            const SizedBox(width: 8),
                            Expanded(child: _buildAnnehmenBtn(a)),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Status-Strip links ──
          Positioned(
            left: 0,
            top: 8,
            bottom: 8,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: stripColor,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: stripColor.withValues(alpha: 0.33),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return isStorniert ? Opacity(opacity: 0.45, child: card) : card;
  }

  Widget _buildChatButton(bool isUnread, BuildContext context) {
    return GestureDetector(
      onTap: () => _openChat(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnread
                  ? _chatAmber.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: isUnread
                    ? _chatAmber.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.22),
                width: isUnread ? 1.8 : 1.5,
              ),
              boxShadow: isUnread
                  ? [
                      BoxShadow(
                        color: _chatAmber.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.chat_bubble_rounded,
              size: 20,
              color: isUnread ? _chatAmber : Colors.white,
            ),
          ),
          if (isUnread)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _chatAmber.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepper(AnfrageDaten a) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniBtn(
            Icons.remove,
            _acceptedSeats > 1 ? () => setState(() => _acceptedSeats--) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$_acceptedSeats',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _chatAmber,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _miniBtn(
            Icons.add,
            _acceptedSeats >= a.seatsRequested
                ? null
                : () {
                    final freie = widget.fahrt.freiePlaetze;
                    if (_acceptedSeats >= freie) {
                      AppSnackbar.show(
                        context,
                        message: 'Nur noch $freie Platz${freie == 1 ? '' : 'e'} verfügbar',
                      );
                      return;
                    }
                    setState(() => _acceptedSeats++);
                  },
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 26,
        height: 26,
        child: Icon(
          icon,
          size: 15,
          color: onTap != null ? Colors.white : Colors.white38,
        ),
      ),
    );
  }

  Widget _buildAblehnenBtn() {
    return GestureDetector(
      onTap: _loading ? null : _handleAblehnen,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: _stripRed.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.close, size: 15,
                color: _loading ? Colors.white24 : const Color(0xFFE88891)),
            const SizedBox(width: 5),
            Text(
              'Ablehnen',
              style: TextStyle(
                color: _loading ? Colors.white24 : const Color(0xFFE88891),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnehmenBtn(AnfrageDaten a) {
    final label = a.seatsRequested > 1 ? '$_acceptedSeats annehmen' : 'Annehmen';
    return GestureDetector(
      onTap: _loading ? null : _handleAnnehmen,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          gradient: _loading
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF34B97A), Color(0xFF2A9D68)],
                ),
          color: _loading ? Colors.white12 : null,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _loading
              ? [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white54),
                  ),
                ]
              : [
                  const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
        ),
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
    case AnfrageStatus.fahrtGeloescht:
      return _chip("Fahrt abgesagt", Colors.deepOrange);
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
