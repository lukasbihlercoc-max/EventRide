import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';

import 'package:my_app/data/chat_service.dart';
import 'package:my_app/data/chat_message.dart';
import 'package:my_app/views/widgets/app_card.dart';
import 'package:my_app/views/widgets/background_widget.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUserName;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherUserName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final String _myUserId;

  final _scrolledPast = ValueNotifier<bool>(false);
  final _systemInfoKey = GlobalKey();
  double _systemInfoHeight = 130;
  int _prevMessageCount = 0;

  static const double _triggerOffset = 100;

  @override
  void initState() {
    super.initState();
    _myUserId = context.read<IAuthRepository>().currentUser?.userId ?? '';

    _scrollController.addListener(() {
      final past = _scrollController.offset > _triggerOffset;
      if (past != _scrolledPast.value) _scrolledPast.value = past;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _measureSystemBox() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _systemInfoKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final h = box.size.height;
      if ((h - _systemInfoHeight).abs() > 0.5) {
        setState(() => _systemInfoHeight = h);
      }
    });
  }

  @override
  void dispose() {
    _scrolledPast.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.read<ChatService>();

    return StreamBuilder<List<ChatMessage>>(
      stream: chatService.messagesStream(widget.conversationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return AppBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.black.withValues(alpha: 0.18),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                title: Text(widget.otherUserName),
              ),
              body: const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              ),
            ),
          );
        }

        final messages = snapshot.data ?? [];
        final systemMessages = messages.where((m) => m.isSystem).toList();
        final userMessages = messages.where((m) => !m.isSystem).toList();

        if (systemMessages.isNotEmpty) _measureSystemBox();

        if (userMessages.length != _prevMessageCount) {
          _prevMessageCount = userMessages.length;
          _scrollToBottom();
        }

        return AppBackground(
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.black.withOpacity(0.18),
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  title: Text(widget.otherUserName),
                ),
                body: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16 +
                              (systemMessages.isNotEmpty
                                  ? _systemInfoHeight + 16
                                  : 0),
                          16,
                          16,
                        ),
                        itemCount: userMessages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(
                            userMessages[index],
                            _myUserId,
                          );
                        },
                      ),
                    ),
                    _buildInput(context),
                  ],
                  ),
                ),
              ),

              if (systemMessages.isNotEmpty)
                ValueListenableBuilder<bool>(
                  valueListenable: _scrolledPast,
                  builder: (context, past, _) => Positioned(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                    left: 16,
                    right: 16,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: past ? 0 : 1,
                      child: IgnorePointer(
                        ignoring: past,
                        child: TweenAnimationBuilder<double>(
  duration: const Duration(milliseconds: 220),
  tween: Tween(begin: 0.95, end: 1),
  curve: Curves.easeOut,
  builder: (context, scale, child) {
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: scale.clamp(0.0, 1.0),
        child: child,
      ),
    );
  },
  child: Container(
    key: _systemInfoKey,
    child: _buildSystemMessage(
      context,
      systemMessages.last,
    ),
  ),
),
                      ),
                    ),
                  ),
                ),

              if (systemMessages.isNotEmpty)
                ValueListenableBuilder<bool>(
                  valueListenable: _scrolledPast,
                  builder: (context, past, _) => Positioned(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                    left: 16,
                    child: _MiniRideInfo(
                      visible: past,
                      accentColor: _richtungColor(
                        _SystemMessageData.parse(systemMessages.last.text).richtung ?? '',
                      ),
                      onTap: () => _showInfoBottomSheet(
                        context,
                        _SystemMessageData.parse(systemMessages.last.text),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSystemMessage(BuildContext context, ChatMessage message) {
    final data = _SystemMessageData.parse(message.text);
    final accentColor =
        data.richtung != null ? _richtungColor(data.richtung!) : Colors.blueAccent;

    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: Semantics(
        container: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showInfoBottomSheet(context, data),
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AppCard(
              padding: EdgeInsets.zero,
              borderRadius: 24,
              gradientColors: const [
                Color(0xFF2C4A73), 
              Color(0xFF3A6EA5)],
              borderColor: Colors.white.withValues(alpha: 0.08),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Linker Akzentstreifen (wie _FahrerGlassCard)
                    Container(width: 4, color: accentColor),

                    // Hauptinhalt
                    Expanded(
                      child: Padding(
  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16), // ⬅️ mehr Luft
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [

      // ───────────────
      // ZEILE 1
      // ───────────────
      Row(
        children: [
          const Icon(Icons.directions_car,
              size: 14, color: Colors.white54),

          const SizedBox(width: 6),

          if (data.eventName != null)
            Expanded(
              child: Text(
                data.eventName!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(width: 8),
          const Icon(Icons.chevron_right,
              size: 18, color: Colors.white24),
        ],
      ),

      const SizedBox(height: 12), // ⬅️ WICHTIG

      // ───────────────
      // ROUTE
      // ───────────────
      if (data.startOrt != null && data.zielOrt != null)
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: data.startOrt!,
              ),
              const TextSpan(
                text: "  →  ",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: data.zielOrt!,
              ),
            ],
          ),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
            height: 1.3, // ⬅️ MEGA wichtig
          ),
        ),

      const SizedBox(height: 10), // ⬅️ mehr Luft zur Meta

      // ───────────────
      // META
      // ───────────────
      if (data.uhrzeit != null)
        Row(
          children: [
            const Icon(Icons.schedule, size: 13, color: Colors.white54),
            const SizedBox(width: 6),
            Text(
              data.uhrzeit!,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),

      const SizedBox(height: 8),

      Row(
        children: [
          const Icon(Icons.event_seat, size: 13, color: Colors.white54),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              data.seatsAccepted == null
                  ? "${data.seatsRequested} Plätze angefragt"
                  : "${data.seatsAccepted} / ${data.seatsRequested} Plätze",
              style: const TextStyle(fontSize: 12, color: Colors.white54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (data.seatsAccepted != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "akzeptiert",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    ],
  ),
),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Dezente Trennlinie unter der Box
        Container(
          margin: const EdgeInsets.only(top: 6),
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    ),
    ),);
  }

  Widget _buildInput(BuildContext context) {
    final chatService = context.read<ChatService>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                maxLines: null,
                autocorrect: false,
                enableSuggestions: false,
                spellCheckConfiguration:
                    const SpellCheckConfiguration.disabled(),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: "Nachricht schreiben …",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final text = _controller.text.trim();
                if (text.isEmpty) return;
                await chatService.sendMessage(
                  conversationId: widget.conversationId,
                  senderId: _myUserId,
                  text: text,
                );
                _controller.clear();
              },
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.amber.shade300, Colors.amber.shade600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }

  void _showInfoBottomSheet(BuildContext context, _SystemMessageData data) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.car_rental,
                          color: Colors.amber, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        "Mitfahranfrage",
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Badges: Event + Richtung
                  if (data.eventName != null || data.richtung != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (data.eventName != null)
                          _InfoBadge(
                            icon: Icons.celebration,
                            label: data.eventName!,
                            color: Colors.blueAccent,
                          ),
                        if (data.richtung != null)
                          _InfoBadge(
                            icon: Icons.directions,
                            label: data.richtung!,
                            color: _richtungColor(data.richtung!),
                          ),
                      ],
                    ),
                  const SizedBox(height: 14),

                  // Route (wrapping)
                  if (data.startOrt != null && data.zielOrt != null) ...[
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        Text(
                          data.startOrt!,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              data.zielOrt!,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Infos: Uhrzeit, Fahrer, Plätze
                  if (data.uhrzeit != null)
                    _InfoRow(
                        icon: Icons.access_time, label: data.uhrzeit!),
                  if (data.ownerName != null)
                    _InfoRow(
                        icon: Icons.person, label: data.ownerName!),
                  _InfoRow(
                    icon: Icons.event_seat,
                    label:
                        "${data.seatsRequested} Platz${data.seatsRequested != 1 ? 'e' : ''} angefragt",
                  ),
                  if (data.seatsAccepted != null)
                    _InfoRow(
                      icon: Icons.check_circle,
                      label:
                          "${data.seatsAccepted} Platz${data.seatsAccepted != 1 ? 'e' : ''} akzeptiert",
                      color: Colors.greenAccent,
                    ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        "Schließen",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ─────────────────────────────────────────
/// MINI MITFAHR-INFO (OVERLAY, LINKS OBEN)
/// ─────────────────────────────────────────
class _MiniRideInfo extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  final Color accentColor;

  const _MiniRideInfo({
    required this.visible,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: visible ? 1 : 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: DefaultTextStyle.merge(
              style: const TextStyle(decoration: TextDecoration.none),
              child: AppCard(
                padding: EdgeInsets.zero,
                borderRadius: 18,
                gradientColors: const [Color(0xFF2C4A73), Color(0xFF3A6EA5)],
                borderColor: Colors.white.withValues(alpha: 0.08),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 3, color: accentColor),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_car,
                                size: 15, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              "Mitfahr-Info",
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right,
                                size: 16,
                                color: accentColor.withValues(alpha: 0.7)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SYSTEM-MESSAGE DATEN (geparst aus Text)
// ─────────────────────────────────────────
class _SystemMessageData {
  final String? eventName;
  final String? startOrt;
  final String? zielOrt;
  final int seatsRequested;
  final int? seatsAccepted;
  final String? uhrzeit;
  final String? richtung;
  final String? ownerName;

  const _SystemMessageData({
    this.eventName,
    this.startOrt,
    this.zielOrt,
    this.seatsRequested = 0,
    this.seatsAccepted,
    this.uhrzeit,
    this.richtung,
    this.ownerName,
  });

  static _SystemMessageData parse(String text) {
    String? eventName;
    String? startOrt;
    String? zielOrt;
    int seatsRequested = 0;
    int? seatsAccepted;
    String? uhrzeit;
    String? richtung;
    String? ownerName;

    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.startsWith('Event: ')) {
        eventName = t.substring(7);
      } else if (t.startsWith('Strecke: ')) {
        final parts = t.substring(9).split(' → ');
        if (parts.length == 2) {
          startOrt = parts[0].trim();
          zielOrt = parts[1].trim();
        }
      } else if (t.startsWith('Uhrzeit: ')) {
        uhrzeit = t.substring(9);
      } else if (t.startsWith('Richtung: ')) {
        richtung = t.substring(10);
      } else if (t.startsWith('Fahrer: ')) {
        ownerName = t.substring(8);
      } else if (t.startsWith('Angefragt: ')) {
        seatsRequested = int.tryParse(t.substring(11).split(' ').first) ?? 0;
      } else if (t.startsWith('Akzeptiert: ')) {
        seatsAccepted = int.tryParse(t.substring(12).split(' ').first);
      }
    }

    return _SystemMessageData(
      eventName: eventName,
      startOrt: startOrt,
      zielOrt: zielOrt,
      seatsRequested: seatsRequested,
      seatsAccepted: seatsAccepted,
      uhrzeit: uhrzeit,
      richtung: richtung,
      ownerName: ownerName,
    );
  }
}

Widget _buildMessageBubble(ChatMessage msg, String myUserId) {
  final isMe = msg.senderId == myUserId;
  final time =
      '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

  return Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: IntrinsicWidth(
      child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF2F5ED6) : const Color(0xFF1E3547),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              time,
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
          ),
        ],
      ),
    ),
    ),
  );
}

// ─────────────────────────────────────────
// HILFSFUNKTION: Richtungsfarbe
// ─────────────────────────────────────────
Color _richtungColor(String richtung) => switch (richtung) {
      'Hinfahrt' => Colors.greenAccent,
      'Rückfahrt' => Colors.orangeAccent,
      _ => Colors.blueAccent,
    };

// ─────────────────────────────────────────
// BADGE (Event, Richtung)
// ─────────────────────────────────────────
class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// INFO-ZEILE (Icon + Text)
// ─────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF94A3B8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }
}
