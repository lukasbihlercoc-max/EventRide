import 'package:flutter/material.dart';

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
