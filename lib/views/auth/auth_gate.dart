import 'package:flutter/material.dart';
import 'package:my_app/views/widget_tree.dart';

/// AuthGate zeigt immer WidgetTree.
/// Auth-Checks für geschützte Aktionen (Fahrt anbieten, Mitfahren)
/// erfolgen direkt am jeweiligen Button über requiresLogin() in auth_guard.dart.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return const WidgetTree();
  }
}
