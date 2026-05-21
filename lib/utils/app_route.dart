import 'package:flutter/material.dart';

/// Einheitliche Seitenroute für die gesamte App.
/// Nutzt CupertinoPageTransitionsBuilder aus dem PageTransitionsTheme
/// mit kürzeren Dauern: 220 ms vorwärts, 160 ms rückwärts.
class AppRoute<T> extends MaterialPageRoute<T> {
  AppRoute({
    required super.builder,
    super.settings,
    super.fullscreenDialog,
  });

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 160);
}
