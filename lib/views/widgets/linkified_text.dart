import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final _urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);

/// Zeigt Text an und macht enthaltene http(s)-Links antippbar (öffnen extern
/// im Browser) — z.B. für Ticket-Links in Event-Beschreibungen.
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

    final matches = _urlPattern.allMatches(widget.text);
    if (matches.isEmpty) {
      return Text(widget.text, style: widget.style);
    }

    final spans = <InlineSpan>[];
    var lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: widget.text.substring(lastEnd, match.start)));
      }

      // Satzzeichen am Ende ausschließen (z.B. "https://x.at." → Punkt gehört
      // zum Satz, nicht zur URL).
      var url = match.group(0)!;
      var end = match.end;
      while (url.isNotEmpty && '.,!?;:)'.contains(url[url.length - 1])) {
        url = url.substring(0, url.length - 1);
        end--;
      }

      final recognizer = TapGestureRecognizer()..onTap = () => _open(url);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: url,
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
