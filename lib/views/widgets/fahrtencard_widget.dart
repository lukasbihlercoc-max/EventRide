// fahrtencard_widget.dart
import 'package:flutter/material.dart';
import 'package:my_app/data/fahrt_anfrage_service.dart';
import 'package:my_app/data/fahrt_service.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';

import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/views/widgets/trust_shields_widget.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/views/pages/fahrt_anbieten_page.dart';
import 'package:my_app/views/pages/fahrt_anfragen_page.dart';
import 'package:my_app/views/pages/public_profile_page.dart';
import 'package:my_app/views/widgets/sizehelper_widget.dart';
import 'package:my_app/views/widgets/user_avatar_widget.dart';
import 'package:my_app/views/auth/auth_guard.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';

import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:my_app/views/pages/detail_page.dart';

String getBackgroundImage(Fahrtrichtung richtung) {
  switch (richtung) {
    case Fahrtrichtung.hinfahrt:
      return "assets/image/hinfahrt3.png";
    case Fahrtrichtung.rueckfahrt:
      return "assets/image/rueckfahrt5.png";
    case Fahrtrichtung.hinUndZurueck:
      return "assets/image/hinundrueck5.png";
  }
}

// Y-Wert pro Bild: -1.0 = ganz oben · 0.0 = Mitte · 1.0 = ganz unten
Alignment getBackgroundAlignment(Fahrtrichtung richtung) {
  switch (richtung) {
    case Fahrtrichtung.hinfahrt:
      return const Alignment(0.0, 0.7); // ← hier anpassen
    case Fahrtrichtung.rueckfahrt:
      return const Alignment(0.0, 1.0);  // ← hier anpassen
    case Fahrtrichtung.hinUndZurueck:
      return const Alignment(0.0, 0.85);  // ← hier anpassen
  }
}

/// Zeigt Event-Details als Glassmorphism-Dialog.
/// Wird von fahrt_finden_page.dart für den anklickbaren Header aufgerufen.
void showEventDetailsPopup(BuildContext context, Event event) {
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
                          DateFormat("dd.MM.yyyy").format(event.datum),
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
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white70, thickness: 1, height: 12),
                  const SizedBox(height: 12),
                  if (event.beschreibung.trim().isNotEmpty)
                    Text(
                      event.beschreibung,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "Schließen",
                          style: TextStyle(
                            color: Colors.lightBlueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
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


class FahrtenCard extends StatefulWidget {
  final FahrtDaten fahrt;
  final bool isEditable;
  final double? homeTownDistanceKm;

  const FahrtenCard({
    super.key,
    required this.fahrt,
    this.isEditable = false,
    this.homeTownDistanceKm,
  });

  @override
  State<FahrtenCard> createState() => _FahrtenCardState();
}

class _FahrtenCardState extends State<FahrtenCard> {
  final _pressed = ValueNotifier<bool>(false);

  // Getter damit alle bestehenden Methoden unverändert bleiben
  FahrtDaten get fahrt => widget.fahrt;
  bool get isEditable => widget.isEditable;

  @override
  void dispose() {
    _pressed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offeneAnfragenCount = context.select<AnfrageService, int>(
      (s) => s.offeneAnfragenProFahrt[fahrt.id] ?? 0,
    );

    return RepaintBoundary(
      child: ValueListenableBuilder<bool>(
        valueListenable: _pressed,
        builder: (_, pressed, child) => AnimatedScale(
          scale: pressed ? 0.975 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: child,
        ),
        child: GestureDetector(
          onTapDown: (_) => _pressed.value = true,
          onTapUp: (_) => _pressed.value = false,
          onTapCancel: () => _pressed.value = false,
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
                  children: [
                    // ── Hintergrundbild ──
                    Positioned.fill(
                      child: Image.asset(
                        getBackgroundImage(fahrt.richtung),
                        fit: BoxFit.cover,
                        alignment: getBackgroundAlignment(fahrt.richtung),
                        cacheWidth: 800,
                      ),
                    ),

                    // ── Dunkles Overlay ──
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                    ),

                    // ── Layout-Column (bestimmt Kartenhöhe) ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          child: _FahrerProfilBlock(
                            userId: fahrt.ownerId,
                            name: fahrt.ownerName,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.14),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: buildContent(context),
                        ),
                      ],
                    ),

                    // ── Icons oben rechts (nur editierbar) ──
                    if (isEditable)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 26,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                AppRoute(
                                  builder: (_) =>
                                      FahrtAnfragenPage(fahrt: fahrt),
                                ),
                              ),
                            ),
                            if (offeneAnfragenCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      offeneAnfragenCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
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

  Widget buildContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 390).clamp(0.82, 1.0);
    final routeFontSize = (screenWidth * 0.053).clamp(15.0, 20.0);

    final accentColor = switch (fahrt.richtung) {
      Fahrtrichtung.hinfahrt => Colors.greenAccent,
      Fahrtrichtung.rueckfahrt => Colors.orangeAccent,
      Fahrtrichtung.hinUndZurueck => Colors.blueAccent,
    };

    final richtungLabel = switch (fahrt.richtung) {
      Fahrtrichtung.hinfahrt => 'Hinfahrt',
      Fahrtrichtung.rueckfahrt => 'Rückfahrt',
      Fahrtrichtung.hinUndZurueck => 'Hin und Zurück',
    };

    final routeArrow = switch (fahrt.richtung) {
      Fahrtrichtung.hinfahrt =>
        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
      Fahrtrichtung.rueckfahrt =>
        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
      Fahrtrichtung.hinUndZurueck =>
        const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 24),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badges (Richtung + optional Voll)
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions, color: accentColor, size: 13 * scale),
                  const SizedBox(width: 4),
                  Text(
                    richtungLabel,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (fahrt.freiePlaetze == 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blueGrey),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_seat, color: Colors.blueGrey, size: 13 * scale),
                    const SizedBox(width: 4),
                    Text(
                      'Ausgebucht',
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.homeTownDistanceKm != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white38),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me_rounded, color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.homeTownDistanceKm! < 10 ? widget.homeTownDistanceKm!.toStringAsFixed(1) : widget.homeTownDistanceKm!.round()} km entfernt',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Route
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              fahrt.richtung == Fahrtrichtung.rueckfahrt
                  ? fahrt.standort
                  : fahrt.abfahrtsortAnzeige,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: routeFontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                routeArrow,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    fahrt.richtung == Fahrtrichtung.rueckfahrt
                        ? fahrt.abfahrtsortAnzeige
                        : fahrt.standort,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: routeFontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            const Icon(Icons.access_time,
                color: Color(0xFF94A3B8), size: 15),
            const SizedBox(width: 4),
            Text(
              fahrt.uhrzeit.format(context),
              style: TextStyle(
                  color: const Color(0xFF94A3B8), fontSize: 14 * scale),
            ),
            if (fahrt.richtung == Fahrtrichtung.hinUndZurueck &&
                fahrt.rueckuhrzeit != null) ...[
              const SizedBox(width: 18),
              const Icon(Icons.subdirectory_arrow_right_rounded,
                  color: Color(0xFF94A3B8), size: 15),
              const SizedBox(width: 4),
              Text(
                fahrt.rueckuhrzeit!.format(context),
                style: const TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 14),
              ),
            ],
            const Spacer(),
            if (fahrt.freiePlaetze > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_seat,
                        color: Colors.greenAccent, size: 13 * scale),
                    const SizedBox(width: 4),
                    Text(
                      '${fahrt.freiePlaetze} frei',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 6),

        buildButton(context),
      ],
    );
  }

  Widget buildButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 390).clamp(0.82, 1.0);

    final currentUid = context.read<IAuthRepository>().currentUser?.userId;
    if (currentUid != null && currentUid == fahrt.ownerId) {
      return const SizedBox.shrink();
    }

    if (isEditable) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _handleDelete(context),
            child: Text(
              'Löschen',
              style: TextStyle(fontSize: SizeHelper.w(context, 0.04)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _handleEdit(context),
            child: Text(
              'Bearbeiten',
              style: TextStyle(fontSize: SizeHelper.w(context, 0.04)),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _handleMitfahren(context),
      child: Container(
        height: 42 * scale,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.blueAccent.withValues(alpha: 0.95),
              Colors.blue.withValues(alpha: 0.69),
            ],
          ),
        ),
        child: Center(
          child: Text(
            'Mitfahren',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16 * scale,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }


  void _handleEdit(BuildContext context) {
    final event = Event(
      name: fahrt.eventName,
      standort: fahrt.standort,
      datum: DateTime.now(),
      beschreibung: '',
      typ: '',
      adresse: '',
    );

    Navigator.push(
      context,
      AppRoute(
        builder: (context) =>
            FahrtAnbietenPage(event: event, existingFahrt: fahrt),
      ),
    );
  }

  //! Mitfahr-Fenster

  void _handleMitfahren(BuildContext context) async {
    if (!await requiresLogin(context)) return;
    if (!context.mounted) return;

    final rideRequestService = context.read<RideRequestService>();
    final currentUser = context.read<IAuthRepository>().currentUser;
    if (currentUser == null) return;

    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final maxSeats = fahrt.freiePlaetze;
    int selectedSeats = 1;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.decelerate,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Material(
                    type: MaterialType.transparency,
                    child: StatefulBuilder(
                      builder: (ctxInner, setStateDialog) {
                        return Container(
                          width: size.width * 0.85,
                          padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          constraints: BoxConstraints(
                            maxHeight: size.height * 0.85,
                            minHeight: 200,
                          ),
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
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                        Icons.chat_bubble_outline,
                                        color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Mitfahranfrage senden",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            fahrt.eventName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            fahrt.standort,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Plätze",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.remove,
                                            color: Colors.white),
                                        onPressed: selectedSeats > 1
                                            ? () {
                                                setStateDialog(() {
                                                  selectedSeats--;
                                                });
                                              }
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      "$selectedSeats",
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.add,
                                            color: Colors.white),
                                        onPressed: selectedSeats < maxSeats
                                            ? () {
                                                setStateDialog(() {
                                                  selectedSeats++;
                                                });
                                              }
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "Max. $maxSeats verfügbar",
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Nachricht (optional)",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: messageController,
                                  style:
                                      const TextStyle(color: Colors.white),
                                  maxLines: 3,
                                  minLines: 3,
                                  autofocus: false,
                                  decoration: const InputDecoration(
                                    hintText:
                                        "z. B. Treffpunkt oder Info",
                                    hintStyle:
                                        TextStyle(color: Colors.white38),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.white24),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.lightBlueAccent),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text(
                                        "Abbrechen",
                                        style: TextStyle(
                                            color: Colors.white70),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx, true);
                                      },
                                      child: const Text(
                                        "Senden",
                                        style: TextStyle(
                                          color: Colors.lightBlueAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    final success = await rideRequestService.sendRequest(
      fahrt: fahrt,
      seats: selectedSeats,
      userId: currentUser.userId,
      userName: currentUser.name,
      message: messageController.text.trim().isEmpty
          ? null
          : messageController.text.trim(),
    );

    if (!context.mounted) return;
    if (!success) {
      AppSnackbar.show(context, message: "Du hast bereits angefragt!");
      return;
    }

    AppSnackbar.show(context, message: "Anfrage wurde gesendet");
  }

  void _handleDelete(BuildContext context) async {
    final fahrtService = Provider.of<FahrtService>(context, listen: false);
    final anfrageService = Provider.of<AnfrageService>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;

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
                      children: const [
                        Icon(Icons.delete_forever,
                            color: Colors.redAccent, size: 24),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Fahrt löschen?",
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
                      "Wenn du diese Fahrt löscht, werden auch alle Mitfahr-Anfragen dafür abgebrochen.",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            "Abbrechen",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            "Löschen",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    await anfrageService.cancelAnfragenForFahrt(fahrt.id);
    await fahrtService.delete(fahrt.id);

    if (!context.mounted) return;
    AppSnackbar.show(context, message: "Fahrt wurde gelöscht");
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FahrerProfilBlock
// Avatar + Name + Rating — ganzer Block führt zur PublicProfilePage.
// ─────────────────────────────────────────────────────────────────────────────

class _FahrerProfilBlock extends StatefulWidget {
  final String userId;
  final String name;

  const _FahrerProfilBlock({required this.userId, required this.name});

  @override
  State<_FahrerProfilBlock> createState() => _FahrerProfilBlockState();
}

class _FahrerProfilBlockState extends State<_FahrerProfilBlock> {
  final _photoUrl = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _photoUrl.dispose();
    super.dispose();
  }

  void _navigate() {
    Navigator.push(
      context,
      AppRoute(
        builder: (_) => PublicProfilePage(
          userId: widget.userId,
          name: widget.name,
          photoUrl: _photoUrl.value,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<IAuthRepository>().currentUser?.userId;
    final isMe = currentUid != null && currentUid == widget.userId;
    return GestureDetector(
      onTap: _navigate,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          UserAvatarById(
            userId: widget.userId,
            name: widget.name,
            radius: 21,
            backgroundColor: const Color(0xFF2F5ED6),
            onPhotoLoaded: (url) => _photoUrl.value = url,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMe ? '${widget.name} (du)' : widget.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    TrustShieldsByUserId(userId: widget.userId, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
