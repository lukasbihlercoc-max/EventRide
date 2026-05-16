import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/views/pages/email_verification_page.dart';

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
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _VerificationBottomSheet(email: email),
  );
}

class _VerificationBottomSheet extends StatelessWidget {
  final String email;
  const _VerificationBottomSheet({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Icon(Icons.mark_email_unread_outlined,
                  color: Colors.blueAccent, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'E-Mail bestätigen erforderlich',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Um diese Funktion zu nutzen, musst du zuerst deine E-Mail-Adresse bestätigen.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tipp: Schau auch in deinem Spam-Ordner nach – die Bestätigungs-E-Mail landet manchmal dort.',
                    style: TextStyle(
                        color: Colors.orange, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  AppRoute(
                    builder: (_) => EmailVerificationPage(email: email),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Jetzt bestätigen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
