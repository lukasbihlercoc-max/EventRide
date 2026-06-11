import 'package:flutter/material.dart';
import 'package:my_app/views/pages/terms_acceptance_page.dart';
import 'package:my_app/views/widget_tree.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _termsAccepted;

  @override
  void initState() {
    super.initState();
    _checkTerms();
  }

  Future<void> _checkTerms() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('termsAccepted') ?? false;
    if (mounted) setState(() => _termsAccepted = accepted);
  }

  @override
  Widget build(BuildContext context) {
    if (_termsAccepted == null) return const SizedBox.shrink();
    if (!_termsAccepted!) {
      return TermsAcceptancePage(
        onAccepted: () => setState(() => _termsAccepted = true),
      );
    }
    return const WidgetTree();
  }
}
