import 'package:flutter/material.dart';
import 'package:my_app/data/interfaces/i_user_repository.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TrustShields
// ─────────────────────────────────────────────────────────────────────────────

/// Zeigt 3 Shield-Icons als Vertrauensindikator.
/// Gefüllte Schilder: blau mit weißem Rahmen. Leere: outline/weiß54.
class TrustShields extends StatelessWidget {
  final int filled;
  final double size;

  const TrustShields({super.key, required this.filled, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        if (i < filled) {
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.shield_rounded, size: size,
                    color: const Color(0xFF4A80F0)),
                Icon(Icons.shield_outlined, size: size,
                    color: Colors.white70.withValues(alpha: 0.8)),
              ],
            ),
          );
        }
        return Icon(Icons.shield_outlined, size: size,
            color: Colors.white38);
      }),
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
