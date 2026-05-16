// chat_system_widget.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_app/data/chat_message.dart';

class ChatSystemMessage extends StatelessWidget {
  final ChatMessage message;

  const ChatSystemMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final lines = message.text.split('\n');

String? event;
String? strecke;
String? angefragt;
String? akzeptiert;

for (final l in lines) {
  if (l.startsWith('Event:')) event = l.replaceFirst('Event:', '').trim();
  if (l.startsWith('Strecke:')) strecke = l.replaceFirst('Strecke:', '').trim();
  if (l.startsWith('Angefragt:')) angefragt = l;
  if (l.startsWith('Akzeptiert:')) akzeptiert = l;
}

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.lightBlueAccent.withValues(alpha:0.25),
                  Colors.blueAccent.withValues(alpha:0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.lightBlueAccent.withValues(alpha:0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.info_outline,
                      color: Colors.lightBlueAccent,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Mitfahr-Info",
                      style: TextStyle(
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (event != null)
  Text(
    event,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
  ),

if (strecke != null) ...[
  const SizedBox(height: 4),
  Text(
    strecke,
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 14,
    ),
  ),
],

const SizedBox(height: 12),

Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    if (angefragt != null)
      _infoChip(
        text: angefragt,
        color: Colors.lightBlueAccent,
      ),
    if (akzeptiert != null)
      _infoChip(
        text: akzeptiert,
        color: Colors.greenAccent,
      ),
  ],
),

              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _infoChip({
  required String text,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha:0.15),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha:0.6)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

}
