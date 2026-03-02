// fahrtencard_widget.dart
import 'package:flutter/material.dart';
import 'package:my_app/data/fahrt_anfrage_service.dart';
import 'package:my_app/data/fahrt_service.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';

import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/views/pages/fahrt_anbieten_page.dart';
import 'package:my_app/views/widgets/sizehelper_widget.dart';
import 'package:my_app/views/pages/fahrt_anfragen_page.dart';
import 'package:my_app/views/auth/auth_guard.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';

import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import 'dart:ui'; // 🔥 NEU für BackdropFilter / Blur


String getBackgroundImage(Fahrtrichtung richtung) {
  switch (richtung) {
    case Fahrtrichtung.hinfahrt:
      return "assets/image/hinfahrt3.png";
    case Fahrtrichtung.rueckfahrt:
      return "assets/image/rueckfahrt3.png";
    case Fahrtrichtung.hinUndZurueck:
      return "assets/image/hinundrueck2.png";
  }
}

class FahrtenCard extends StatelessWidget {
  final FahrtDaten fahrt;
  final bool isEditable; // 🆕 Flag, ob die Karte bearbeitbar ist

  const FahrtenCard({super.key, required this.fahrt, this.isEditable = false});

  @override
  Widget build(BuildContext context) {
    // 🆕 Anzahl offener Anfragen für diese Fahrt
    final offeneAnfragenCount = context
        .watch<AnfrageService>()
        .getAnfragenForFahrt(fahrt.id)
        .where((a) => a.status == AnfrageStatus.offen)
        .length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(getBackgroundImage(fahrt.richtung)),
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.1, 0.1),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minHeight: 260),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((0.35 * 255).round()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Benutzername
                    Row(
                      children: [
                        // Linker Teil: Name + Sterne
                        Expanded(
                          child: Row(
                            children: const [
                              Text(
                                "Günther Hiden",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.star, color: Colors.amber, size: 20),
                              Icon(Icons.star, color: Colors.amber, size: 20),
                              Icon(Icons.star, color: Colors.amber, size: 20),
                            ],
                          ),
                        ),

                        // Rechter Teil: Chat-Icon NUR wenn isEditable = true
                        if (isEditable)
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          FahrtAnfragenPage(fahrt: fahrt),
                                    ),
                                  );
                                },
                              ),

                              // 🆕 Badge nur anzeigen, wenn es offene Anfragen gibt
                              if (offeneAnfragenCount > 0)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
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

                      ],
                    ),
                    // 🔹 Eventname + Datum (anklickbar)
// 🔹 Eventname + Datum (anklickbar, Datum wird über Event geladen)
GestureDetector(
  onTap: () => _showEventDetailsPopup(context),
  child: Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 6),
    child: Row(
      children: [
        const Icon(
          Icons.event,
          color: Colors.white70,
          size: 18,
        ),
        const SizedBox(width: 6),

        Expanded(
          child: Builder(
            builder: (context) {
              // 🔥 Event über die eventId aus Hive laden
              final eventBox = Hive.box<Event>("events");
              final event = eventBox.values.firstWhere(
                (e) => e.id == fahrt.eventId,
                orElse: () => Event(
                  name: fahrt.eventName,
                  datum: DateTime(2000),
                  standort: fahrt.standort,
                  beschreibung: "",
                  typ: "",
                  adresse: "",
                ),
              );

              final dateText = event.datum.year == 2000
                  ? ""
                  : " (${DateFormat('dd.MM.yy').format(event.datum)})";

              return Text(
                "${fahrt.eventName}$dateText",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ],
    ),
  ),
),



                    const Divider(color: Colors.amber),

                    // ✅ Fahrtrichtung
                    Row(
                      children: [
                        const Icon(
                          Icons.directions,
                          color: Colors.greenAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          () {
                            switch (fahrt.richtung) {
                              case Fahrtrichtung.hinfahrt:
                                return "Nur Hinfahrt";
                              case Fahrtrichtung.rueckfahrt:
                                return "Nur Rückfahrt";
                              case Fahrtrichtung.hinUndZurueck:
                                return "Hin und Zurück";
                            }
                          }(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ✅ Strecke
                   // ✅ Strecke mit Richtungspfeilen
                    Row(
                      children: [
                        Text(
                          fahrt.abfahrtsort,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Pfeil abhängig von der Richtung
                        () {
                          switch (fahrt.richtung) {
                            case Fahrtrichtung.hinfahrt:
                              return const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 26,
                              );

                            case Fahrtrichtung.rueckfahrt:
                              return const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 26,
                              );

                            case Fahrtrichtung.hinUndZurueck:
                              return const Icon(
                                Icons.swap_horiz_rounded,
                                color: Colors.white,
                                size: 28,
                              );
                          }
                        }(),

                        const SizedBox(width: 8),

                        Text(
                          fahrt.standort,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),


                    const SizedBox(height: 6),

                    // ✅ Uhrzeit(en)
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.amberAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          fahrt.uhrzeit.format(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                        if (fahrt.richtung == Fahrtrichtung.hinUndZurueck) ...[
                          const SizedBox(width: 20),
                          const Icon(
                            Icons.access_time,
                            color: Colors.amberAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            fahrt.rueckuhrzeit?.format(context) ?? "",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ✅ Freie Plätze
                    Row(
                      children: [
                        const Icon(
                          Icons.event_seat,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${fahrt.freiePlaetze} freie Plätze",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ✅ Buttons (Bearbeiten / Mitfahren / Löschen)
                    Align(
                      alignment: Alignment.centerRight,
                      child: isEditable
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 🔴 Löschen-Button (gleiches Design wie Bearbeiten, nur rot)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.redAccent, // 🔴 rote Fläche
                                    foregroundColor:
                                        Colors.white, // weiße Schrift
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _handleDelete(context),
                                  child: Text(
                                    "Löschen",
                                    style: TextStyle(
                                      fontSize: SizeHelper.w(context, 0.04),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // 🔵 Bearbeiten-Button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _handleEdit(context),
                                  child: Text(
                                    "Bearbeiten",
                                    style: TextStyle(
                                      fontSize: SizeHelper.w(context, 0.04),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _handleMitfahren(context),
                              child: Text(
                                "Mitfahren",
                                style: TextStyle(
                                  fontSize: SizeHelper.w(context, 0.04),
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
    );
  }

  void _handleEdit(BuildContext context) {
    final event = Event(
      name: fahrt.eventName,
      standort: fahrt.standort,
      datum: DateTime.now(), // TODO: echtes Event-Datum, wenn vorhanden
      beschreibung: '',
      typ: '',
      adresse: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FahrtAnbietenPage(event: event, existingFahrt: fahrt),
      ),
    );
  }

  void _showEventDetailsPopup(BuildContext context) {
  final eventBox = Hive.box<Event>("events");
  final event = eventBox.values.firstWhere(
    (e) => e.id == fahrt.eventId,
    orElse: () => Event(
      name: fahrt.eventName,
      datum: DateTime(2000),
      standort: fahrt.standort,
      beschreibung: "",
      typ: "",
      adresse: "",
    ),
  );

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
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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

                  // Datum
                  if (event.datum.year != 2000)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat("dd.MM.yyyy").format(event.datum),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  // Standort
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
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                            color: Colors.white70,
                            thickness: 1,
                            height: 12, // 32px
                          ),

                  const SizedBox(height: 12),

                  // Beschreibung
                  if (event.beschreibung.trim().isNotEmpty)
                    Text(
                      event.beschreibung,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
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

  // aktuell ausgewählte Plätze
  int selectedSeats = 1;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final size = MediaQuery.of(ctx).size;

      // AnimatedPadding + SingleChildScrollView um Keyboard-Overlap zu vermeiden
      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.decelerate,
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                // WICHTIG: Material-Widget hinzufügen, aber transparent, damit
                // das Aussehen gleich bleibt. Das stellt den benötigten
                // Material-Context für TextFormField/TextField bereit.
                child: Material(
                  type: MaterialType.transparency,
                  child: StatefulBuilder(
                    builder: (ctxInner, setStateDialog) {
                      return Container(
                        width: size.width * 0.85,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        constraints: BoxConstraints(
                          // maxHeight kleiner als Bildschirm, damit bei Keyboard noch Platz bleibt
                          maxHeight: size.height * 0.85,
                          minHeight: 200,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
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
                              // HEADER
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.chat_bubble_outline,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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

                              // PLÄTZE
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
                                  // MINUS
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
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

                                  // PLUS
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.add, color: Colors.white),
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
                                          color: Colors.white38, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // NACHRICHT
                              const Text(
                                "Nachricht (optional)",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // TextFormField benötigt Material-Ancestor (deshalb oben Material),
                              // autofocus false damit Tastatur nicht sofort aufpoppt (optional)
                              TextFormField(
                                controller: messageController,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 3,
                                minLines: 3,
                                autofocus: false,
                                decoration: const InputDecoration(
                                  hintText: "z. B. Treffpunkt oder Info",
                                  hintStyle: TextStyle(color: Colors.white38),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.lightBlueAccent),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // BUTTONS
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text(
                                      "Abbrechen",
                                      style: TextStyle(color: Colors.white70),
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


if (!success) {
  AppSnackbar.show(
        context,
        message: "Du hast bereits angefragt!",
      );
  return;
}


  if (!context.mounted) return;

  AppSnackbar.show(
        context,
        message: "Anfrage wurde gesendet",
      );
}


  void _handleDelete(BuildContext context) async {
  final confirmed = await showDialog<bool>(
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
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Header mit Icon + Titel
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
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Buttons unten rechts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          "Abbrechen",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
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

  final fahrtService = Provider.of<FahrtService>(context, listen: false);
  final anfrageService = Provider.of<AnfrageService>(context, listen: false);

  // 1) alle Anfragen zu dieser Fahrt abbrechen
  await anfrageService.cancelAnfragenForFahrt(fahrt.id);

  // 2) Fahrt löschen
  await fahrtService.delete(fahrt.id);

  if (!context.mounted) return;
  AppSnackbar.show(
        context,
        message: "Fahrt wurde gelöscht",
      );
}
}
