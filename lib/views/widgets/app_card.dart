import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final double borderRadius;

static const List<Color> _defaultGradient = [
  Color.fromARGB(255, 20, 42, 71),
  Color.fromARGB(255, 38, 73, 113),
  Color.fromARGB(255, 57, 100, 156),
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
          end: const Alignment(0.7, 1),
          colors: colors,
          stops: colors.length == 3 ? const [0.0, 0.7, 1.0] : null,
        ),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 36,
            spreadRadius: -6,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: colors.last.withValues(alpha: 0.24),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Top-left Highlight hinter dem Content (nicht darüber)
            Positioned.fill(
  child: IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.center,
          colors: [
            Colors.black.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4],
        ),
      ),
    ),
  ),
),
            Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
