import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/data/chat_service.dart';
import 'package:my_app/data/chat_message.dart';
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

  static const double _triggerOffset = 100;
  static const double _systemBoxHeight = 260;

  @override
  void initState() {
    super.initState();
    _myUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    _scrollController.addListener(() {
      final past = _scrollController.offset > _triggerOffset;
      if (past != _scrolledPast.value) _scrolledPast.value = past;
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
                body: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16 +
                              (systemMessages.isNotEmpty
                                  ? _systemBoxHeight + 16
                                  : 0),
                          16,
                          90,
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

              if (systemMessages.isNotEmpty)
                ValueListenableBuilder<bool>(
                  valueListenable: _scrolledPast,
                  builder: (context, past, _) => Positioned(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                    left: 16,
                    right: 16,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: past ? 0 : 1,
                      child: IgnorePointer(
                        ignoring: past,
                        child: _buildSystemMessage(
                          context,
                          systemMessages.last,
                        ),
                      ),
                    ),
                  ),
                ),

              if (systemMessages.isNotEmpty)
                ValueListenableBuilder<bool>(
                  valueListenable: _scrolledPast,
                  builder: (context, past, _) => Positioned(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                    left: 16,
                    child: _MiniRideInfo(
                      visible: past,
                      onTap: () =>
                          _showInfoBottomSheet(context, systemMessages.last),
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
    return Semantics(
      container: true,
      child: GestureDetector(
        onTap: () => _showInfoBottomSheet(context, message),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(239, 67, 132, 216).withOpacity(0.60),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.car_rental, color: Colors.amber, size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      "Mitfahr-Info",
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        color: Colors.amber.withOpacity(0.7)),
                  ],
                ),
                const SizedBox(height: 12),
                ExcludeSemantics(
                  child: RichText(
                    textScaler: MediaQuery.of(context).textScaler,
                    text: TextSpan(
                      text: message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    final chatService = context.read<ChatService>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              autocorrect: false,
              enableSuggestions: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Nachricht schreiben …",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.amber),
            onPressed: () async {
              final text = _controller.text.trim();
              if (text.isEmpty) return;

              await chatService.sendMessage(
                conversationId: widget.conversationId,
                senderId: _myUserId,
                text: text,
              );

              _controller.clear();
            },
          ),
        ],
      ),
    );
  }

  void _showInfoBottomSheet(BuildContext context, ChatMessage message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1F3A5F).withOpacity(0.98),
                  Color(0xFF152B46).withOpacity(0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.blueAccent.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.blueAccent.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.car_rental, color: Colors.amber, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Mitfahr-Informationen",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E6FB5).withOpacity(0.22),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.amber, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Akzeptierte Plätze:",
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
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

  const _MiniRideInfo({
    required this.visible,
    required this.onTap,
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3E6FB5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.car_rental, size: 18, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    "Mitfahr-Info",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: Colors.amber),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildMessageBubble(ChatMessage msg, String myUserId) {
  final isMe = msg.senderId == myUserId;

  return Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF2F5ED6) : const Color(0xFF3E5F96),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        msg.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.35,
        ),
      ),
    ),
  );
}
