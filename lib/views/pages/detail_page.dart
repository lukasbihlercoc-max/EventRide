// detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // Für ImageFilter.blur
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/chat_service.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/fahrt_service.dart';
import 'package:my_app/data/interessenten_service.dart';
import 'package:my_app/data/interessenten_daten.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/views/pages/events_page.dart';
import 'package:my_app/views/pages/fahrt_anbieten_page.dart';
import 'package:my_app/views/pages/chat_page.dart';
import 'package:my_app/views/pages/fahrt_finden_page.dart';
import 'package:my_app/views/auth/auth_guard.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/fahrtencard_widget/interessenten_bottom_sheet.dart';

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
                          SizedBox(height: height * 0.013),
                          _InteressentenInline(
                              event: event, width: width, height: height),
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
                                    if (context
                                        .read<IAuthRepository>()
                                        .isAdmin)
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
                padding: EdgeInsets.fromLTRB(
                  width * 0.064,
                  0,
                  width * 0.064,
                  height * 0.016,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // PRIMARY: Fahrten finden
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
                        padding:
                            EdgeInsets.symmetric(vertical: height * 0.020),
                      ),
                    ),
                    SizedBox(height: height * 0.010),
                    // SECONDARY: Fahrt anbieten (outlined, kleiner)
                    OutlinedButton.icon(
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
                          size: width * 0.038),
                      label: Text("Fahrt anbieten",
                          style: TextStyle(fontSize: width * 0.038)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.lightBlueAccent,
                        side: BorderSide(
                          color: Colors.lightBlueAccent
                              .withValues(alpha: 0.55),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: height * 0.013),
                      ),
                    ),
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
// Interessenten — inline social proof (below address, above divider)
// ---------------------------------------------------------------------------
class _InteressentenInline extends StatefulWidget {
  const _InteressentenInline({
    required this.event,
    required this.width,
    required this.height,
  });

  final Event event;
  final double width;
  final double height;

  @override
  State<_InteressentenInline> createState() => _InteressentenInlineState();
}

class _InteressentenInlineState extends State<_InteressentenInline>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _pressed = false;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final interessentenService = context.watch<InteressentenService>();
    final currentUser = context.read<IAuthRepository>().currentUser;
    final interessenten = interessentenService.getForEvent(widget.event.id);
    final count = interessenten.length;

    // ── Nicht eingeloggt ──
    if (currentUser == null) {
      return _shell(
        bgColor: Colors.white.withValues(alpha: 0.06),
        borderColor: Colors.white.withValues(alpha: 0.08),
        child: _inlineRow(
          interessenten: interessenten,
          mainText: count == 0
              ? 'Noch keiner eingetragen'
              : count == 1
                  ? '1 will hin'
                  : '$count wollen hin',
          subText: 'Tippe um dich einzutragen',
          right: GestureDetector(
            onTap: () => requiresLogin(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.amber.withValues(alpha: 0.2),
              ),
              child: const Text(
                'Ich will hin',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final fahrtService = context.watch<FahrtService>();
    final anfrageService = context.watch<AnfrageService>();

    // ── PRIORITÄT 1: Akzeptierte Anfrage ──
    final hatAkzeptierteAnfrage = anfrageService.alleAnfragen.any((a) =>
        a.eventId == widget.event.id &&
        a.requesterId == currentUser.userId &&
        a.status == AnfrageStatus.akzeptiert);

    if (hatAkzeptierteAnfrage) {
      return _shell(
        bgColor: Colors.white.withValues(alpha: 0.05),
        borderColor: Colors.white.withValues(alpha: 0.10),
        child: _inlineRow(
          interessenten: interessenten,
          mainText: 'Du hast eine Fahrt',
          mainTextColor: Colors.white38,
          subText: count > 0
              ? (count == 1
                  ? '1 weiterer will hin'
                  : '$count weitere wollen hin')
              : null,
          subTextColor: Colors.white38,
          right: const Icon(Icons.check_circle_outline,
              color: Colors.white24, size: 18),
        ),
      );
    }

    // ── PRIORITÄT 2: Offene Einladungen vom Fahrer ──
    final einladungen = anfrageService.alleAnfragen
        .where((a) =>
            a.eventId == widget.event.id &&
            a.requesterId == currentUser.userId &&
            a.vonFahrer &&
            a.status == AnfrageStatus.offen)
        .toList();

    if (einladungen.isNotEmpty) {
      final n = einladungen.length;
      return GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () => _showEinladungsSheet(context, einladungen, fahrtService),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.width * 0.04,
                vertical: widget.height * 0.012,
              ),
              decoration: BoxDecoration(
                color: Colors.amber
                    .withValues(alpha: 0.08 + 0.08 * _pulseAnim.value),
                borderRadius: BorderRadius.circular(widget.width * 0.03),
                border: Border.all(
                  color: Colors.amber
                      .withValues(alpha: 0.35 + 0.25 * _pulseAnim.value),
                ),
              ),
              child: _inlineRow(
                interessenten: interessenten,
                mainText: n == 1
                    ? 'Fahrer hat dich eingeladen'
                    : '$n Fahrer haben dich eingeladen',
                mainTextColor: Colors.amber.shade100,
                mainTextBold: true,
                subText: count > 0
                    ? (count == 1 ? '1 will hin' : '$count wollen hin')
                    : null,
                right: Icon(Icons.chevron_right,
                    color: Colors.amber.shade300, size: 20),
              ),
            ),
          ),
        ),
      );
    }

    // ── PRIORITÄT 3: Fahrer-Sicht ──
    final eigeneFahrt = fahrtService.alleFahrten
        .where((f) =>
            f.eventId == widget.event.id &&
            f.ownerId == currentUser.userId)
        .firstOrNull;

    if (eigeneFahrt != null) {
      return _shell(
        onTap: count > 0
            ? () => showInteressentenSheet(context, eigeneFahrt)
            : null,
        bgColor: Colors.white.withValues(alpha: 0.06),
        borderColor: count > 0
            ? Colors.amber.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.08),
        child: _inlineRow(
          interessenten: interessenten,
          mainText: count == 0
              ? 'Noch keiner eingetragen'
              : count == 1
                  ? '1 will hin'
                  : '$count wollen hin',
          subText: count > 0 ? 'Tippe um einzuladen' : null,
          right: count > 0
              ? Icon(Icons.chevron_right,
                  color: Colors.amber.shade300, size: 20)
              : null,
        ),
      );
    }

    // ── PRIORITÄT 4: Gast-Toggle ──
    final ichBinInteressiert = interessentenService.isInteressiert(
        widget.event.id, currentUser.userId);

    return _shell(
      bgColor: Colors.white.withValues(alpha: 0.06),
      borderColor: ichBinInteressiert
          ? Colors.amber.withValues(alpha: 0.35)
          : Colors.white.withValues(alpha: 0.08),
      child: _inlineRow(
        interessenten: interessenten,
        mainText: count == 0
            ? 'Noch keiner eingetragen'
            : count == 1
                ? '1 will hin'
                : '$count wollen hin',
        subText:
            ichBinInteressiert ? 'Du willst hin' : 'Tippe um dich einzutragen',
        right: ichBinInteressiert
            ? GestureDetector(
                onTap: _loading ? null : () => _toggle(currentUser),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: const Text(
                    'Abmelden',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ),
              )
            : GestureDetector(
                onTap: _loading ? null : () => _toggle(currentUser),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.amber.withValues(alpha: 0.2),
                  ),
                  child: const Text(
                    'Ich will hin',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _shell({
    required Widget child,
    required Color bgColor,
    required Color borderColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: widget.width * 0.04,
          vertical: widget.height * 0.012,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(widget.width * 0.03),
          border: Border.all(color: borderColor),
        ),
        child: child,
      ),
    );
  }

  Widget _inlineRow({
    required List<InteressentenDaten> interessenten,
    required String mainText,
    Color? mainTextColor,
    bool mainTextBold = false,
    String? subText,
    Color? subTextColor,
    Widget? right,
  }) {
    final count = interessenten.length;
    return Row(
      children: [
        if (count > 0)
          SizedBox(
            height: 26,
            width: 58,
            child: Stack(
              children:
                  interessenten.take(3).toList().asMap().entries.map((e) {
                final index = e.key;
                final user = e.value;
                return Positioned(
                  left: index * 16.0,
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.white24,
                    backgroundImage: user.userPhotoUrl != null
                        ? NetworkImage(user.userPhotoUrl!)
                        : null,
                    child: user.userPhotoUrl == null
                        ? Text(
                            user.userName.isNotEmpty
                                ? user.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 10),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          )
        else
          const Icon(Icons.people_outline, size: 18, color: Colors.white38),
        SizedBox(width: widget.width * 0.035),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mainText,
                style: TextStyle(
                  color: mainTextColor ?? Colors.white,
                  fontSize: 13.5,
                  fontWeight: mainTextBold ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              if (subText != null)
                Text(
                  subText,
                  style: TextStyle(
                    color: subTextColor ?? Colors.white54,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        if (right != null) right,
      ],
    );
  }

  void _showEinladungsSheet(
    BuildContext context,
    List<AnfrageDaten> einladungen,
    FahrtService fahrtService,
  ) {
    FahrtDaten? fahrtFuer(AnfrageDaten e) => fahrtService.alleFahrten
        .where((f) => f.id == e.fahrtId)
        .firstOrNull;

    if (einladungen.length == 1) {
      final einladung = einladungen.first;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _EinladungsBottomSheet(
          einladung: einladung,
          fahrt: fahrtFuer(einladung),
          onChatPressed: () => _openChatFromSheet(context, einladung),
        ),
      );
    } else {
      final pairs = einladungen.map((e) => (e, fahrtFuer(e))).toList();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _EinladungenListSheet(
          einladungen: pairs,
          onChatPressed: (e) => _openChatFromSheet(context, e),
        ),
      );
    }
  }

  void _openChatFromSheet(BuildContext context, AnfrageDaten einladung) {
    final chatService = context.read<ChatService>();
    final conversationId = chatService.buildConversationId(
      fahrtId: einladung.fahrtId,
      userA: einladung.fahrtOwnerId,
      userB: einladung.requesterId,
    );
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => ChatPage(
          conversationId: conversationId,
          otherUserName: einladung.fahrerName,
          otherUserId: einladung.fahrtOwnerId,
        ),
      ),
    );

    final fahrt = context
        .read<FahrtService>()
        .alleFahrten
        .where((f) => f.id == einladung.fahrtId)
        .firstOrNull;

    chatService.ensureConversation(
      fahrtId: einladung.fahrtId,
      ownerId: einladung.fahrtOwnerId,
      requesterId: einladung.requesterId,
      eventName: einladung.eventName,
      startOrt: einladung.startOrt,
      zielOrt: einladung.zielOrt,
      seatsRequested: einladung.seatsRequested,
    ).then((_) {
      if (fahrt != null) {
        chatService.updateSystemMessage(
          conversationId: conversationId,
          eventName: fahrt.eventName,
          startOrt: fahrt.abfahrtsort,
          zielOrt: fahrt.standort,
          seatsRequested: einladung.seatsRequested,
          seatsAccepted: einladung.seatsAccepted ?? 0,
          uhrzeit:
              '${fahrt.uhrzeitHour.toString().padLeft(2, '0')}:${fahrt.uhrzeitMinute.toString().padLeft(2, '0')}',
          richtung: switch (fahrt.richtung) {
            Fahrtrichtung.hinfahrt => 'Hinfahrt',
            Fahrtrichtung.rueckfahrt => 'Rückfahrt',
            Fahrtrichtung.hinUndZurueck => 'Hin und Zurück',
          },
          ownerName: fahrt.ownerName,
        );
      }
    });
  }

  Future<void> _toggle(AppUser currentUser) async {
    final bezirk = await context.read<IAuthRepository>().getHomeTown();
    if (!context.mounted) return;
    setState(() => _loading = true);
    try {
      final eingetragen = await context.read<InteressentenService>().toggle(
            eventId: widget.event.id,
            userId: currentUser.userId,
            userName: currentUser.name,
            userPhotoUrl: currentUser.photoUrl,
            bezirk: bezirk,
          );
      if (mounted) {
        AppSnackbar.show(
          context,
          message: eingetragen
              ? 'Du wurdest als Interessent eingetragen!'
              : 'Interesse zurückgezogen.',
        );
      }
    } catch (e) {
      debugPrint('[Toggle] FEHLER: $e');
      if (mounted) AppSnackbar.show(context, message: 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheet — Fahrer-Einladung annehmen oder ablehnen
// ---------------------------------------------------------------------------
class _EinladungsBottomSheet extends StatefulWidget {
  const _EinladungsBottomSheet({
    required this.einladung,
    required this.onChatPressed,
    this.fahrt,
  });

  final AnfrageDaten einladung;
  final FahrtDaten? fahrt;
  final VoidCallback onChatPressed;

  @override
  State<_EinladungsBottomSheet> createState() =>
      _EinladungsBottomSheetState();
}

class _EinladungsBottomSheetState extends State<_EinladungsBottomSheet> {
  bool _loading = false;
  bool _angenommen = false;

  Future<void> _annehmen() async {
    setState(() => _loading = true);
    final anfrageService = context.read<AnfrageService>();
    final fahrtService = context.read<FahrtService>();
    final interessentenService = context.read<InteressentenService>();
    final currentUser = context.read<IAuthRepository>().currentUser;

    final aktuelleFahrt = fahrtService.alleFahrten
            .where((f) => f.id == widget.einladung.fahrtId)
            .firstOrNull ??
        widget.fahrt;

    if (aktuelleFahrt == null || aktuelleFahrt.freiePlaetze <= 0) {
      if (mounted) {
        AppSnackbar.show(context, message: 'Leider keine freien Plätze mehr.');
        setState(() => _loading = false);
      }
      return;
    }

    final ok = await anfrageService.akzeptiereAnfrage(
      anfrage: widget.einladung,
      fahrt: aktuelleFahrt,
      seatsAccepted: 1,
    );

    if (!ok || !mounted) {
      setState(() => _loading = false);
      return;
    }

    await fahrtService.update(
      aktuelleFahrt.copyWith(freiePlaetze: aktuelleFahrt.freiePlaetze - 1),
    );

    if (currentUser != null) {
      await interessentenService.removeForUser(
          widget.einladung.eventId, currentUser.userId);
    }

    if (mounted) setState(() { _loading = false; _angenommen = true; });
  }

  Future<void> _ablehnen() async {
    setState(() => _loading = true);
    final chatService = context.read<ChatService>();
    await context.read<AnfrageService>().ablehnenAnfrage(widget.einladung);
    if (!mounted) return;
    chatService.sendStatusNotification(
      fahrtId: widget.einladung.fahrtId,
      ownerId: widget.einladung.fahrtOwnerId,
      requesterId: widget.einladung.requesterId,
      eventName: widget.einladung.eventName,
      startOrt: widget.einladung.startOrt,
      zielOrt: widget.einladung.zielOrt,
      seatsRequested: widget.einladung.seatsRequested,
      text: 'Einladung wurde abgelehnt.',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A2744),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          if (_angenommen)
            ..._buildSuccessContent()
          else
            ..._buildInviteContent(),
        ],
      ),
    );
  }

  List<Widget> _buildInviteContent() {
    final fahrt = widget.fahrt;
    final uhrzeit = fahrt?.uhrzeit.format(context);

    return [
      Row(
        children: [
          Icon(Icons.mail_outline, color: Colors.amber.shade300, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Einladung von ${widget.einladung.fahrerName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            _detailRow(Icons.location_on, 'Von', widget.einladung.startOrt),
            const Divider(color: Colors.white12, height: 16),
            _detailRow(Icons.flag, 'Nach', widget.einladung.zielOrt),
            if (uhrzeit != null) ...[
              const Divider(color: Colors.white12, height: 16),
              _detailRow(Icons.access_time, 'Abfahrt', uhrzeit),
            ],
            if (fahrt != null) ...[
              const Divider(color: Colors.white12, height: 16),
              _detailRow(
                  Icons.event_seat, 'Freie Plätze', '${fahrt.freiePlaetze}'),
            ],
          ],
        ),
      ),
      const SizedBox(height: 24),
      if (_loading)
        const Center(
          child: CircularProgressIndicator(
              color: Colors.amber, strokeWidth: 2),
        )
      else
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _ablehnen,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Ablehnen'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _annehmen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Annehmen',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
    ];
  }

  List<Widget> _buildSuccessContent() {
    return [
      Icon(Icons.check_circle_rounded,
          color: Colors.green.shade400, size: 56),
      const SizedBox(height: 12),
      const Text(
        'Fahrt angenommen!',
        style: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      const Text(
        'Schreib dem Fahrer, damit er Bescheid weiß.',
        style: TextStyle(color: Colors.white54, fontSize: 14),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            widget.onChatPressed();
          },
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Chat öffnen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Schließen',
            style: TextStyle(color: Colors.white38)),
      ),
    ];
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// List-Sheet — mehrere Fahrer-Einladungen auf einmal
// ---------------------------------------------------------------------------
class _EinladungenListSheet extends StatelessWidget {
  const _EinladungenListSheet({
    required this.einladungen,
    required this.onChatPressed,
  });

  final List<(AnfrageDaten, FahrtDaten?)> einladungen;
  final void Function(AnfrageDaten) onChatPressed;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A2744),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    Icon(Icons.mail_outline,
                        color: Colors.amber.shade300, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      '${einladungen.length} Einladungen',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: einladungen.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final (einladung, fahrt) = einladungen[i];
                    return _EinladungCard(
                      einladung: einladung,
                      fahrt: fahrt,
                      onChatPressed: () => onChatPressed(einladung),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Einzelne Einladungs-Karte innerhalb des List-Sheets
// ---------------------------------------------------------------------------
class _EinladungCard extends StatefulWidget {
  const _EinladungCard({
    required this.einladung,
    required this.onChatPressed,
    this.fahrt,
  });

  final AnfrageDaten einladung;
  final FahrtDaten? fahrt;
  final VoidCallback onChatPressed;

  @override
  State<_EinladungCard> createState() => _EinladungCardState();
}

class _EinladungCardState extends State<_EinladungCard> {
  bool _loading = false;
  bool _angenommen = false;
  bool _abgelehnt = false;

  Future<void> _annehmen() async {
    setState(() => _loading = true);
    final anfrageService = context.read<AnfrageService>();
    final fahrtService = context.read<FahrtService>();
    final interessentenService = context.read<InteressentenService>();
    final currentUser = context.read<IAuthRepository>().currentUser;

    final aktuelleFahrt = fahrtService.alleFahrten
            .where((f) => f.id == widget.einladung.fahrtId)
            .firstOrNull ??
        widget.fahrt;

    if (aktuelleFahrt == null || aktuelleFahrt.freiePlaetze <= 0) {
      if (mounted) {
        AppSnackbar.show(context, message: 'Leider keine freien Plätze mehr.');
        setState(() => _loading = false);
      }
      return;
    }

    final ok = await anfrageService.akzeptiereAnfrage(
      anfrage: widget.einladung,
      fahrt: aktuelleFahrt,
      seatsAccepted: 1,
    );

    if (!ok || !mounted) {
      setState(() => _loading = false);
      return;
    }

    await fahrtService.update(
      aktuelleFahrt.copyWith(freiePlaetze: aktuelleFahrt.freiePlaetze - 1),
    );

    if (currentUser != null) {
      await interessentenService.removeForUser(
          widget.einladung.eventId, currentUser.userId);
    }

    if (mounted) setState(() { _loading = false; _angenommen = true; });
  }

  Future<void> _ablehnen() async {
    setState(() => _loading = true);
    await context.read<AnfrageService>().ablehnenAnfrage(widget.einladung);
    if (mounted) setState(() { _loading = false; _abgelehnt = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (_abgelehnt) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.block, color: Colors.white24, size: 16),
            const SizedBox(width: 8),
            Text(
              'Einladung von ${widget.einladung.fahrerName} abgelehnt',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_angenommen) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.green.shade400, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fahrt bei ${widget.einladung.fahrerName} angenommen!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onChatPressed();
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Chat öffnen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.lightBlueAccent,
                  side: BorderSide(
                      color: Colors.lightBlueAccent.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final uhrzeit = widget.fahrt?.uhrzeit.format(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline,
                  color: Colors.amber.shade300, size: 18),
              const SizedBox(width: 6),
              Text(
                widget.einladung.fahrerName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row(Icons.location_on, widget.einladung.startOrt),
          const SizedBox(height: 4),
          _row(Icons.flag, widget.einladung.zielOrt),
          if (uhrzeit != null) ...[
            const SizedBox(height: 4),
            _row(Icons.access_time, uhrzeit),
          ],
          if (widget.fahrt != null) ...[
            const SizedBox(height: 4),
            _row(Icons.event_seat, '${widget.fahrt!.freiePlaetze} freie Plätze'),
          ],
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                  color: Colors.amber, strokeWidth: 2),
            )
          else
            Row(
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
                    ),
                    child: const Text('Ablehnen',
                        style: TextStyle(fontSize: 13)),
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
                    ),
                    child: const Text('Annehmen',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
