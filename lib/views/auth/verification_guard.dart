import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/views/pages/email_verification_page.dart';
import 'package:my_app/views/widgets/app_bottom_sheet.dart';

/// Prüft ob die E-Mail des eingeloggten Users verifiziert ist.
/// Wenn nicht: zeigt ein BottomSheet mit Hinweis und Link zur Verifikationsseite.
/// Gibt [true] zurück wenn verifiziert, sonst [false].
bool requireVerified(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && user.emailVerified) return true;

  _showVerificationBottomSheet(context, user?.email ?? '');
  return false;
}

void _showVerificationBottomSheet(BuildContext context, String email) {
  showAppSheet<void>(
    context,
    (ctx) => AppSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSheetHeader(
            icon: Icons.mark_email_unread_outlined,
            iconColor: const Color(0xFFF5A04A),
            title: 'E-Mail bestätigen erforderlich',
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              'Um diese Funktion zu nutzen, musst du zuerst deine E-Mail-Adresse bestätigen.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13.5,
                  height: 1.5),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.orange.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tipp: Schau auch in deinem Spam-Ordner nach – die Bestätigungs-E-Mail landet manchmal dort.',
                      style: TextStyle(
                          color: Colors.orange.withValues(alpha: 0.90),
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppSheetPrimaryButton(
            label: 'Jetzt bestätigen',
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                  context,
                  AppRoute(
                      builder: (_) => EmailVerificationPage(email: email)));
            },
          ),
        ],
      ),
    ),
  );
}
