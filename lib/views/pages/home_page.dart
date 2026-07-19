// home_page.dart
import 'dart:io';
import 'dart:ui';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/utils/platform_pickers.dart';
import 'package:my_app/utils/geo_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/data/notifiers.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/views/pages/email_verification_page.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/sizehelper_widget.dart';
import 'package:my_app/views/widgets/suchleiste_widget.dart';
import 'package:my_app/views/widgets/eventcard_widget.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/views/pages/app_info_page.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kGlassRadius = 20.0;
const _kAccent      = Color(0xFFF5A04A);
const _kAccentDark  = Color(0xFF1A2030);

// ─── Glass-Surface Decoration ─────────────────────────────────────────────────
BoxDecoration _glassDeco({required bool active}) => BoxDecoration(
      color: active
          ? Colors.white.withValues(alpha: 0.28)
          : Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(_kGlassRadius),
      border: Border.all(
        color: active
            ? Colors.white.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.32),
        width: active ? 1.3 : 1.0,
      ),
      boxShadow: active
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );

TextStyle _chipTextStyle({required bool active}) => TextStyle(
      color: active ? Colors.white : Colors.white.withValues(alpha: 0.65),
      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
      fontSize: 13,
      letterSpacing: 0,
    );

// ─── Isolated BackdropFilter Widget ───────────────────────────────────────────
class _GlassSurface extends StatelessWidget {
  final Widget child;
  final double width;

  const _GlassSurface({
    required this.child,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(20, 30, 50, 0.25),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Glass Overlay Menu ────────────────────────────────────────────────────────
Future<T?> _showGlassMenu<T>({
  required BuildContext context,
  required GlobalKey anchorKey,
  required List<({T value, String label})> options,
  required T? selected,
}) async {
  final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null) return null;
  final offset = box.localToGlobal(Offset.zero);
  final size   = box.size;

  const menuWidth = 200.0;
  const margin    = 8.0;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'menu',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (ctx, anim, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final screenW = MediaQuery.of(ctx).size.width;
      final left = (offset.dx).clamp(margin, screenW - menuWidth - margin);
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return Stack(
        children: [
          // Scrim
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          // Menu
          Positioned(
            left: left,
            top: offset.dy + size.height + 8,
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
                alignment: Alignment.topCenter,
                child: Material(
                  color: Colors.transparent,
                  child: _GlassSurface(
                    width: menuWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < options.length; i++) ...[
                            if (i > 0)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            Builder(builder: (_) {
                              final opt = options[i];
                              final isSelected = opt.value == selected;
                              return GestureDetector(
                                onTap: () => Navigator.of(ctx).pop(opt.value),
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 44),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.22)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          opt.label,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                                alpha: isSelected ? 1.0 : 0.90),
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w400,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.check,
                                            color: _kAccent, size: 18),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

// ─── Radius Slider Card ────────────────────────────────────────────────────────
class _RadiusSliderCard extends StatefulWidget {
  final GlobalKey anchorKey;
  final int? initialValue;
  final ValueChanged<int?> onChanged;

  const _RadiusSliderCard({
    required this.anchorKey,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_RadiusSliderCard> createState() => _RadiusSliderCardState();
}

class _RadiusSliderCardState extends State<_RadiusSliderCard> {
  static const _stops = [null, 10, 20, 50, 100];
  late double _dragValue; // 0..4

  @override
  void initState() {
    super.initState();
    final idx = _stops.indexOf(widget.initialValue);
    _dragValue = (idx < 0 ? 0 : idx).toDouble();
  }

  int? get _currentStop => _stops[_dragValue.round()];

  String get _label {
    final v = _currentStop;
    return v == null ? 'Alle' : '$v';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ENTFERNUNG',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentStop != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    'km',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Custom track + stops + thumb
        SizedBox(
          height: 40,
          child: LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            const count = 4; // intervals
            final stepW = w / count;
            final thumbX = _dragValue * stepW;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) {
                setState(() {
                  _dragValue = (_dragValue + d.delta.dx / stepW)
                      .clamp(0.0, 4.0);
                });
              },
              onHorizontalDragEnd: (_) {
                final snapped = _dragValue.roundToDouble();
                setState(() => _dragValue = snapped);
                widget.onChanged(_stops[snapped.toInt()]);
              },
              onTapUp: (d) {
                final idx = (d.localPosition.dx / stepW).round().clamp(0, 4);
                setState(() => _dragValue = idx.toDouble());
                widget.onChanged(_stops[idx]);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track background
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Track fill
                  Positioned(
                    top: 12,
                    left: 0,
                    width: thumbX.clamp(0.0, w),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: _kAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Stop dots
                  for (int i = 0; i <= 4; i++)
                    Positioned(
                      top: 7.5,
                      left: i * stepW - 4.5,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: i <= _dragValue.round()
                              ? _kAccent
                              : Colors.white.withValues(alpha: 0.40),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  // Thumb
                  Positioned(
                    top: 0,
                    left: thumbX - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kAccent, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        // Stop labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['Alle', '10', '20', '50', '100'].map((l) {
            return SizedBox(
              width: 28,
              child: Text(
                l,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 11,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

Future<void> _showRadiusCard({
  required BuildContext context,
  required GlobalKey anchorKey,
  required int? current,
  required ValueChanged<int?> onChanged,
}) async {
  final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null) return;
  final offset = box.localToGlobal(Offset.zero);
  final size   = box.size;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'radius',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (ctx, anim, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      const cardWidth = 264.0;
      const margin    = 8.0;
      final screenW = MediaQuery.of(ctx).size.width;
      final left = (offset.dx).clamp(margin, screenW - cardWidth - margin);
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            top: offset.dy + size.height + 8,
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
                alignment: Alignment.topCenter,
                child: Material(
                  color: Colors.transparent,
                  child: _GlassSurface(
                    width: 264,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: _RadiusSliderCard(
                        anchorKey: anchorKey,
                        initialValue: current,
                        onChanged: (v) {
                          onChanged(v);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

// ─── HomePage ──────────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = TextEditingController();
  double? _homeTownLat;
  double? _homeTownLng;
  bool _showFavourites = false;

  final _radiusKey = GlobalKey();
  final _datumKey  = GlobalKey();
  final _typKey    = GlobalKey();

  static const _typOptionen = {
    'e1': 'Kirchtage & Feste',
    'e2': 'Feuerwehrfeste',
    'e3': 'Disco & Party',
    'e4': 'Bälle',
    'e5': 'Krampus & Perchten',
    'e6': 'Festivals & Open Air',
    'e7': 'Beach & Sommer',
  };

  String _radiusLabel(int? value) {
    if (value == null) return 'Entfernung';
    return '$value km';
  }

  String _datumFilterLabel() {
    final mode = selectedDatumModeNotifier.value;
    if (mode == 'heute') return 'Heute';
    if (mode == 'wochenende') return 'Wochenende';
    if (mode == 'datum' && selectedDatumNotifier.value != null) {
      return DateFormat('dd.MM.').format(selectedDatumNotifier.value!);
    }
    return 'Datum';
  }

  String _typFilterLabel() {
    final typ = selectedTypNotifier.value;
    return typ != null ? (_typOptionen[typ] ?? 'Typ') : 'Typ';
  }

  bool _isThisWeekend(DateTime eventDatum, DateTime today) {
    final eventDay = DateTime(
      eventDatum.toLocal().year,
      eventDatum.toLocal().month,
      eventDatum.toLocal().day,
    );
    if (eventDay.weekday < 5) return false;
    final todayWd = today.weekday;
    final DateTime friday;
    if (todayWd <= 5) {
      friday = today.add(Duration(days: 5 - todayWd));
    } else {
      friday = today.subtract(Duration(days: todayWd - 5));
    }
    final sunday = friday.add(const Duration(days: 2));
    return !eventDay.isBefore(friday) && !eventDay.isAfter(sunday);
  }

  Future<void> _pickDate() async {
    final picked = await showPlatformDatePicker(
      context,
      initialDate: selectedDatumNotifier.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted || picked == null) return;
    selectedDatumNotifier.value = picked;
    selectedDatumModeNotifier.value = 'datum';
  }

  @override
  void initState() {
    super.initState();
    _loadHomeTown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheImages());
    controller.addListener(() => searchTextNotifier.value = controller.text);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _precacheImages() {
    const images = [
      'assets/image/kirchtag6.jpg',
      'assets/image/feuerwehr.png',
      'assets/image/disco.jpg',
      'assets/image/Ball.jpg',
      'assets/image/krampus.jpg',
      'assets/image/kirchtag.jpg',
      'assets/image/festival4.jpg',
    ];
    for (final path in images) {
      precacheImage(AssetImage(path), context);
    }
  }

  Future<void> _loadHomeTown() async {
    final coords = await context.read<IAuthRepository>().getHomeTownCoords();
    if (!mounted) return;
    setState(() {
      _homeTownLat = coords.lat;
      _homeTownLng = coords.lng;
    });
  }

  // ── Chip container (38px tall, 14px h-padding) ───────────────────────────
  Widget _chip({
    required GlobalKey key,
    required bool active,
    required String label,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return _TapScaleWrapper(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          key: key,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: _glassDeco(active: active),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: _chipTextStyle(active: active)),
              if (showArrow) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.45),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  //! Filterzeile
  Widget _buildFilterRow(BuildContext context) {
    final currentRadius = selectedRadiusNotifier.value;
    final datumMode = selectedDatumModeNotifier.value;
    final selectedTyp = selectedTypNotifier.value;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // ── Favoriten-Button ────────────────────────────────────────────
            _TapScaleWrapper(
              child: GestureDetector(
                onTap: () => setState(() => _showFavourites = !_showFavourites),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: _showFavourites
                      ? BoxDecoration(
                          color: _kAccent,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: _kAccent.withValues(alpha: 0.40),
                              blurRadius: 12,
                            ),
                          ],
                        )
                      : BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.32),
                          ),
                        ),
                  child: Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: _showFavourites
                        ? _kAccentDark
                        : Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // ── Typ ─────────────────────────────────────────────────────────
            _chip(
              key: _typKey,
              active: selectedTyp != null,
              label: _typFilterLabel(),
              onTap: () async {
                final typOptions = [
                  (value: 'alle', label: 'Alle'),
                  ..._typOptionen.entries
                      .map((e) => (value: e.key, label: e.value)),
                ];
                final currentKey = selectedTyp ?? 'alle';
                final result = await _showGlassMenu<String>(
                  context: context,
                  anchorKey: _typKey,
                  options: typOptions,
                  selected: currentKey,
                );
                if (!mounted || result == null) return;
                selectedTypNotifier.value = result == 'alle' ? null : result;
              },
            ),

            const SizedBox(width: 8),

            // ── Datum ───────────────────────────────────────────────────────
            _chip(
              key: _datumKey,
              active: datumMode != null,
              label: _datumFilterLabel(),
              onTap: () async {
                const datumOptions = [
                  (value: 'alle',       label: 'Alle'),
                  (value: 'heute',      label: 'Heute'),
                  (value: 'wochenende', label: 'Dieses Wochenende'),
                  (value: 'datum',      label: 'Datum wählen…'),
                ];
                final currentKey = datumMode ?? 'alle';
                final result = await _showGlassMenu<String>(
                  context: context,
                  anchorKey: _datumKey,
                  options: datumOptions,
                  selected: currentKey,
                );
                if (!mounted || result == null) return;
                if (result == 'datum') {
                  _pickDate();
                } else {
                  selectedDatumModeNotifier.value = result == 'alle' ? null : result;
                  selectedDatumNotifier.value = null;
                }
              },
            ),

            const SizedBox(width: 8),

            // ── Entfernung (Slider) ─────────────────────────────────────────
            if (_homeTownLat == null || _homeTownLng == null)
              _chip(
                key: _radiusKey,
                active: false,
                label: 'Entfernung',
                onTap: () => AppSnackbar.show(
                  context,
                  message: 'Bitte zuerst deine Heimatgemeinde bei der Profilvervollständigung festlegen.',
                ),
              )
            else
              _chip(
                key: _radiusKey,
                active: currentRadius != null,
                label: _radiusLabel(currentRadius),
                onTap: () => _showRadiusCard(
                  context: context,
                  anchorKey: _radiusKey,
                  current: currentRadius,
                  onChanged: (v) => setState(() {
                    selectedRadiusNotifier.value = v;
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBanner(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.emailVerified) return const SizedBox.shrink();

    return Container(
  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: const Color(0xFFFF9800).withValues(alpha: 0.18),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: const Color(0xFFFFB74D).withValues(alpha: 0.65),
      width: 1.2,
    ),
  ),
  child: Row(
    children: [
      const Icon(
        Icons.warning_amber_rounded,
        color: Color(0xFFFFB74D),
        size: 20,
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Text(
          'E-Mail noch nicht bestätigt',
          style: TextStyle(
            color: Color(0xFFFFCC80),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          AppRoute(
            builder: (_) => EmailVerificationPage(
              email: user.email ?? '',
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFCC80).withValues(alpha: 0.5),
            ),
          ),
          child: const Text(
            'Bestätigen',
            style: TextStyle(
              color: Color(0xFFFFD699),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    ],
  ),
);
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () async {
            controller.clear();
            searchTextNotifier.value = '';
          },
          child: ListenableBuilder(
            listenable: Listenable.merge([
              searchTextNotifier,
              eventListNotifier,
              selectedRadiusNotifier,
              selectedDatumModeNotifier,
              selectedDatumNotifier,
              selectedTypNotifier,
            ]),
            builder: (context, _) {
              final query = searchTextNotifier.value.toLowerCase();
              final events = eventListNotifier.value;
              final selectedRadius = selectedRadiusNotifier.value;
              final datumMode = selectedDatumModeNotifier.value;
              final customDatum = selectedDatumNotifier.value;
              final selectedTyp = selectedTypNotifier.value;

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              final favourites = _showFavourites ? favouriteEventsNotifier.value : null;
              final hasCoords = selectedRadius != null &&
                  _homeTownLat != null &&
                  _homeTownLng != null;
              // Test-Events (adminOnly) sind clientseitig ausgeblendet für
              // alle außer Admins — echte Nutzer sollen sie nie zu Gesicht
              // bekommen, auch wenn eine Firestore-Rules-Lücke bei breiten
              // Queries sie theoretisch mitliefern würde.
              final isAdmin = context.read<IAuthRepository>().isAdmin;

              // Kind-Events eines mehrtägigen Containers nach containerId
              // gruppieren (jeweils nach Datum sortiert) — sie erscheinen
              // nie einzeln in der Hauptliste, nur aufgeklappt im Container.
              final childrenByContainer = <String, List<Event>>{};
              for (final e in events) {
                final containerId = e.containerId;
                if (containerId == null) continue;
                childrenByContainer.putIfAbsent(containerId, () => []).add(e);
              }
              for (final list in childrenByContainer.values) {
                list.sort((a, b) => a.datum.compareTo(b.datum));
              }

              bool matchesDatumFilter(DateTime datum) {
                if (datumMode == 'heute') {
                  final d = datum.toLocal();
                  return d.year == today.year &&
                      d.month == today.month &&
                      d.day == today.day;
                } else if (datumMode == 'wochenende') {
                  return _isThisWeekend(datum, today);
                } else if (datumMode == 'datum' && customDatum != null) {
                  final d = datum.toLocal();
                  return d.year == customDatum.year &&
                      d.month == customDatum.month &&
                      d.day == customDatum.day;
                }
                return true;
              }

              // Ein Datums- oder Favoriten-Filter kann nur einen Teil der
              // Tage eines Containers betreffen — dann soll der Container
              // trotzdem erscheinen (wenn mind. ein Tag passt) und beim
              // Aufklappen nur die passenden Tage zeigen.
              final dateFilterActive = datumMode != null;
              final favouritesFilterActive = favourites != null;

              final filteredEvents = events.where((event) {
                if (event.containerId != null) return false;
                if (event.adminOnly && !isAdmin) return false;
                if (query.isNotEmpty &&
                    !event.name.toLowerCase().contains(query) &&
                    !event.standort.toLowerCase().contains(query) &&
                    !event.typ.toLowerCase().contains(query)) {
                  return false;
                }
                final children = childrenByContainer[event.id];
                final hasChildren = children != null && children.isNotEmpty;

                if (favourites != null) {
                  final isFav = hasChildren
                      ? children.any((c) => favourites.contains(c.stabileId))
                      : favourites.contains(event.stabileId);
                  if (!isFav) return false;
                }
                final matchesDate = hasChildren
                    ? children.any((c) => matchesDatumFilter(c.datum))
                    : matchesDatumFilter(event.datum);
                if (!matchesDate) return false;
                if (selectedTyp != null && event.typ != selectedTyp) return false;
                if (hasCoords) {
                  final lat = event.latitude;
                  final lng = event.longitude;
                  if (lat == null || lng == null) return false;
                  final dist = haversineKm(
                      _homeTownLat!, _homeTownLng!, lat, lng);
                  if (dist > selectedRadius) return false;
                }
                return true;
              }).toList();

              return CustomScrollView(
                physics: Platform.isIOS
                    ? const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics())
                    : const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SearchBarDelegate(controller: controller),
                  ),
                  SliverToBoxAdapter(child: _buildVerificationBanner(context)),
                  SliverToBoxAdapter(child: _buildFilterRow(context)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = filteredEvents[index];
                        Widget card;
                        if (event.isContainer) {
                          final containerChildren =
                              childrenByContainer[event.id] ?? [];
                          final filterActive =
                              dateFilterActive || favouritesFilterActive;
                          final visibleChildren = filterActive
                              ? containerChildren.where((c) {
                                  if (favouritesFilterActive &&
                                      !favourites.contains(c.stabileId)) {
                                    return false;
                                  }
                                  if (dateFilterActive &&
                                      !matchesDatumFilter(c.datum)) {
                                    return false;
                                  }
                                  return true;
                                }).toList()
                              : null;
                          card = EventContainerCard(
                            container: event,
                            children: containerChildren,
                            visibleChildren: visibleChildren,
                          );
                        } else {
                          card = EventCard(event: event);
                        }
                        // Dezenter zusätzlicher Abstand zwischen gepinnten
                        // und den restlichen Events.
                        final isFirstUnpinned = !event.pinned &&
                            index > 0 &&
                            filteredEvents[index - 1].pinned;
                        // Section-Header über dem ersten gepinnten Event —
                        // gleiches Muster wie "VERGANGENE FAHRTEN" in
                        // fahrten_page.dart (Divider–Icon–Text–Divider).
                        // Erklärt Nutzern, warum das Event oben steht, und
                        // macht Veranstaltern die Premium-Funktion sichtbar.
                        final isFirstPinned = event.pinned &&
                            (index == 0 || !filteredEvents[index - 1].pinned);
                        return RepaintBoundary(
                          key: ValueKey(event.stabileId),
                          child: isFirstPinned
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(16, 24, 16, 4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: Colors.white
                                                  .withValues(alpha: 0.25),
                                              thickness: 1,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Row(
                                              children: [
                                                Icon(Icons.push_pin,
                                                    size: 16, color: _kAccent),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  'EMPFOHLENE EVENTS',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: Colors.white
                                                  .withValues(alpha: 0.25),
                                              thickness: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    card,
                                  ],
                                )
                              : isFirstUnpinned
                                  ? Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 16, 16, 8),
                                          child: Divider(
                                            color: Colors.white
                                                .withValues(alpha: 0.25),
                                            thickness: 1,
                                          ),
                                        ),
                                        card,
                                      ],
                                    )
                                  : card,
                        );
                      },
                      childCount: filteredEvents.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          AppRoute(builder: (_) => const AppInfoPage()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_location_alt,
                                  color: _kAccent),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Fehlt dein Event? Jetzt vorschlagen',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.60),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: SizeHelper.h(context, 0.15)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── _TapScaleWrapper ──────────────────────────────────────────────────────────
class _TapScaleWrapper extends StatefulWidget {
  final Widget child;
  const _TapScaleWrapper({required this.child});

  @override
  State<_TapScaleWrapper> createState() => _TapScaleWrapperState();
}

class _TapScaleWrapperState extends State<_TapScaleWrapper> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      child: Listener(
        onPointerDown: (_) => setState(() => _scale = 0.95),
        onPointerUp: (_) => setState(() => _scale = 1.0),
        onPointerCancel: (_) => setState(() => _scale = 1.0),
        child: widget.child,
      ),
    );
  }
}
