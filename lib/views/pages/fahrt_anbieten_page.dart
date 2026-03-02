import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/fahrt_service.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';

class FahrtAnbietenPage extends StatefulWidget {
  final Event event;
  final FahrtDaten? existingFahrt;

  const FahrtAnbietenPage({
    super.key,
    required this.event,
    this.existingFahrt,
  });

  @override
  State<FahrtAnbietenPage> createState() => _FahrtAnbietenPageState();
}

class _FahrtAnbietenPageState extends State<FahrtAnbietenPage> {
  final _formKey = GlobalKey<FormState>();

  String abfahrtsort = '';
  TimeOfDay? uhrzeit;
  TimeOfDay? rueckuhrzeit;
  int freiePlaetze = 1;
  String? _timeError;

  Fahrtrichtung fahrtrichtung = Fahrtrichtung.hinfahrt;

  static const int maxPlaetze = 20;

  @override
  void initState() {
    super.initState();

    final f = widget.existingFahrt;
    if (f != null) {
      abfahrtsort = f.abfahrtsort;
      uhrzeit = TimeOfDay(hour: f.uhrzeitHour, minute: f.uhrzeitMinute);

      if (f.rueckuhrzeit != null) {
        rueckuhrzeit = f.rueckuhrzeit;
      }

      freiePlaetze = f.freiePlaetze.clamp(1, maxPlaetze);
      fahrtrichtung = f.richtung;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fahrtService = context.read<FahrtService>();

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
            title: const Text("Fahrt anbieten"),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Event: ${widget.event.name}",
                      style: const TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Fahrtrichtung:",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),

                    ...Fahrtrichtung.values.map(
                      (r) => RadioListTile<Fahrtrichtung>(
                        value: r,
                        groupValue: fahrtrichtung,
                        onChanged: (v) => setState(() => fahrtrichtung = v!),
                        title: Text(
                          r == Fahrtrichtung.hinfahrt
                              ? "Nur Hinfahrt"
                              : r == Fahrtrichtung.rueckfahrt
                                  ? "Nur Rückfahrt"
                                  : "Hin und Zurück",
                          style: const TextStyle(color: Colors.amber),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextFormField(
                      decoration: InputDecoration(
                        labelText: fahrtrichtung == Fahrtrichtung.rueckfahrt
                            ? "Zielort"
                            : "Abfahrtsort",
                      ),
                      style: const TextStyle(color: Colors.amber),
                      initialValue: abfahrtsort,
                      onChanged: (v) => abfahrtsort = v,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Pflichtfeld" : null,
                    ),

                    const SizedBox(height: 24),

                    _timePickerRow(
                      label: "Uhrzeit",
                      time: uhrzeit,
                      onPick: (t) => setState(() => uhrzeit = t),
                      
                    ),

                    if (_timeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          _timeError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),


                    if (fahrtrichtung == Fahrtrichtung.hinUndZurueck)
                      _timePickerRow(
                        label: "Rückfahrt",
                        time: rueckuhrzeit,
                        onPick: (t) => setState(() => rueckuhrzeit = t),
                      ),

                    const SizedBox(height: 24),

                    _plaetzeSelector(),

                    const SizedBox(height: 32),

                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text("Fahrt speichern"),
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

setState(() {
  _timeError = null;
});

if (uhrzeit == null) {
  setState(() {
    _timeError = "Bitte eine Uhrzeit auswählen";
  });
  return;
}

if (fahrtrichtung == Fahrtrichtung.hinUndZurueck && rueckuhrzeit == null) {
  setState(() {
    _timeError = "Bitte eine Uhrzeit für die Rückfahrt auswählen";
  });
  return;
}



                          final user = context.read<IAuthRepository>().currentUser!;


                          final fahrt = widget.existingFahrt == null
                              ? FahrtDaten.fromTimeOfDay(
                                  id: null, // NEU → generiert neue ID
                                  eventId: widget.event.id,
                                  eventName: widget.event.name,
                                  standort: widget.event.standort,
                                  abfahrtsort: abfahrtsort,
                                  uhrzeit: uhrzeit!,
                                  rueckuhrzeit:
                                      fahrtrichtung ==
                                          Fahrtrichtung.hinUndZurueck
                                      ? rueckuhrzeit
                                      : null,
                                  freiePlaetze: freiePlaetze,
                                  richtung: fahrtrichtung,
                                  ownerId: user.userId,
                                  ownerName: user.name,
                                )
                              : widget.existingFahrt!.copyWith(
                                  abfahrtsort: abfahrtsort,
                                  uhrzeitHour: uhrzeit!.hour,
                                  uhrzeitMinute: uhrzeit!.minute,
                                  rueckuhrzeitHour: rueckuhrzeit?.hour,
                                  rueckuhrzeitMinute: rueckuhrzeit?.minute,
                                  freiePlaetze: freiePlaetze,
                                  richtung: fahrtrichtung,
                                );


                          if (widget.existingFahrt == null) {
                            await fahrtService.add(fahrt);
                          } else {
                            await fahrtService.update(fahrt);
                          }

                          if (!mounted) return;

                          // ✅ Snackbar anzeigen
                          AppSnackbar.show(
                            context,
                            message: "Fahrt gespeichert",
                            accentColor: const Color(0xFF5DA9FF),
                          );

                          // ⏳ kleine Verzögerung, damit sie sichtbar bleibt
                          await Future.delayed(
                            const Duration(milliseconds: 300),
                          );

                          Navigator.pop(context);

                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
 
  Widget _timePickerRow({
    required String label,
    required TimeOfDay? time,
    required ValueChanged<TimeOfDay> onPick,
  }) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(color: Colors.white)),
        Text(
          time?.format(context) ?? "--:--",
          style: const TextStyle(color: Colors.amber, fontSize: 20),
        ),
        TextButton(
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );

            if (picked != null) {
              setState(() {
                _timeError = null; // ✅ Fehler zurücksetzen
                onPick(picked);
              });
            }
          },
          child: const Text("Wählen"),
        ),
      ],
    );
  }

  Widget _plaetzeSelector() {
    return Row(
      children: [
        const Text("Freie Plätze:", style: TextStyle(color: Colors.white)),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () =>
              setState(() => freiePlaetze = (freiePlaetze - 1).clamp(1, maxPlaetze)),
          icon: const Icon(Icons.remove, color: Colors.white),
        ),
        Text(
          "$freiePlaetze",
          style: const TextStyle(color: Colors.amber, fontSize: 22),
        ),
        IconButton(
          onPressed: () =>
              setState(() => freiePlaetze = (freiePlaetze + 1).clamp(1, maxPlaetze)),
          icon: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }
}
