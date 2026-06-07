// places_autocomplete_field.dart
//
// Ersatz für GooglePlaceAutoCompleteTextField.
// Vorschläge werden in einem Overlay gerendert, das über dem Layout
// schwebt – kein Scroll-Jump durch Layout-Shift.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _kApiKey = 'AIzaSyBxoCA2nUR69u7aNL2IksnvfBPXjEqQYmM';

class _Prediction {
  final String description;
  final String mainText;
  final String secondaryText;
  final String placeId;
  const _Prediction({
    required this.description,
    required this.mainText,
    required this.secondaryText,
    required this.placeId,
  });
}

class PlacesAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final TextStyle? textStyle;
  final void Function(String name, String fullAddress, double lat, double lng) onPlaceSelected;
  // true (Standard): nur Ortschaften/Gemeinden – für Abfahrtsort und Wohnort
  // false: vollständige Adresssuche inkl. POIs – für Event-Adresse
  final bool localityOnly;

  const PlacesAutocompleteField({
    super.key,
    required this.controller,
    required this.decoration,
    this.textStyle,
    required this.onPlaceSelected,
    this.localityOnly = true,
  });

  @override
  State<PlacesAutocompleteField> createState() =>
      _PlacesAutocompleteFieldState();
}

class _PlacesAutocompleteFieldState extends State<PlacesAutocompleteField> {
  final _link = LayerLink();
  final _focus = FocusNode();
  OverlayEntry? _overlay;
  Timer? _debounce;
  List<_Prediction> _predictions = [];
  // placeId → Postleitzahl, nur für Dropdown-Anzeige
  final Map<String, String> _postalCodes = {};
  // Verhindert dass veraltete PLZ-Fetches das aktuelle Ergebnis überschreiben
  int _fetchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focus.hasFocus) _removeOverlay();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final q = widget.controller.text.trim();
    if (q.length < 2) {
      _predictions = [];
      _removeOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _fetch(q));
  }

  // Entfernt redundante Wiederholung des Hauptnamens:
  // mainText="Seeboden", secondary="Seeboden, Österreich" → "Österreich"
  String _cleanSecondary(String main, String secondary) {
    final prefix = '$main, ';
    if (secondary.startsWith(prefix)) {
      return secondary.substring(prefix.length);
    }
    return secondary;
  }

  // Baut die Subzeile: "9871 · Kärnten" — "Österreich" wird weggelassen.
  String _buildSubline(String placeId, String rawSecondary) {
    var region = rawSecondary
        .replaceAll(', Österreich', '')
        .replaceAll('Österreich', '')
        .trim();
    if (region.endsWith(',')) region = region.substring(0, region.length - 1).trim();

    final plz = _postalCodes[placeId];
    if (plz != null && plz.isNotEmpty) {
      return region.isNotEmpty ? '$plz · $region' : plz;
    }
    return region.isNotEmpty ? region : rawSecondary;
  }

  Future<void> _fetch(String query) async {
    final gen = ++_fetchGeneration;
    _postalCodes.clear();

    try {
      final res = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _kApiKey,
          'X-Goog-FieldMask':
              'suggestions.placePrediction.placeId,'
              'suggestions.placePrediction.text,'
              'suggestions.placePrediction.structuredFormat',
        },
        body: jsonEncode({
          'input': query,
          'includedRegionCodes': ['at'],
          'languageCode': 'de',
          if (widget.localityOnly)
            'includedPrimaryTypes': ['locality', 'sublocality'],
        }),
      );
      if (!mounted || gen != _fetchGeneration) return;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final seen = <String>{};
      _predictions = (data['suggestions'] as List? ?? [])
          .map((s) {
            final p = s['placePrediction'] as Map<String, dynamic>? ?? {};
            final desc = (p['text']?['text'] as String?) ?? '';
            final main =
                (p['structuredFormat']?['mainText']?['text'] as String?) ?? desc;
            final rawSecondary =
                (p['structuredFormat']?['secondaryText']?['text'] as String?) ?? '';
            final secondary = _cleanSecondary(main, rawSecondary);
            return _Prediction(
              description: desc,
              mainText: main,
              secondaryText: secondary,
              placeId: p['placeId'] as String? ?? '',
            );
          })
          .where((p) => p.placeId.isNotEmpty && seen.add(p.mainText.toLowerCase()))
          .take(5)
          .toList();

      if (_predictions.isEmpty || !_focus.hasFocus) {
        _removeOverlay();
      } else {
        _showOrUpdate();
        // PLZ für alle Vorschläge parallel nachladen
        for (final pred in _predictions) {
          _fetchPostalCode(pred.placeId, gen);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchPostalCode(String placeId, int gen) async {
    try {
      final res = await http.get(
        Uri.parse('https://places.googleapis.com/v1/places/$placeId'),
        headers: {
          'X-Goog-Api-Key': _kApiKey,
          'X-Goog-FieldMask': 'addressComponents',
        },
      );
      if (!mounted || gen != _fetchGeneration) return;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final components = (data['addressComponents'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final entry = components.firstWhere(
        (c) => (c['types'] as List?)?.contains('postal_code') ?? false,
        orElse: () => {},
      );
      final plz = entry['longText'] as String? ?? '';
      if (plz.isNotEmpty) {
        _postalCodes[placeId] = plz;
        _overlay?.markNeedsBuild();
      }
    } catch (_) {}
  }

  Future<void> _select(_Prediction p) async {
    widget.controller.text = p.mainText;
    widget.controller.selection =
        TextSelection.collapsed(offset: p.mainText.length);
    _predictions = [];
    _removeOverlay();
    _focus.unfocus();

    try {
      final res = await http.get(
        Uri.parse('https://places.googleapis.com/v1/places/${p.placeId}'),
        headers: {
          'X-Goog-Api-Key': _kApiKey,
          'X-Goog-FieldMask': 'location',
        },
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final loc = data['location'];
      if (loc != null) {
        widget.onPlaceSelected(
          p.mainText,
          p.description,
          (loc['latitude'] as num).toDouble(),
          (loc['longitude'] as num).toDouble(),
        );
      }
    } catch (_) {}
  }

  void _showOrUpdate() {
    if (_overlay == null) {
      _overlay = _buildEntry();
      Overlay.of(context).insert(_overlay!);
    } else {
      _overlay!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  OverlayEntry _buildEntry() {
    return OverlayEntry(
      builder: (_) {
        final box = context.findRenderObject() as RenderBox?;
        final width = (box != null && box.hasSize) ? box.size.width : 300.0;
        final fieldHeight = (box != null && box.hasSize) ? box.size.height : 60.0;

        return Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset(0, fieldHeight + 2),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3F78),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < _predictions.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              height: 1,
                              color: Colors.white24,
                              indent: 16,
                              endIndent: 16,
                            ),
                          InkWell(
                            onTap: () => _select(_predictions[i]),
                            child: Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                      color: Color(0xFF5DA9FF), width: 3),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      color: Color(0xFF5DA9FF), size: 18),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Builder(
                                      builder: (_) {
                                        final sub = _buildSubline(
                                          _predictions[i].placeId,
                                          _predictions[i].secondaryText,
                                        );
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _predictions[i].mainText,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (sub.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                sub,
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        style: widget.textStyle,
        decoration: widget.decoration,
      ),
    );
  }
}