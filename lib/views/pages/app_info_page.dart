// app_info_page.dart
import 'package:flutter/material.dart';
import 'package:my_app/data/event_request.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/views/pages/admin_event_requests_page.dart';
import 'package:my_app/views/pages/event_submit_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/app_card.dart';
import 'package:my_app/views/pages/user_event_requests_page.dart';

const _kAccent = Color(0xFFF5A04A);

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'EventRide Info',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ── HEADLINE / CONTEXT ─────────────────────────────
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                "Hilf uns, EventRide besser zu machen",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),

            // ── EVENT CTA (WICHTIGSTER BLOCK) ───────────────────
            AppCard(
              borderColor: _kAccent.withValues(alpha: 0.7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.event_available,
                    title: "Event fehlt?",
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Schick uns dein Event und wir fügen es hinzu.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // CTA BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        AppRoute(
                          builder: (_) => const EventSubmitPage(),
                        ),
                      ),
                      child: const Text(
                        "Event einreichen",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── MEINE EINREICHUNGEN (für eingeloggte Nutzer) ──────
            StreamBuilder<List<dynamic>>(
              stream: context.read<IAuthRepository>().myEventRequests,
              builder: (context, snapshot) {
                final list = snapshot.data ?? [];
                if (list.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: AppCard(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.push(
                        context,
                        AppRoute(
                          builder: (_) => const UserEventRequestsPage(),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionHeader(
                                  icon: Icons.send_outlined,
                                  title: 'Meine Einreichungen',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${list.length} ${list.length == 1 ? 'Einreichung' : 'Einreichungen'}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── ADMIN: EVENT-ANFRAGEN (nur für Admins) ─────────
            Builder(builder: (context) {
              final auth = context.read<IAuthRepository>();
              if (!auth.isAdmin) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: StreamBuilder<List<EventRequest>>(
                  stream: auth.pendingEventRequests,
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return AppCard(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.push(
                          context,
                          AppRoute(
                            builder: (_) => const AdminEventRequestsPage(),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(
                                    icon: Icons.event_note_outlined,
                                    title: 'Event-Anfragen',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    count == 0
                                        ? 'Keine offenen Anfragen'
                                        : '$count offen${count == 1 ? 'e Anfrage' : 'e Anfragen'}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (count > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _kAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            else
                              Icon(Icons.chevron_right,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

            const SizedBox(height: 16),

            // ── KONTAKT ────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kontakt',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _ContactTile(
                    icon: Icons.camera_alt_outlined,
                    label: 'Instagram',
                    subtitle: '@event.ride',
                    onTap: () =>
                        _launch('https://instagram.com/event.ride'),
                  ),

                  const Divider(color: Colors.white24),

                  _ContactTile(
                    icon: Icons.mail_outline,
                    label: 'E-Mail',
                    subtitle: 'eventride.25@gmail.com',
                    onTap: () => _launch(
                        'mailto:eventride.25@gmail.com?subject=Kontakt'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── REGIONEN ──────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.map_outlined,
                    title: "Neue Regionen",
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Aktuell: Kärnten\nDemnächst: weitere Bundesländer",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ─────────────────────────────────────────────
// UI COMPONENTS
// ─────────────────────────────────────────────
//

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _kAccent, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _kAccent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.60),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}