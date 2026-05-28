// places_autocomplete_field.dart
//
// Ersatz für GooglePlaceAutoCompleteTextField.
// Vorschläge werden in einem Overlay gerendert, das über dem Layout
// schwebt – kein Scroll-Jump durch Layout-Shift.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _kApiKey = 'AIzaSyB97RZAMf-fmZKhdFFniU20CqK0QWCV3KE';

class _Prediction {
  final String description;
  final String mainText;
  final String placeId;
  const _Prediction({
    required this.description,
    required this.mainText,
    required this.placeId,
  });
}

class PlacesAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final TextStyle? textStyle;
  final void Function(String name, String fullAddress, double lat, double lng) onPlaceSelected;

  const PlacesAutocompleteField({
    super.key,
    required this.controller,
    required this.decoration,
    this.textStyle,
    required this.onPlaceSelected,
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
    _debounce =
        Timer(const Duration(milliseconds: 500), () => _fetch(q));
  }

  Future<void> _fetch(String query) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=$_kApiKey'
        '&components=country:at'
        '&language=de',
      );
      final res = await http.get(url);
      if (!mounted) return;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _predictions = (data['predictions'] as List? ?? [])
          .take(5)
          .map((p) {
            final desc = p['description'] as String? ?? '';
            final main = (p['structured_formatting']?['main_text'] as String?)
                ?? desc;
            return _Prediction(
              description: desc,
              mainText: main,
              placeId: p['place_id'] as String? ?? '',
            );
          })
          .where((p) => p.placeId.isNotEmpty)
          .toList();

      if (_predictions.isEmpty || !_focus.hasFocus) {
        _removeOverlay();
      } else {
        _showOrUpdate();
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
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${p.placeId}'
        '&key=$_kApiKey'
        '&fields=geometry',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final loc = data['result']?['geometry']?['location'];
      if (loc != null) {
        widget.onPlaceSelected(
          p.mainText,
          p.description,
          (loc['lat'] as num).toDouble(),
          (loc['lng'] as num).toDouble(),
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
        final width =
            (box != null && box.hasSize) ? box.size.width : 300.0;
        final fieldHeight =
            (box != null && box.hasSize) ? box.size.height : 60.0;

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
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: Color(0xFF5DA9FF), size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _predictions[i].description,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
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
