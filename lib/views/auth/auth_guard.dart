import 'package:flutter/material.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/views/pages/login_page.dart';
import 'package:my_app/views/widgets/app_bottom_sheet.dart';
import 'package:provider/provider.dart';

/// Prüft ob der Nutzer angemeldet ist.
/// Wenn nicht: zeigt einen Dialog und navigiert optional zur LoginPage.
/// Gibt [true] zurück wenn angemeldet, sonst [false].
Future<bool> requiresLogin(BuildContext context) async {
  final auth = context.read<IAuthRepository>();
  if (auth.currentUser != null) return true;

  final shouldLogin = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x73080C16),
    builder: (ctx) => AppBottomSheet(
      icon: Icons.key_outlined,
      iconColor: const Color(0xFFF5A04A),
      title: 'Anmeldung erforderlich',
      body: 'Für diese Aktion musst du angemeldet sein.',
      primaryLabel: 'Anmelden',
      onPrimary: () => Navigator.pop(ctx, true),
      secondaryLabel: 'Abbrechen',
      onSecondary: () => Navigator.pop(ctx, false),
    ),
  );

  if (shouldLogin != true) return false;
  if (!context.mounted) return false;

  await Navigator.push(
    context,
    AppRoute(builder: (_) => const LoginPage()),
  );

  if (!context.mounted) return false;
  return context.read<IAuthRepository>().currentUser != null;
}
