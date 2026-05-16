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
      clipBehavior: Clip.hardEdge,
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
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
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
    );
  }
}
