import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:my_app/utils/platform_pickers.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/widgets/places_autocomplete_field.dart';
import 'package:provider/provider.dart';

import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/fahrt_service.dart';
import 'package:my_app/data/interessenten_service.dart';
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

class _FahrtAnbietenPageState extends State<FahrtAnbietenPage>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _abfahrtsortFieldKey = GlobalKey();

  String abfahrtsort = '';
  double? _abfahrtsortLat;
  double? _abfahrtsortLng;
  String? _abfahrtsortFullAddress;
  final _abfahrtsortController = TextEditingController();

  TimeOfDay? uhrzeit;
  TimeOfDay? rueckuhrzeit;
  int freiePlaetze = 1;
  String? _timeError;

  Fahrtrichtung fahrtrichtung = Fahrtrichtung.hinfahrt;
  bool _isSaving = false;

  static const int maxPlaetze = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final f = widget.existingFahrt;
    if (f != null) {
      abfahrtsort = f.abfahrtsort;
      _abfahrtsortLat = f.abfahrtsortLat;
      _abfahrtsortLng = f.abfahrtsortLng;
      _abfahrtsortFullAddress = f.abfahrtsortFullAddress;
      uhrzeit = TimeOfDay(hour: f.uhrzeitHour, minute: f.uhrzeitMinute);

      if (f.rueckuhrzeit != null) {
        rueckuhrzeit = f.rueckuhrzeit;
      }

      freiePlaetze = f.freiePlaetze.clamp(1, maxPlaetze);
      fahrtrichtung = f.richtung;
    }
    _abfahrtsortController.text = abfahrtsort;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _abfahrtsortController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 100;
      if (keyboardVisible) {
        final ctx = _abfahrtsortFieldKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fahrtService = context.read<FahrtService>();
    final anfrageService = context.read<AnfrageService>();
    final interessentenService = context.read<InteressentenService>();

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
            title: const Text("Fahrt anbieten"),
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
            controller: _scrollController,
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

                    RadioGroup<Fahrtrichtung>(
                      groupValue: fahrtrichtung,
                      onChanged: (v) {
                        if (v != null) setState(() => fahrtrichtung = v);
                      },
                      child: Column(
                        children: Fahrtrichtung.values.map(
                          (r) => RadioListTile<Fahrtrichtung>(
                            value: r,
                            title: Text(
                              r == Fahrtrichtung.hinfahrt
                                  ? "Nur Hinfahrt"
                                  : r == Fahrtrichtung.rueckfahrt
                                      ? "Nur Rückfahrt"
                                      : "Hin und Zurück",
                              style: const TextStyle(color: Colors.amber),
                            ),
                          ),
                        ).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    PlacesAutocompleteField(
                      key: _abfahrtsortFieldKey,
                      controller: _abfahrtsortController,
                      decoration: InputDecoration(
                        labelText: fahrtrichtung == Fahrtrichtung.rueckfahrt
                            ? "Zielort"
                            : "Abfahrtsort",
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                      textStyle: const TextStyle(color: Colors.amber),
                      onPlaceSelected: (name, fullAddress, lat, lng) {
                        setState(() {
                          abfahrtsort = name;
                          _abfahrtsortFullAddress = fullAddress;
                          _abfahrtsortLat = lat;
                          _abfahrtsortLng = lng;
                        });
                      },
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
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isSaving ? "Speichern …" : "Fahrt speichern"),
                        onPressed: _isSaving
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;

                                if (abfahrtsort.isEmpty) {
                                  AppSnackbar.show(context,
                                      message: "Bitte einen Abfahrtsort wählen",
                                      accentColor: Colors.redAccent);
                                  return;
                                }

                                if (_abfahrtsortLat == null || _abfahrtsortLng == null) {
                                  AppSnackbar.show(context,
                                      message: "Bitte einen Ort aus der Liste wählen",
                                      accentColor: Colors.redAccent);
                                  return;
                                }

                                setState(() => _timeError = null);

                                if (uhrzeit == null) {
                                  setState(() => _timeError = "Bitte eine Uhrzeit auswählen");
                                  return;
                                }

                                if (fahrtrichtung == Fahrtrichtung.hinUndZurueck && rueckuhrzeit == null) {
                                  setState(() => _timeError = "Bitte eine Uhrzeit für die Rückfahrt auswählen");
                                  return;
                                }

                                final user = context.read<IAuthRepository>().currentUser;
                                if (user == null) {
                                  AppSnackbar.show(context, message: "Nicht eingeloggt", accentColor: Colors.redAccent);
                                  return;
                                }

                                final fahrt = widget.existingFahrt == null
                                    ? FahrtDaten.fromTimeOfDay(
                                        id: null,
                                        eventId: widget.event.id,
                                        eventName: widget.event.name,
                                        standort: widget.event.standort,
                                        abfahrtsort: abfahrtsort,
                                        uhrzeit: uhrzeit!,
                                        rueckuhrzeit: fahrtrichtung == Fahrtrichtung.hinUndZurueck
                                            ? rueckuhrzeit
                                            : null,
                                        freiePlaetze: freiePlaetze,
                                        richtung: fahrtrichtung,
                                        ownerId: user.userId,
                                        ownerName: user.name,
                                        abfahrtsortLat: _abfahrtsortLat,
                                        abfahrtsortLng: _abfahrtsortLng,
                                        abfahrtsortFullAddress: _abfahrtsortFullAddress,
                                        eventDatum: widget.event.datum,
                                      )
                                    : widget.existingFahrt!.copyWith(
                                        abfahrtsort: abfahrtsort,
                                        uhrzeitHour: uhrzeit!.hour,
                                        uhrzeitMinute: uhrzeit!.minute,
                                        rueckuhrzeitHour: rueckuhrzeit?.hour,
                                        rueckuhrzeitMinute: rueckuhrzeit?.minute,
                                        freiePlaetze: freiePlaetze,
                                        richtung: fahrtrichtung,
                                        abfahrtsortLat: _abfahrtsortLat,
                                        abfahrtsortLng: _abfahrtsortLng,
                                        abfahrtsortFullAddress: _abfahrtsortFullAddress,
                                        eventDatum: widget.event.datum,
                                      );

                                // Navigator vor dem await sichern
                                final nav = Navigator.of(context);

                                setState(() => _isSaving = true);
                                try {
                                  if (widget.existingFahrt == null) {
                                    await fahrtService.add(fahrt);
                                    await interessentenService.removeForUser(widget.event.id, fahrt.ownerId);
                                    await anfrageService.storniereOffeneAnfragenFuerEvent(
                                      eventId: widget.event.id,
                                      requesterId: fahrt.ownerId,
                                    );
                                  } else {
                                    await fahrtService.update(fahrt);
                                  }
                                } catch (e, st) {
                                  if (kDebugMode) debugPrint('❌ [Speichern] Fehler: $e\n$st');
                                  if (!context.mounted) return;
                                  setState(() => _isSaving = false);
                                  AppSnackbar.show(context, message: "Fehler: $e", accentColor: Colors.redAccent);
                                  return;
                                }

                                if (!context.mounted) return;
                                AppSnackbar.show(context, message: "Fahrt gespeichert", accentColor: const Color(0xFF5DA9FF));
                                nav.pop();
                              },
                      ),
                    ),
                  ],
                ),
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
            final picked = await showPlatformTimePicker(
              context,
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
