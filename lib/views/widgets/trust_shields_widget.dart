import 'package:flutter/material.dart';
import 'package:my_app/data/interfaces/i_user_repository.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TrustShields
// ─────────────────────────────────────────────────────────────────────────────

/// Zeigt 3 Shield-Icons als Vertrauensindikator.
/// Gefüllte Schilder: blau mit weißem Rahmen. Leere: outline/weiß38.
/// Wenn filled steigt, spielt der neu gefüllte Shield eine Bounce+Flash-Animation.
class TrustShields extends StatefulWidget {
  final int filled;
  final double size;

  const TrustShields({super.key, required this.filled, this.size = 14});

  @override
  State<TrustShields> createState() => _TrustShieldsState();
}

class _TrustShieldsState extends State<TrustShields>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<Color?> _color;
  int? _animatingIndex;

  static const _blue = Color(0xFF4A80F0);
  static const _gold = Color(0xFFF5A04A);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.6), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.6, end: 0.88), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _color = ColorTween(begin: _gold, end: _blue)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void didUpdateWidget(TrustShields old) {
    super.didUpdateWidget(old);
    if (widget.filled > old.filled) {
      _animatingIndex = old.filled; // 0-based index des neu gefüllten Shields
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final isFilled = i < widget.filled;
          final isAnimating = i == _animatingIndex && _ctrl.isAnimating;

          if (isFilled) {
            return Transform.scale(
              scale: isAnimating ? _scale.value : 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.shield_rounded,
                      size: widget.size,
                      color: isAnimating ? _color.value : _blue),
                  Icon(Icons.shield_outlined,
                      size: widget.size,
                      color: Colors.white70.withValues(alpha: 0.8)),
                ],
              ),
            );
          }
          return Icon(Icons.shield_outlined,
              size: widget.size, color: Colors.white38);
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TrustShieldsByUserId
// Lädt das Trust-Level einmalig aus Firestore und zeigt TrustShields an.
// ─────────────────────────────────────────────────────────────────────────────

class TrustShieldsByUserId extends StatefulWidget {
  final String userId;
  final double size;

  const TrustShieldsByUserId({
    super.key,
    required this.userId,
    this.size = 14,
  });

  @override
  State<TrustShieldsByUserId> createState() => _TrustShieldsByUserIdState();
}

class _TrustShieldsByUserIdState extends State<TrustShieldsByUserId> {
  static final _cache = <String, int>{};
  int _trustLevel = 0;

  @override
  void initState() {
    super.initState();
    final cached = _cache[widget.userId];
    if (cached != null) {
      _trustLevel = cached;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final level = await context
          .read<IUserRepository>()
          .getTrustLevel(widget.userId);
      _cache[widget.userId] = level;
      if (mounted) setState(() => _trustLevel = level);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return TrustShields(filled: _trustLevel, size: widget.size);
  }
}
