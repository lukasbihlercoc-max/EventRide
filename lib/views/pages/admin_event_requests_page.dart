// admin_event_requests_page.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:my_app/utils/platform_pickers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/views/widgets/places_autocomplete_field.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/event_request.dart';
import 'package:my_app/data/event_service.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/views/widgets/app_bottom_sheet.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:provider/provider.dart';

const _kAccent = Color(0xFF5DA9FF);
const _kOrange = Color(0xFFF5A04A);
const _kGreen = Color(0xFF2D6A4F);
const _kRed = Color(0xFFE63946);

const _kTypLabels = {
  'e0': 'Standart',
  'e1': 'Kirchtage/Feste',
  'e2': 'Feuerwehrfest',
  'e3': 'Disco',
  'e4': 'Ball',
  'e5': 'Krampuslauf',
  'e6': 'Festival/Open-Air',
};

InputDecoration _inputStyle(String label, {Widget? suffixIcon}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
        color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white38, width: 1.5),
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: _kAccent, width: 2.5),
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
    suffixIcon: suffixIcon,
  );
}

const _kInputText = TextStyle(color: Colors.white, fontSize: 15);

class AdminEventRequestsPage extends StatelessWidget {
  const AdminEventRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<IAuthRepository>();

    if (!auth.isAdmin) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1F2E),
        body: Center(
          child: Text('Kein Zugriff',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Event-Anfragen',
              style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: StreamBuilder<List<EventRequest>>(
          stream: auth.pendingEventRequests,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Fehler: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent)),
              );
            }

            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white38, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text('Keine offenen Anfragen',
                        style: TextStyle(color: Colors.white70, fontSize: 15)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final req = requests[i];
                return _RequestCard(
                  request: req,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF1A1F2E),
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => _ReviewSheet(request: req),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REQUEST CARD
// ─────────────────────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final EventRequest request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = request.submittedAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final isFlyer = request.submissionType == 'flyer';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF2A3044),
              backgroundImage: request.userPhotoUrl != null
                  ? NetworkImage(request.userPhotoUrl!)
                  : null,
              child: request.userPhotoUrl == null
                  ? Text(
                      request.userName.isNotEmpty
                          ? request.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.eventName?.isNotEmpty == true
                        ? request.eventName!
                        : request.userName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'von ${request.userName} · $dateStr',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isFlyer ? _kOrange : _kAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isFlyer ? 'Flyer' : 'Manuell',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEW SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewSheet extends StatefulWidget {
  final EventRequest request;
  const _ReviewSheet({required this.request});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  // Formular-Controller
  late final TextEditingController _nameCtrl;
  late final TextEditingController _standortCtrl;
  late final TextEditingController _datumCtrl;
  late final TextEditingController _adresseCtrl;
  late final TextEditingController _beschreibungCtrl;
  late String _typ;
  double? _latitude;
  double? _longitude;

  // Flyer
  Uint8List? _flyerBytes;
  bool _loadingFlyer = false;
  String? _flyerError;

  // Ähnliche Events
  List<Event> _similarEvents = [];
  Timer? _debounceTimer;

  bool _actioning = false;

  @override
  void initState() {
    super.initState();
    final req = widget.request;
    _nameCtrl = TextEditingController(text: req.eventName ?? '');
    _standortCtrl = TextEditingController(text: req.standort ?? '');
    _datumCtrl = TextEditingController(text: req.datum ?? '');
    _adresseCtrl = TextEditingController(text: req.adresse ?? '');
    _beschreibungCtrl = TextEditingController(text: req.beschreibung ?? '');
    _typ = _kTypLabels.containsKey(req.eventTyp) ? req.eventTyp! : 'e0';
    _latitude = req.latitude;
    _longitude = req.longitude;

    if (req.submissionType == 'flyer' && req.flyerPath != null) {
      _loadFlyer(req.flyerPath!);
    }

    _nameCtrl.addListener(_onTextChanged);
    _adresseCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameCtrl.dispose();
    _standortCtrl.dispose();
    _datumCtrl.dispose();
    _adresseCtrl.dispose();
    _beschreibungCtrl.dispose();
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
    final tokensA = a.toLowerCase().split(RegExp(r'\s+')).where((t) => t.length > 1).toSet();
    final tokensB = b.toLowerCase().split(RegExp(r'\s+')).where((t) => t.length > 1).toSet();
    if (tokensA.isEmpty && tokensB.isEmpty) return 1.0;
    if (tokensA.isEmpty || tokensB.isEmpty) return 0.0;
    return tokensA.intersection(tokensB).length / tokensA.union(tokensB).length;
  }

  bool _sameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _updateSimilarEvents() {
    if (!mounted) return;
    final enteredName = _nameCtrl.text.trim();
    if (enteredName.isEmpty) {
      setState(() => _similarEvents = []);
      return;
    }
    DateTime? enteredDate;
    try {
      if (_datumCtrl.text.trim().isNotEmpty) {
        enteredDate = DateFormat('dd.MM.yyyy').parseStrict(_datumCtrl.text.trim(), true);
      }
    } catch (_) {}
    final enteredAdresse = _adresseCtrl.text.trim();
    final allEvents = context.read<EventService>().events;
    final scored = <({Event event, double score})>[];
    for (final candidate in allEvents) {
      final nameScore = _jaccard(enteredName, candidate.name);
      final dateScore = (enteredDate != null && _sameCalendarDay(enteredDate, candidate.datum.toLocal())) ? 1.0 : 0.0;
      final addrScore = enteredAdresse.isNotEmpty ? _jaccard(enteredAdresse, candidate.adresse) : 0.0;
      final composite = nameScore * 0.5 + dateScore * 0.3 + addrScore * 0.2;
      if (composite >= 0.3 || nameScore >= 0.7) {
        scored.add((event: candidate, score: composite));
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    setState(() => _similarEvents = scored.take(5).map((r) => r.event).toList());
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
        style: const TextStyle(color: _kAccent, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSimilarEventsSection() {
    if (_similarEvents.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFF5A623), size: 18),
              SizedBox(width: 8),
              Text(
                'Ähnliche Events gefunden',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd.MM.yyyy').format(e.datum.toLocal()),
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
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

  Future<void> _loadFlyer(String path) async {
    setState(() => _loadingFlyer = true);
    try {
      final bytes = await FirebaseStorage.instance.ref(path).getData(8 * 1024 * 1024);
      if (mounted) setState(() => _flyerBytes = bytes);
    } catch (e) {
      if (mounted) setState(() => _flyerError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingFlyer = false);
    }
  }

  Future<void> _publish() async {
    if (_datumCtrl.text.trim().isEmpty) {
      AppSnackbar.show(context, message: 'Bitte ein Datum eintragen');
      return;
    }
    DateTime parsedDate;
    try {
      parsedDate =
          DateFormat('dd.MM.yyyy').parseStrict(_datumCtrl.text.trim(), true);
    } catch (_) {
      AppSnackbar.show(context, message: 'Ungültiges Datumformat (TT.MM.JJJJ)');
      return;
    }

    setState(() => _actioning = true);
    try {
      final event = Event(
        name: _nameCtrl.text.trim().isEmpty
            ? 'Unbenanntes Event'
            : _nameCtrl.text.trim(),
        datum: parsedDate,
        standort: _standortCtrl.text.trim().isEmpty
            ? 'Unbekannt'
            : _standortCtrl.text.trim(),
        typ: _typ,
        beschreibung: _beschreibungCtrl.text.trim(),
        adresse: _adresseCtrl.text.trim().isEmpty
            ? 'Adresse nicht angegeben'
            : _adresseCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      await context
          .read<IAuthRepository>()
          .approveEventRequest(widget.request.id, event);

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.show(context, message: 'Event veröffentlicht.');
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, message: 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  Future<void> _discard() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showAppSheet<bool>(
      context,
      (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AppSheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSheetHeader(
                icon: Icons.block,
                iconColor: const Color(0xFFE53935),
                title: 'Anfrage verwerfen?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: sheetInputDecoration(
                  label: 'Ablehnungsgrund (optional)',
                ),
              ),
              const SizedBox(height: 22),
              AppSheetDangerButton(
                label: 'Verwerfen',
                onTap: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 10),
              AppSheetGhostButton(
                label: 'Abbrechen',
                onTap: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        ),
      ),
    );
    final reason =
        reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _actioning = true);
    try {
      await context
          .read<IAuthRepository>()
          .discardEventRequest(widget.request.id, reason: reason);
      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.show(context, message: 'Anfrage verworfen.');
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, message: 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  Widget _buildFlyerSection() {
    if (widget.request.submissionType != 'flyer') return const SizedBox.shrink();

    Widget flyerWidget;
    if (_loadingFlyer) {
      flyerWidget = const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(color: Colors.white54)),
      );
    } else if (_flyerBytes != null) {
      flyerWidget = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(_flyerBytes!,
            fit: BoxFit.contain, width: double.infinity),
      );
    } else {
      flyerWidget = SizedBox(
        height: 100,
        child: Center(
          child: Text(
            _flyerError != null
                ? 'Flyer konnte nicht geladen werden'
                : 'Kein Flyer',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: flyerWidget,
        ),
        if (widget.request.note?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(
            'Notiz: ${widget.request.note}',
            style:
                const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
        const SizedBox(height: 4),
        const Divider(color: Colors.white12, height: 24),
        const Text(
          'Event-Daten eintragen',
          style: TextStyle(
              color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameCtrl,
          style: _kInputText,
          decoration: _inputStyle('Eventname'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _datumCtrl,
          style: _kInputText,
          decoration: _inputStyle('Datum',
              suffixIcon: const Icon(Icons.calendar_today_outlined,
                  color: Colors.white38, size: 18)),
          readOnly: true,
          onTap: () async {
            DateTime initial = DateTime.now();
            if (_datumCtrl.text.trim().isNotEmpty) {
              try {
                initial = DateFormat('dd.MM.yyyy')
                    .parseStrict(_datumCtrl.text.trim(), true);
              } catch (_) {}
            }
            final picked = await showPlatformDatePicker(
              context,
              initialDate: initial,
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
        const SizedBox(height: 12),
        TextField(
          controller: _standortCtrl,
          style: _kInputText,
          decoration: _inputStyle('Standort'),
        ),
        const SizedBox(height: 12),
        PlacesAutocompleteField(
          controller: _adresseCtrl,
          decoration: _inputStyle('genaue Adresse'),
          textStyle: _kInputText,
          localityOnly: false,
          onPlaceSelected: (_, __, lat, lng) {
            setState(() {
              _latitude = lat;
              _longitude = lng;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _typ,
          dropdownColor: const Color(0xFF1B3A6B),
          style: _kInputText,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white54),
          decoration: const InputDecoration(
            labelText: 'Event-Typ',
            labelStyle: TextStyle(
                color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white38, width: 1.5),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _kAccent, width: 2.5),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            contentPadding:
                EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          ),
          items: _kTypLabels.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _typ = v ?? 'e0'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _beschreibungCtrl,
          style: _kInputText,
          decoration: _inputStyle('Beschreibung'),
          keyboardType: TextInputType.multiline,
          maxLines: null,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2A3044),
                backgroundImage: widget.request.userPhotoUrl != null
                    ? NetworkImage(widget.request.userPhotoUrl!)
                    : null,
                child: widget.request.userPhotoUrl == null
                    ? Text(
                        widget.request.userName.isNotEmpty
                            ? widget.request.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.request.userName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.request.submissionType == 'flyer'
                      ? _kOrange
                      : _kAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.request.submissionType == 'flyer'
                      ? 'Flyer'
                      : 'Manuell',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollbarer Inhalt
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFlyerSection(),
                  _buildSimilarEventsSection(),
                  if (_similarEvents.isNotEmpty) const SizedBox(height: 12),
                  _buildForm(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Action-Buttons
          if (_actioning)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Verwerfen',
                    color: _kRed,
                    onTap: _discard,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'Veröffentlichen',
                    color: _kGreen,
                    onTap: _publish,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
