import 'package:flutter/material.dart';
import 'package:my_app/config/legal_texts.dart';
import 'package:my_app/views/pages/legal_page.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsAcceptancePage extends StatelessWidget {
  final VoidCallback onAccepted;

  const TermsAcceptancePage({super.key, required this.onAccepted});

  Future<void> _accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('termsAccepted', true);
    onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    size: 38,
                    color: Color(0xFFF5A04A),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Willkommen bei EventRide',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Bevor du loslegst, lies bitte unsere Nutzungsbedingungen und '
                  'Datenschutzerklärung. Mit dem Tippen auf „Akzeptieren" stimmst '
                  'du diesen zu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegalLink(
                      label: 'Nutzungsbedingungen',
                      onTap: () => Navigator.push(
                        context,
                        AppRoute(
                          builder: (_) => const LegalPage(
                            title: 'Nutzungsbedingungen',
                            content: kAgbText,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '  ·  ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.40),
                        fontSize: 14,
                      ),
                    ),
                    _LegalLink(
                      label: 'Datenschutz',
                      onTap: () => Navigator.push(
                        context,
                        AppRoute(
                          builder: (_) => const LegalPage(
                            title: 'Datenschutzerklärung',
                            content: kDatenschutzText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _AcceptButton(onTap: _accept),
                const SizedBox(height: 12),
                Text(
                  'Du kannst die App nur nutzen, wenn du zustimmst.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFF5A04A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFFF5A04A),
        ),
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AcceptButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5A04A), Color(0xFFE08A35)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5A04A).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: const Center(
              child: Text(
                'Akzeptieren & fortfahren',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
