// event_submit_page.dart
import 'dart:io';
import 'dart:async';
import 'package:my_app/utils/platform_pickers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/views/widgets/places_autocomplete_field.dart';
import 'package:intl/intl.dart';
import 'package:my_app/data/event_service.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/views/widgets/app_bottom_sheet.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:provider/provider.dart';

const _kAccent = Color(0xFF5DA9FF);
const _kGlassAlpha = 0.06;
const _kGlassBorder = 0.10;
const _kRadius = 14.0;
const _kButtonHeight = 46.0;
const _kPadding = 24.0;

const _kTypLabels = {
  'e0': 'Standart',
  'e1': 'Kirchtage/Feste',
  'e2': 'Feuerwehrfest',
  'e3': 'Disco',
  'e4': 'Ball',
  'e5': 'Krampuslauf',
  'e6': 'Festival/Open-Air',
  'e7': 'Sommer/Strand',
};

InputDecoration _inputStyle(String label, {Widget? suffixIcon}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: Colors.white70,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white70, width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: _kAccent, width: 4),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    contentPadding:
        const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
    suffixIcon: suffixIcon,
  );
}

const _kInputTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 20,
  fontWeight: FontWeight.w600,
);

class EventSubmitPage extends StatefulWidget {
  const EventSubmitPage({super.key});

  @override
  State<EventSubmitPage> createState() => _EventSubmitPageState();
}

class _EventSubmitPageState extends State<EventSubmitPage> {
  int _tab = 0; // 0 = Manuell, 1 = Flyer

  // ── Manuell ──────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _standortCtrl = TextEditingController();
  final _datumCtrl = TextEditingController();
  final _uhrzeitCtrl = TextEditingController(text: '20:00');
  final _adresseCtrl = TextEditingController();
  final _beschreibungCtrl = TextEditingController();
  String _typ = 'e0';
  double? _latitude;
  double? _longitude;
  List<Event> _similarEvents = [];
  Timer? _debounceTimer;

  // ── Flyer ─────────────────────────────────────────────────────────────
  File? _flyerFile;
  final _noteCtrl = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onTextChanged);
    _adresseCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameCtrl.dispose();
    _standortCtrl.dispose();
    _datumCtrl.dispose();
    _uhrzeitCtrl.dispose();
    _adresseCtrl.dispose();
    _beschreibungCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer =
        Timer(const Duration(milliseconds: 800), _updateSimilarEvents);
  }

  double _jaccard(String a, String b) {
    final ta = a.toLowerCase().split(RegExp(r'\s+')).where((t) => t.length > 1).toSet();
    final tb = b.toLowerCase().split(RegExp(r'\s+')).where((t) => t.length > 1).toSet();
    if (ta.isEmpty && tb.isEmpty) return 1.0;
    if (ta.isEmpty || tb.isEmpty) return 0.0;
    return ta.intersection(tb).length / ta.union(tb).length;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _updateSimilarEvents() {
    if (!mounted) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _similarEvents = []);
      return;
    }
    DateTime? date;
    try {
      if (_datumCtrl.text.trim().isNotEmpty) {
        date = DateFormat('dd.MM.yyyy').parseStrict(_datumCtrl.text.trim(), true);
      }
    } catch (_) {}

    final all = context.read<EventService>().events;
    final scored = <({Event event, double score})>[];
    for (final c in all) {
      final ns = _jaccard(name, c.name);
      final ds = (date != null && _sameDay(date, c.datum.toLocal())) ? 1.0 : 0.0;
      final as_ = _adresseCtrl.text.trim().isNotEmpty
          ? _jaccard(_adresseCtrl.text.trim(), c.adresse)
          : 0.0;
      final total = ns * 0.5 + ds * 0.3 + as_ * 0.2;
      if (total >= 0.3 || ns >= 0.7) scored.add((event: c, score: total));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    setState(() => _similarEvents = scored.take(5).map((r) => r.event).toList());
  }

  Future<void> _submitManual() async {
    if (_datumCtrl.text.trim().isEmpty) {
      AppSnackbar.show(context, message: 'Bitte ein Datum auswählen');
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<IAuthRepository>().submitEventRequestManual(
            name: _nameCtrl.text.trim().isEmpty
                ? 'Unbenanntes Event'
                : _nameCtrl.text.trim(),
            standort: _standortCtrl.text.trim().isEmpty
                ? 'Unbekannt'
                : _standortCtrl.text.trim(),
            datum: _datumCtrl.text.trim(),
            uhrzeit: _uhrzeitCtrl.text.trim().isEmpty ? null : _uhrzeitCtrl.text.trim(),
            eventTyp: _typ,
            beschreibung: _beschreibungCtrl.text.trim(),
            adresse: _adresseCtrl.text.trim().isEmpty
                ? 'Adresse nicht angegeben'
                : _adresseCtrl.text.trim(),
            latitude: _latitude,
            longitude: _longitude,
          );
      if (!mounted) return;
      AppSnackbar.show(context, message: 'Anfrage eingereicht – danke!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, message: 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickFlyer(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _flyerFile = File(picked.path));
  }

  void _showPickerSheet() {
    showAppSheet<void>(
      context,
      (ctx) => AppSheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetHeader(
              icon: Icons.add_photo_alternate_outlined,
              iconColor: _kAccent,
              title: 'Bild auswählen',
            ),
            const SizedBox(height: 16),
            _PickerTile(
              icon: Icons.photo_library_outlined,
              label: 'Aus Galerie',
              onTap: () {
                Navigator.pop(ctx);
                _pickFlyer(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
            _PickerTile(
              icon: Icons.camera_alt_outlined,
              label: 'Kamera',
              onTap: () {
                Navigator.pop(ctx);
                _pickFlyer(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFlyer() async {
    if (_flyerFile == null) {
      AppSnackbar.show(context, message: 'Bitte einen Flyer auswählen');
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<IAuthRepository>().submitEventRequestFlyer(
            _flyerFile!,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      if (!mounted) return;
      AppSnackbar.show(context, message: 'Flyer eingereicht – danke!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, message: 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _tabButton(String label, int index) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? _kAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.white54,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
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
        border: Border.all(color: Colors.white.withValues(alpha: _kGlassBorder)),
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
                'Ähnliche Events gefunden',
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
            'Prüfe ob dieses Event bereits existiert.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...List.generate(_similarEvents.length, (i) {
            final e = _similarEvents[i];
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd.MM.yyyy').format(e.datum.toLocal()),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
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

  Widget _buildManualTab() {
    return Column(
      children: [
        TextField(
          controller: _nameCtrl,
          style: _kInputTextStyle,
          decoration: _inputStyle('Eventname'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _datumCtrl,
          style: _kInputTextStyle,
          decoration: _inputStyle(
            'Datum',
            suffixIcon: const Icon(Icons.calendar_today_outlined,
                color: Colors.white38, size: 20),
          ),
          readOnly: true,
          onTap: () async {
            final picked = await showPlatformDatePicker(
              context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                _datumCtrl.text = DateFormat('dd.MM.yyyy').format(picked);
              });
              _updateSimilarEvents();
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _uhrzeitCtrl,
          style: _kInputTextStyle,
          decoration: _inputStyle('Uhrzeit (HH:MM)'),
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _standortCtrl,
          style: _kInputTextStyle,
          decoration: _inputStyle('Standort'),
        ),
        const SizedBox(height: 16),
        PlacesAutocompleteField(
          controller: _adresseCtrl,
          decoration: _inputStyle('genaue Adresse'),
          textStyle: _kInputTextStyle,
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
          initialValue: _typ,
          dropdownColor: const Color(0xFF1B3A6B),
          style: _kInputTextStyle,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white54),
          decoration: const InputDecoration(
            labelText: 'Event-Typ',
            labelStyle: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500),
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
          onChanged: (v) => setState(() => _typ = v ?? 'e0'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _beschreibungCtrl,
          style: _kInputTextStyle,
          decoration: _inputStyle('Beschreibung'),
          keyboardType: TextInputType.multiline,
          maxLines: null,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: 24),
        _buildSimilarEventsSection(),
        if (_similarEvents.isNotEmpty) const SizedBox(height: 16),
        _submitButton('Anfrage einreichen', _submitting ? null : _submitManual),
      ],
    );
  }

  Widget _buildFlyerTab() {
    return Column(
      children: [
        // Bild-Preview / Picker
        GestureDetector(
          onTap: _showPickerSheet,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _kGlassAlpha),
              border: Border.all(
                color: _flyerFile == null
                    ? Colors.white.withValues(alpha: _kGlassBorder)
                    : _kAccent.withValues(alpha: 0.5),
                width: _flyerFile == null ? 1 : 2,
              ),
              borderRadius: BorderRadius.circular(_kRadius),
            ),
            child: _flyerFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: Colors.white38, size: 40),
                      const SizedBox(height: 10),
                      const Text('Flyer auswählen',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(_kRadius),
                    child: Image.file(_flyerFile!, fit: BoxFit.cover,
                        width: double.infinity),
                  ),
          ),
        ),
        if (_flyerFile != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _showPickerSheet,
            icon: const Icon(Icons.swap_horiz, color: _kAccent, size: 18),
            label: const Text('Anderes Bild',
                style: TextStyle(color: _kAccent, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _noteCtrl,
          style: _kInputTextStyle.copyWith(fontSize: 16),
          decoration: _inputStyle('Notiz (optional)'),
          keyboardType: TextInputType.multiline,
          maxLines: null,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: 24),
        _submitButton('Flyer einreichen', _submitting ? null : _submitFlyer),
      ],
    );
  }

  Widget _submitButton(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: _kButtonHeight,
        decoration: BoxDecoration(
          color: onTap == null
              ? _kAccent.withValues(alpha: 0.4)
              : _kAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _submitting
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
                  const Icon(Icons.send_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
          title: const Text('Event vorschlagen',
              style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(_kPadding),
          child: Column(
            children: [
              // Tab-Umschalter
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: _kGlassAlpha),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: _kGlassBorder)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _tabButton('Manuell', 0),
                    const SizedBox(width: 4),
                    _tabButton('Flyer hochladen', 1),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _tab == 0 ? _buildManualTab() : _buildFlyerTab(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFF5A04A), size: 20),
              const SizedBox(width: 14),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
