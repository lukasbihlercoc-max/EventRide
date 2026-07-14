// events_page.dart
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:my_app/utils/async_guard.dart';
import 'package:my_app/utils/platform_pickers.dart';
import 'package:my_app/views/widgets/places_autocomplete_field.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/event_service.dart';
import 'package:intl/intl.dart';
import 'package:my_app/views/widgets/background_widget.dart';

const _kAccent = Color(0xFF5DA9FF);
const _kGlassAlpha = 0.06;
const _kGlassBorder = 0.10;
const _kRadius = 14.0;
const _kButtonHeight = 46.0;
const _kPadding = 24.0;

InputDecoration getInputStyle(String label, {Widget? suffixIcon}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: Colors.white70,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.white70,
        width: 2,
      ),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(
        color: _kAccent,
        width: 4,
      ),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    contentPadding: const EdgeInsets.symmetric(
      vertical: 20,
      horizontal: 16,
    ),
    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
    suffixIcon: suffixIcon,
  );
}

const inputTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 20,
  fontWeight: FontWeight.w600,
);

const _kTypLabels = {
  'e0': 'Standart',
  'e1': 'Kirchtage & Feste',
  'e2': 'Feuerwehrfeste',
  'e3': 'Disco & Party',
  'e4': 'Bälle',
  'e5': 'Krampus & Perchten',
  'e6': 'Festivals & Open Air',
  'e7': 'Beach & Sommer',
};

class EventsPage extends StatefulWidget {
  final Event? event; // optional: edit existing
  const EventsPage({super.key, required this.event});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final nameController = TextEditingController();
  final standortController = TextEditingController();
  final datumController = TextEditingController();
  final vonController = TextEditingController();
  final bisController = TextEditingController();
  final uhrzeitController = TextEditingController(text: '20:00');
  String? typ = "e0";
  final beschreibungController = TextEditingController();
  final adresseController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _pinned = false;
  bool _adminOnly = false;
  bool _mehrtaegig = false;
  bool _syncChildren = true;
  bool _saving = false;

  List<Event> _similarEvents = [];
  Timer? _debounceTimer;

  bool get _isEditingContainer => widget.event?.isContainer ?? false;

  @override
  void initState() {
    super.initState();

    if (widget.event != null) {
      nameController.text = widget.event!.name;
      standortController.text = widget.event!.standort;
      datumController.text = DateFormat("dd.MM.yyyy").format(widget.event!.datum.toLocal());
      uhrzeitController.text = widget.event!.uhrzeit ?? '20:00';
      typ = _kTypLabels.containsKey(widget.event!.typ) ? widget.event!.typ : "e0";
      beschreibungController.text = widget.event!.beschreibung;
      adresseController.text = widget.event!.adresse;
      _latitude = widget.event!.latitude;
      _longitude = widget.event!.longitude;
      _pinned = widget.event!.pinned;
      _adminOnly = widget.event!.adminOnly;
    }

    nameController.addListener(_onTextChanged);
    adresseController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    nameController.dispose();
    standortController.dispose();
    datumController.dispose();
    vonController.dispose();
    bisController.dispose();
    uhrzeitController.dispose();
    beschreibungController.dispose();
    adresseController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 800),
      _updateSimilarEvents,
    );
  }

  double _jaccard(String a, String b) {
    final tokensA = a
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1)
        .toSet();
    final tokensB = b
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1)
        .toSet();
    if (tokensA.isEmpty && tokensB.isEmpty) return 1.0;
    if (tokensA.isEmpty || tokensB.isEmpty) return 0.0;
    return tokensA.intersection(tokensB).length /
        tokensA.union(tokensB).length;
  }

  bool _sameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _updateSimilarEvents() {
    if (!mounted) return;

    final enteredName = nameController.text.trim();
    if (enteredName.isEmpty) {
      setState(() => _similarEvents = []);
      return;
    }

    DateTime? enteredDate;
    try {
      if (datumController.text.trim().isNotEmpty) {
        enteredDate =
            DateFormat("dd.MM.yyyy").parseStrict(datumController.text.trim(), true);
      }
    } catch (_) {}

    final enteredAdresse = adresseController.text.trim();
    final allEvents = context.read<EventService>().events;

    final scored = <({Event event, double score})>[];

    for (final candidate in allEvents) {
      if (widget.event != null && candidate.id == widget.event!.id) continue;

      final nameScore = _jaccard(enteredName, candidate.name);
      final dateScore = (enteredDate != null &&
              _sameCalendarDay(enteredDate, candidate.datum.toLocal()))
          ? 1.0
          : 0.0;
      final addrScore = enteredAdresse.isNotEmpty
          ? _jaccard(enteredAdresse, candidate.adresse)
          : 0.0;

      final composite = nameScore * 0.5 + dateScore * 0.3 + addrScore * 0.2;

      if (composite >= 0.3 || nameScore >= 0.7) {
        scored.add((event: candidate, score: composite));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    setState(() => _similarEvents = scored.take(5).map((r) => r.event).toList());
  }

  Future<void> _saveEvent() async {
    if (_saving) return;

    // Mehrtägig-Neuanlage: Von/Bis statt Einzeldatum, läuft komplett über
    // die createEventContainer Cloud Function (einzige Implementierung der
    // Tages-Generierung, siehe functions/src/index.ts).
    if (widget.event == null && _mehrtaegig) {
      if (vonController.text.trim().isEmpty || bisController.text.trim().isEmpty) {
        AppSnackbar.show(context, message: "Bitte Von- und Bis-Datum auswählen");
        return;
      }
      try {
        final von = DateFormat("dd.MM.yyyy").parseStrict(vonController.text, true);
        final bis = DateFormat("dd.MM.yyyy").parseStrict(bisController.text, true);
        setState(() => _saving = true);
        await guarded(
          FirebaseFunctions.instance.httpsCallable('createEventContainer').call({
            'name': nameController.text.trim().isEmpty
                ? "Unbenanntes Event"
                : nameController.text.trim(),
            'standort': standortController.text.trim().isNotEmpty
                ? standortController.text.trim()
                : "Unbekannt",
            'typ': typ ?? "e0",
            'beschreibung': beschreibungController.text.trim(),
            'adresse': adresseController.text.trim().isNotEmpty
                ? adresseController.text.trim()
                : "Adresse nicht angegeben",
            'latitude': _latitude,
            'longitude': _longitude,
            'uhrzeit': uhrzeitController.text.trim().isEmpty
                ? null
                : uhrzeitController.text.trim(),
            'pinned': _pinned,
            'adminOnly': _adminOnly,
            'von': von.toIso8601String(),
            'bis': bis.toIso8601String(),
          }),
        );
        if (!mounted) return;
        Navigator.pop(context);
      } on FormatException {
        if (mounted) AppSnackbar.show(context, message: "Ungültiges Datumformat");
      } on AsyncGuardTimeoutException {
        if (mounted) {
          Navigator.pop(context);
          AppSnackbar.show(context,
              message: "Verbindung langsam – wird im Hintergrund synchronisiert");
        }
      } catch (e) {
        if (mounted) AppSnackbar.show(context, message: "Fehler beim Speichern: $e");
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    if (datumController.text.trim().isEmpty) {
      AppSnackbar.show(context, message: "Bitte ein Datum auswählen");
      return;
    }

    // Container-Bearbeitung: läuft über updateEventContainer (optional mit
    // Sync auf alle Kind-Tage), nicht über den normalen Einzel-Update-Pfad.
    if (_isEditingContainer) {
      try {
        setState(() => _saving = true);
        await guarded(
          FirebaseFunctions.instance.httpsCallable('updateEventContainer').call({
            'containerId': widget.event!.id,
            'name': nameController.text.trim().isEmpty
                ? widget.event!.name
                : nameController.text.trim(),
            'standort': standortController.text.trim().isNotEmpty
                ? standortController.text.trim()
                : widget.event!.standort,
            'typ': typ ?? widget.event!.typ,
            'beschreibung': beschreibungController.text.trim(),
            'adresse': adresseController.text.trim().isNotEmpty
                ? adresseController.text.trim()
                : widget.event!.adresse,
            'latitude': _latitude,
            'longitude': _longitude,
            'uhrzeit': uhrzeitController.text.trim().isEmpty
                ? null
                : uhrzeitController.text.trim(),
            'pinned': _pinned,
            'adminOnly': _adminOnly,
            'syncChildren': _syncChildren,
          }),
        );
        if (!mounted) return;
        Navigator.pop(context);
      } on AsyncGuardTimeoutException {
        if (mounted) {
          Navigator.pop(context);
          AppSnackbar.show(context,
              message: "Verbindung langsam – wird im Hintergrund synchronisiert");
        }
      } catch (e) {
        if (mounted) AppSnackbar.show(context, message: "Fehler beim Speichern: $e");
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    try {
      final parsedDate =
          DateFormat("dd.MM.yyyy").parseStrict(datumController.text, true);
      final eventService = context.read<EventService>();

      final uhrzeit = uhrzeitController.text.trim().isEmpty ? null : uhrzeitController.text.trim();
      if (widget.event == null) {
        final newEvent = Event(
          name: nameController.text.trim().isEmpty
              ? "Unbenanntes Event"
              : nameController.text.trim(),
          datum: parsedDate,
          uhrzeit: uhrzeit,
          standort: standortController.text.isNotEmpty
              ? standortController.text.trim()
              : "Unbekannt",
          typ: typ ?? "e0",
          beschreibung: beschreibungController.text.trim(),
          adresse: adresseController.text.trim().isNotEmpty
              ? adresseController.text.trim()
              : "Adresse nicht angegeben",
          latitude: _latitude,
          longitude: _longitude,
          pinned: _pinned,
          adminOnly: _adminOnly,
        );
        await eventService.add(newEvent);
      } else {
        final updatedEvent = widget.event!.copyWith(
          name: nameController.text.trim().isEmpty
              ? widget.event!.name
              : nameController.text.trim(),
          datum: parsedDate,
          uhrzeit: uhrzeit,
          standort: standortController.text.trim().isNotEmpty
              ? standortController.text.trim()
              : widget.event!.standort,
          typ: typ ?? widget.event!.typ,
          beschreibung: beschreibungController.text.trim(),
          adresse: adresseController.text.trim().isNotEmpty
              ? adresseController.text.trim()
              : widget.event!.adresse,
          latitude: _latitude,
          longitude: _longitude,
          pinned: _pinned,
          adminOnly: _adminOnly,
        );
        await eventService.update(updatedEvent);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } on FormatException {
      if (!mounted) return;
      AppSnackbar.show(context, message: "Ungültiges Datumformat");
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, message: "Fehler beim Speichern: $e");
    }
  }

  Widget _checkboxTile({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: _kAccent,
              side: const BorderSide(color: Colors.white70, width: 1.5),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typBadge(String typKey) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.18),
        border: Border.all(color: _kAccent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _kTypLabels[typKey] ?? typKey,
        style: const TextStyle(
          color: _kAccent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSimilarEventsSection() {
    if (_similarEvents.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: _kGlassAlpha),
        border: Border.all(
          color: Colors.white.withValues(alpha: _kGlassBorder),
        ),
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFF5A623), size: 18),
              SizedBox(width: 8),
              Text(
                "Ähnliche Events gefunden",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Bitte prüfen ob dieses Event bereits existiert.",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...List.generate(_similarEvents.length, (i) {
            final e = _similarEvents[i];
            final dateStr =
                DateFormat('dd.MM.yyyy').format(e.datum.toLocal());
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _typBadge(e.typ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.event == null ? "Neues Event erstellen" : "Event bearbeiten",
            style: const TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(_kPadding),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  style: inputTextStyle,
                  decoration: getInputStyle("Eventname"),
                ),
                const SizedBox(height: 16),
                _checkboxTile(
                  label: "Angepinnt",
                  value: _pinned,
                  onChanged: (v) => setState(() => _pinned = v ?? false),
                ),
                const SizedBox(height: 8),
                _checkboxTile(
                  label: "Nur für Admins sichtbar (Test-Event)",
                  value: _adminOnly,
                  onChanged: (v) => setState(() => _adminOnly = v ?? false),
                ),
                if (widget.event == null) ...[
                  const SizedBox(height: 8),
                  _checkboxTile(
                    label: "Mehrtägiges Event",
                    value: _mehrtaegig,
                    onChanged: (v) => setState(() => _mehrtaegig = v ?? false),
                  ),
                ],
                if (_isEditingContainer) ...[
                  const SizedBox(height: 8),
                  _checkboxTile(
                    label: "Änderungen auf alle Tage übertragen",
                    value: _syncChildren,
                    onChanged: (v) => setState(() => _syncChildren = v ?? false),
                  ),
                ],
                const SizedBox(height: 16),
                if (widget.event == null && _mehrtaegig) ...[
                  TextFormField(
                    controller: vonController,
                    style: inputTextStyle,
                    decoration: getInputStyle(
                      "Von",
                      suffixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final pickedDate = await showPlatformDatePicker(
                        context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          vonController.text =
                              DateFormat('dd.MM.yyyy').format(pickedDate);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: bisController,
                    style: inputTextStyle,
                    decoration: getInputStyle(
                      "Bis",
                      suffixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final pickedDate = await showPlatformDatePicker(
                        context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          bisController.text =
                              DateFormat('dd.MM.yyyy').format(pickedDate);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  TextFormField(
                    controller: datumController,
                    style: inputTextStyle,
                    decoration: getInputStyle(
                      "Datum",
                      suffixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showPlatformDatePicker(
                        context,
                        initialDate: widget.event?.datum.toLocal() ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          datumController.text =
                              DateFormat('dd.MM.yyyy').format(pickedDate);
                        });
                        _updateSimilarEvents();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte ein Datum auswählen';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: uhrzeitController,
                  style: inputTextStyle,
                  decoration: getInputStyle(
                    "Uhrzeit",
                    suffixIcon: const Icon(Icons.access_time, color: Colors.white38, size: 20),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final parts = uhrzeitController.text.split(':');
                    final initial = parts.length == 2
                        ? TimeOfDay(
                            hour: int.tryParse(parts[0])?.clamp(0, 23) ?? 20,
                            minute: int.tryParse(parts[1])?.clamp(0, 59) ?? 0,
                          )
                        : const TimeOfDay(hour: 20, minute: 0);
                    final picked = await showPlatformTimePicker(context, initialTime: initial);
                    if (picked != null) {
                      setState(() {
                        uhrzeitController.text =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: standortController,
                  style: inputTextStyle,
                  decoration: getInputStyle("Standort"),
                ),
                const SizedBox(height: 16),
                PlacesAutocompleteField(
                  controller: adresseController,
                  decoration: getInputStyle("genaue Adresse"),
                  textStyle: inputTextStyle,
                  localityOnly: false,
                  onPlaceSelected: (_, __, lat, lng) {
                    setState(() {
                      _latitude = lat;
                      _longitude = lng;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: typ,
                  dropdownColor: const Color(0xFF1B3A6B),
                  style: inputTextStyle,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white54),
                  decoration: const InputDecoration(
                    labelText: "Event-Typ",
                    labelStyle: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70, width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _kAccent, width: 4),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  ),
                  items: _kTypLabels.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => typ = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: beschreibungController,
                  style: inputTextStyle,
                  decoration: getInputStyle("Beschreibung"),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 24),
                _buildSimilarEventsSection(),
                if (_similarEvents.isNotEmpty) const SizedBox(height: 16),
                GestureDetector(
                  onTap: _saving ? null : _saveEvent,
                  child: Container(
                    width: double.infinity,
                    height: _kButtonHeight,
                    decoration: BoxDecoration(
                      color: _saving ? _kAccent.withValues(alpha: 0.5) : _kAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _saving
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                          )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_outlined,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.event == null
                              ? "Event abspeichern"
                              : "Änderungen speichern",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
