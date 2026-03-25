import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final double borderRadius;

  static const List<Color> _defaultGradient = [
    Color(0xFF243A5E),
    Color(0xFF365E91),
  ];

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.gradientColors,
    this.borderColor,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final colors = gradientColors ?? _defaultGradient;
    final border = borderColor ?? Colors.white.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(0.9, 1),
          colors: colors,
        ),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),

      // Top-left light + bottom depth
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.06),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),

      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
