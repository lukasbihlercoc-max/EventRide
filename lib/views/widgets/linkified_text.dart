import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Erkennt entweder "[Text](https://…)" (eigener, kurzer Linktext) oder eine
// nackte URL (wird dann selbst als Linktext angezeigt).
final _linkPattern = RegExp(
  r'\[([^\]]+)\]\((https?://[^\s)]+)\)|(https?://[^\s]+)',
  caseSensitive: false,
);

/// Zeigt Text an und macht enthaltene http(s)-Links antippbar (öffnen extern
/// im Browser) — z.B. für Ticket-Links in Event-Beschreibungen.
/// Unterstützt sowohl nackte URLs als auch "[Linktext](URL)" für einen
/// kurzen, selbst gewählten Linktext statt der vollen URL.
class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const LinkifiedText(this.text, {super.key, this.style});

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final matches = _linkPattern.allMatches(widget.text);
    if (matches.isEmpty) {
      return Text(widget.text, style: widget.style);
    }

    final spans = <InlineSpan>[];
    var lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: widget.text.substring(lastEnd, match.start)));
      }

      var end = match.end;
      String label;
      String url;
      if (match.group(2) != null) {
        // "[Text](URL)" — Linktext frei gewählt, URL bleibt unangetastet.
        label = match.group(1)!;
        url = match.group(2)!;
      } else {
        // Nackte URL — Satzzeichen am Ende ausschließen (z.B. "https://x.at."
        // → Punkt gehört zum Satz, nicht zur URL).
        url = match.group(3)!;
        while (url.isNotEmpty && '.,!?;:)'.contains(url[url.length - 1])) {
          url = url.substring(0, url.length - 1);
          end--;
        }
        label = url;
      }

      final recognizer = TapGestureRecognizer()..onTap = () => _open(url);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFFF5A04A),
          decoration: TextDecoration.underline,
        ),
        recognizer: recognizer,
      ));
      lastEnd = end;
    }
    if (lastEnd < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(lastEnd)));
    }

    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
