// profile_page.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/views/pages/login_page.dart';
import 'package:my_app/views/pages/register_page.dart';
import 'package:my_app/views/widgets/app_card.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROOT
// ─────────────────────────────────────────────────────────────────────────────

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<AppUser?>(
          stream: context.read<IAuthRepository>().authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (snapshot.data != null) {
              return _LoggedInView(user: snapshot.data!);
            }
            return const _GuestView();
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GUEST VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 40,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Mein Profil",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Melde dich an für ein sicheres\nMitfahrerlebnis in Kärnten",
              style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _PrimaryButton(
              label: "Anmelden",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                ),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text(
                  "Registrieren",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _GlassInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.white70, size: 18),
                      SizedBox(width: 10),
                      Text(
                        "Vertrauenssystem",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _TrustRow(filled: 1, label: "E-Mail & Telefon verifiziert"),
                  const SizedBox(height: 10),
                  _TrustRow(filled: 2, label: "Profilfoto hinzugefügt"),
                  const SizedBox(height: 10),
                  _TrustRow(filled: 3, label: "Führerschein verifiziert"),
                ],
              ),
            ),
            const SizedBox(height: 130),
          ],
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  final int filled;
  final String label;
  const _TrustRow({required this.filled, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(
            3,
            (i) => Icon(
              i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < filled ? Colors.amber : Colors.white24,
              size: 15,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGGED IN VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _LoggedInView extends StatefulWidget {
  final AppUser user;
  const _LoggedInView({required this.user});

  @override
  State<_LoggedInView> createState() => _LoggedInViewState();
}

class _LoggedInViewState extends State<_LoggedInView> {
  bool _uploading = false;

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: Colors.white70),
              title: const Text('Galerie',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white70),
              title: const Text('Kamera',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Zuschneiden',
          toolbarColor: const Color(0xFF1A1F2E),
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: 'Zuschneiden',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await context
          .read<IAuthRepository>()
          .uploadProfilePhoto(File(cropped.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero ───────────────────────────────────────────────────
            _HeroSection(
              user: user,
              uploading: _uploading,
              onPickPhoto: _showSourceSheet,
            ),

            const SizedBox(height: 24),

            // ── Separator ──────────────────────────────────────────────
            const _Separator(),

            const SizedBox(height: 24),

            // ── Verifikation 2×2 ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Profil vervollständigen",
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 0.3,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _VerifCard(
                          icon: Icons.email_outlined,
                          label: "E-Mail",
                          done: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VerifCard(
                          icon: Icons.phone_outlined,
                          label: "Telefon",
                          cta: "Verifizieren",
                          done: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _VerifCard(
                          icon: Icons.photo_camera_outlined,
                          label: "Profilbild",
                          cta: "Hochladen",
                          done: user.photoUrl != null &&
                              user.photoUrl!.isNotEmpty,
                          onTap: _uploading ? null : _showSourceSheet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VerifCard(
                          icon: Icons.credit_card_outlined,
                          label: "Führerschein",
                          cta: "Hochladen",
                          done: false,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Bewertungen ───────────────────────────────────
                  const Text(
                    "Bewertungen",
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 0.3,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: 22,
                        horizontal: 16,
                      ),
                      child: Column(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.star_border_rounded,
                                color: Colors.white54,
                              ),
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              "Noch keine Bewertungen",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 4),

                            const Text(
                              "Nach deiner ersten Fahrt sichtbar",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 150),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final AppUser user;
  final bool uploading;
  final VoidCallback onPickPhoto;

  const _HeroSection({
    required this.user,
    required this.uploading,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user.name);
    final hasPhoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          // Avatar mit Progress-Arc + Tap
          GestureDetector(
            onTap: uploading ? null : onPickPhoto,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Arc-Ring
                SizedBox(
                  width: 122,
                  height: 122,
                  child: CustomPaint(
                    painter: _ProgressArcPainter(
                      progress: hasPhoto ? 0.5 : 0.25,
                    ),
                  ),
                ),
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasPhoto
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF3B6FE0), Color(0xFF6B4FA0)],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFF4A80F0).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: uploading
                        ? const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : hasPhoto
                            ? Image.network(
                                user.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                  ),
                ),
                // Kamera-Icon über dem Avatar
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A80F0),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF1A1F2E), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF4A80F0).withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 10),

          // Stats-Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(
                icon: Icons.directions_car_rounded,
                label: "0 Fahrten",
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.star_rounded,
                label: "Keine Bewertung",
                iconColor: Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Schritt-Pillen
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final active = i == 0;
              return Container(
                width: active ? 28 : 10,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [Color(0xFF4A80F0), Color(0xFF7B5EA7)],
                        )
                      : null,
                  color: active
                      ? null
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          const Text(
            "1 von 4 Schritten abgeschlossen",
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _StatChip({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? Colors.white54),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEPARATOR
// ─────────────────────────────────────────────────────────────────────────────

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: const Text(
                "EventRide",
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERIFIKATION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _VerifCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;
  final String? cta;
  final VoidCallback? onTap;

  const _VerifCard({
    required this.icon,
    required this.label,
    required this.done,
    this.cta,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 110,
        child: AppCard(
          padding: const EdgeInsets.all(14),
          gradientColors: done
              ? const [Color(0xFF1B4332), Color(0xFF2D6A4F)]
              : null,
          borderColor: done
              ? const Color(0xFF52B788)
              : null,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row ─────────────────────
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : icon,
                    size: 18,
                    color: done
                        ? const Color(0xFF74C69D)
                        : Colors.white60,
                  ),
                ),

                const Spacer(),

                // Status Badge (wie Plätze bei Fahrten)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: done
                        ? const Color(0xFF2D6A4F)
                        : const Color(0xFF4A80F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    done ? "OK" : "Offen",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),

            const Spacer(),

            // ── Text ─────────────────────
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              done ? "Bestätigt" : (cta ?? "Erforderlich"),
              style: TextStyle(
                color: done
                    ? const Color(0xFF74C69D)
                    : Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _GlassInfoCard extends StatelessWidget {
  final Widget child;
  const _GlassInfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(child: child);
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PrimaryButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF4A80F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS ARC PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressArcPainter extends CustomPainter {
  final double progress;
  const _ProgressArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Hintergrund-Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Fortschritts-Arc mit Gradient
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi,
        colors: const [Color(0xFF4A80F0), Color(0xFF7B5EA7), Color(0xFF4A80F0)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Leuchtpunkt am Ende des Arcs
    final endAngle = -math.pi / 2 + 2 * math.pi * progress;
    final dotX = center.dx + radius * math.cos(endAngle);
    final dotY = center.dy + radius * math.sin(endAngle);
    final dotPaint = Paint()
      ..color = const Color(0xFF7B5EA7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
    canvas.drawCircle(
      Offset(dotX, dotY),
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter old) =>
      old.progress != progress;
}