import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Erkennt entweder "[Text](https://…)" (eigener, kurzer Linktext), eine
// nackte URL (wird dann selbst als Linktext angezeigt) oder eine
// österreichische Telefonnummer (z.B. für Festbus-Hotlines).
// Telefon-Erkennung: beginnt mit "+43", "0043" oder "0", danach 6–12 weitere
// Ziffern (optional getrennt durch Leerzeichen, "/" oder "-"). Punkt ist
// bewusst kein erlaubtes Trennzeichen, damit Datumsangaben (z.B. "13.07.2026")
// nicht fälschlich als Telefonnummer erkannt werden.
final _linkPattern = RegExp(
  r'\[([^\]]+)\]\((https?://[^\s)]+)\)'
  r'|(https?://[^\s]+)'
  r'|((?<![\d.])(?:\+43[\s/-]?|0043[\s/-]?|0)(?:[\s/-]?\d){6,12}(?!\d))',
  caseSensitive: false,
);

/// Zeigt Text an und macht enthaltene http(s)-Links sowie Telefonnummern
/// antippbar — Links öffnen extern im Browser, Telefonnummern öffnen die
/// Telefon-App mit vorausgefüllter Nummer (z.B. für Ticket-Links oder
/// Festbus-Hotlines in Event-Beschreibungen).
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

  Future<void> _call(String rawNumber) async {
    var number = rawNumber.replaceAll(RegExp(r'[\s/-]'), '');
    if (number.startsWith('0043')) {
      number = '+43${number.substring(4)}';
    }
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
      VoidCallback onTap;
      if (match.group(2) != null) {
        // "[Text](URL)" — Linktext frei gewählt, URL bleibt unangetastet.
        label = match.group(1)!;
        final url = match.group(2)!;
        onTap = () => _open(url);
      } else if (match.group(4) != null) {
        // Telefonnummer — antippbar, öffnet die Telefon-App.
        label = match.group(4)!;
        final number = label;
        onTap = () => _call(number);
      } else {
        // Nackte URL — Satzzeichen am Ende ausschließen (z.B. "https://x.at."
        // → Punkt gehört zum Satz, nicht zur URL).
        var url = match.group(3)!;
        while (url.isNotEmpty && '.,!?;:)'.contains(url[url.length - 1])) {
          url = url.substring(0, url.length - 1);
          end--;
        }
        label = url;
        onTap = () => _open(url);
      }

      final recognizer = TapGestureRecognizer()..onTap = onTap;
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
