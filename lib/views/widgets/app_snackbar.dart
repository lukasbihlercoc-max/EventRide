import 'dart:ui';
import 'package:flutter/material.dart';

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Color? accentColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _SnackbarOverlay(
          message: message,
          accentColor: accentColor,
          onDismiss: () => entry.remove(),
          duration: duration,
        );
      },
    );

    overlay.insert(entry);
  }
}

class _SnackbarOverlay extends StatefulWidget {
  final String message;
  final Color? accentColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _SnackbarOverlay({
    required this.message,
    required this.onDismiss,
    required this.duration,
    this.accentColor,
  });

  @override
  State<_SnackbarOverlay> createState() => _SnackbarOverlayState();
}

class _SnackbarOverlayState extends State<_SnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _offset = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,

    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _offset,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              constraints: const BoxConstraints(minHeight: 64),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 66, 142, 228).withOpacity(0.28),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF5DA9FF).withOpacity(0.6),
                  width: 1.2,
                ),

                boxShadow: [
                  // Hauptschatten nach unten
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),

                  // leichter Glow nach oben
                  BoxShadow(
                    color: const Color(0xFF5DA9FF).withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: const Color(0xFF5DA9FF),
                    size: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none, // 🔥 wichtig
                      ),
                    ),
                  ),
                ],
              ),
            ),


          ),
        ),
      ),
    );
  }
}

/*falls zu nah am rand (iphone)
return SafeArea(
  child: Positioned(
    bottom: 20,
    left: 20,
    right: 20,
*/