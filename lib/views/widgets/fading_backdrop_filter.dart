import 'dart:ui';
import 'package:flutter/material.dart';

/// BackdropFilter der seinen Blur-Sigma proportional zum Animations-Wert der
/// aktuellen Route skaliert. Beim Weggleiten der Seite (animation → 0) schwindet
/// der Blur auf 0, sodass die darunterliegende Destination-Seite nicht unscharf
/// erscheint (iOS Swipe-Back).
class FadingBackdropFilter extends StatelessWidget {
  final double sigma;
  const FadingBackdropFilter({required this.sigma, super.key});

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(color: Colors.transparent),
      );
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final s = sigma * animation.value;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: s, sigmaY: s),
          child: Container(color: Colors.transparent),
        );
      },
    );
  }
}
