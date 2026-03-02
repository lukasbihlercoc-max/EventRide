import 'package:flutter/material.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/views/pages/login_page.dart';
import 'package:provider/provider.dart';

/// Prüft ob der Nutzer angemeldet ist.
/// Wenn nicht: zeigt einen Dialog und navigiert optional zur LoginPage.
/// Gibt [true] zurück wenn angemeldet, sonst [false].
Future<bool> requiresLogin(BuildContext context) async {
  final auth = context.read<IAuthRepository>();
  if (auth.currentUser != null) return true;

  final shouldLogin = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Anmeldung erforderlich',
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        'Für diese Aktion musst du angemeldet sein.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Anmelden', style: TextStyle(color: Colors.blueAccent)),
        ),
      ],
    ),
  );

  if (shouldLogin != true) return false;
  if (!context.mounted) return false;

  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LoginPage()),
  );

  if (!context.mounted) return false;
  return context.read<IAuthRepository>().currentUser != null;
}
