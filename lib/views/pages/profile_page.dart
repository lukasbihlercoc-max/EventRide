// profile_page.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/data/review.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/place_type.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/config/feature_flags.dart';
import 'package:my_app/config/legal_texts.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/views/pages/legal_page.dart';
import 'package:my_app/views/pages/public_profile_page.dart';
import 'package:my_app/views/pages/reviews_list_page.dart';
import 'package:my_app/views/widgets/review_card_widget.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/views/pages/login_page.dart';
import 'package:my_app/views/pages/register_page.dart';
import 'package:my_app/views/widgets/app_card.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/data/license_request.dart';
import 'package:my_app/views/pages/admin_license_page.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/trust_shields_widget.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROOT
// ─────────────────────────────────────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Stream<AppUser?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = context.read<IAuthRepository>().authStateChanges;
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<AppUser?>(
          stream: _authStream,
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
                AppRoute(builder: (_) => const LoginPage()),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  AppRoute(builder: (_) => const RegisterPage()),
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
                  _TrustRow(filled: 1, label: "E-Mail bestätigt"),
                  const SizedBox(height: 10),
                  _TrustRow(filled: 2, label: "Telefon verifiziert"),
                  const SizedBox(height: 10),
                  _TrustRow(filled: 3, label: "Führerschein hochgeladen"),
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
        TrustShields(filled: filled, size: 15),
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

  // ── Hilfsmethoden ──────────────────────────────────────────────────────────

  VerifState _licenseState(String status) {
    switch (status) {
      case 'verified':
        return VerifState.done;
      case 'pending':
        return VerifState.pending;
      case 'rejected':
        return VerifState.rejected;
      default:
        return VerifState.open;
    }
  }

  // ── Sheets ─────────────────────────────────────────────────────────────────

  void _showVerifInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
              const Text(
                "Das Vertrauenssystem",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Verifizierte Nutzer geben anderen Mitfahrern mehr Sicherheit. Je mehr Schritte du abschließt, desto mehr Sterne erhältst du.",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              const _TrustRow(filled: 1, label: "E-Mail bestätigt"),
              const SizedBox(height: 10),
              const _TrustRow(filled: 2, label: "Telefon verifiziert"),
              const SizedBox(height: 10),
              const _TrustRow(filled: 3, label: "Führerschein hochgeladen"),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

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

  void _showEmailSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EmailVerifSheet(email: widget.user.email),
    );
  }

  void _showPhoneSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _PhoneVerifSheet(),
    );
  }

  void _showLicenseSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _LicenseSheet(),
    );
  }

  void _showHomeTownSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _HomeTownSheet(current: widget.user.homeTown ?? ''),
    );
  }

  void _showCarSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CarInfoSheet(current: widget.user.car),
    );
  }

  // ── Foto-Upload ────────────────────────────────────────────────────────────

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
        AppSnackbar.show(
          context,
          message: 'Upload fehlgeschlagen: $e',
          accentColor: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _HeroSection(
              user: user,
              uploading: _uploading,
              onPickPhoto: _showSourceSheet,
              trustLevel: user.trustLevel,
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Verifikation ──────────────────────────────────────
                  Row(
                    children: [
                      const Text(
                        "Verifikation",
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 0.3,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _showVerifInfo,
                        child: const Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _VerifCard(
                          icon: Icons.email_outlined,
                          label: "E-Mail",
                          state: user.emailVerified
                              ? VerifState.done
                              : VerifState.open,
                          cta: "Verifizieren",
                          doneLabel: "Verifiziert",
                          onTap: user.emailVerified ? null : _showEmailSheet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VerifCard(
                          icon: Icons.phone_outlined,
                          label: "Telefon",
                          state: user.phoneVerified
                              ? VerifState.done
                              : VerifState.open,
                          cta: "Verifizieren",
                          doneLabel: "Verifiziert",
                          onTap: user.phoneVerified ? null : _showPhoneSheet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _VerifCard(
                    icon: Icons.credit_card_outlined,
                    label: "Führerschein",
                    state: _licenseState(user.licenseStatus),
                    cta: user.licenseStatus == 'rejected'
                        ? "Erneut hochladen"
                        : "Hochladen",
                    doneLabel: "Verifiziert",
                    onTap: (user.licenseStatus == 'verified' ||
                          user.licenseStatus == 'pending')
                        ? null
                        : _showLicenseSheet,
                  ),
                  if (user.licenseStatus == 'rejected' &&
                      user.licenseRejectReason != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D0A0A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE63946).withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: Color(0xFFFF6B72)),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Abgelehnt: ${user.licenseRejectReason}',
                              style: const TextStyle(
                                  color: Color(0xFFFF6B72), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Admin: offene Führerschein-Prüfungen ──────────────
                  if (context.read<IAuthRepository>().isAdmin) ...[
                    const SizedBox(height: 10),
                    StreamBuilder<List<LicenseRequest>>(
                      stream: context
                          .read<IAuthRepository>()
                          .pendingLicenseRequests,
                      builder: (context, snap) {
                        final count = snap.data?.length ?? 0;
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            AppRoute(
                                builder: (_) => const AdminLicensePage()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE07B00)
                                    .withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: Color(0xFFE07B00),
                                    size: 18),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Führerschein-Prüfungen',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ),
                                if (count > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE07B00),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  )
                                else
                                  const Icon(Icons.chevron_right_rounded,
                                      color: Colors.white38, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Profil vervollständigen ────────────────────────────
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
                          icon: Icons.photo_camera_outlined,
                          label: "Profilbild",
                          cta: "Hochladen",
                          state: (user.photoUrl?.isNotEmpty == true)
                              ? VerifState.done
                              : VerifState.open,
                          doneLabel: "Erledigt",
                          onTap: _uploading ? null : _showSourceSheet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VerifCard(
                          icon: Icons.location_on_outlined,
                          label: "Gemeinde",
                          cta: "Hinzufügen",
                          state: (user.homeTown?.isNotEmpty == true)
                              ? VerifState.done
                              : VerifState.open,
                          doneLabel: "Erledigt",
                          onTap: _showHomeTownSheet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _VerifCard(
                    icon: Icons.directions_car_outlined,
                    label: "Auto-Infos",
                    cta: user.car != null ? "Bearbeiten" : "Hinzufügen",
                    state: user.car != null ? VerifState.done : VerifState.open,
                    doneLabel: "Erledigt",
                    onTap: _showCarSheet,
                  ),

                  const SizedBox(height: 24),

                  // ── Bewertungen ────────────────────────────────────────
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
                  _OwnReviewsSection(user: user),

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
  final int trustLevel;

  const _HeroSection({
    required this.user,
    required this.uploading,
    required this.onPickPhoto,
    required this.trustLevel,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user.name);
    final hasPhoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          GestureDetector(
            onTap: uploading ? null : onPickPhoto,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 122,
                  height: 122,
                  child: CustomPaint(
                    painter: _ProgressArcPainter(
                      progress: hasPhoto ? 0.5 : 0.25,
                    ),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2A3044),
                    image: hasPhoto
                        ? DecorationImage(
                            image: NetworkImage(user.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasPhoto
                      ? Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : null,
                ),
                if (uploading)
                  const SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
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
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              TrustShields(filled: trustLevel, size: 18),
            ],
          ),
          const SizedBox(height: 10),
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
                label: (user.ratingAvg != null && user.ratingCount > 0)
                    ? '${user.ratingAvg!.toStringAsFixed(1)} ★  ·  ${user.ratingCount} ${user.ratingCount == 1 ? 'Bewertung' : 'Bewertungen'}'
                    : 'Keine Bewertung',
                iconColor: Colors.amber,
              ),
            ],
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
// VERIFIKATION CARD
// ─────────────────────────────────────────────────────────────────────────────

enum VerifState { open, pending, done, rejected }

class _VerifCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VerifState state;
  final String? cta;
  final String doneLabel;
  final VoidCallback? onTap;

  const _VerifCard({
    required this.icon,
    required this.label,
    required this.state,
    this.cta,
    this.doneLabel = "OK",
    this.onTap,
  });

  // Gleiche dunkle Basis wie AppCard-Default, Ende leicht state-getönt
  List<Color> get _gradientColors {
    switch (state) {
      case VerifState.done:
        return const [Color(0xFF142A47), Color(0xFF1B3A34)];
      case VerifState.pending:
        return const [Color(0xFF142A47), Color(0xFF2A2318)];
      case VerifState.rejected:
        return const [Color(0xFF142A47), Color(0xFF3A1515)];
      case VerifState.open:
        return const [Color(0xFF142A47), Color(0xFF264971)];
    }
  }

  Color get _borderColor {
    switch (state) {
      case VerifState.done:
        return const Color(0xFF4B7A6A).withValues(alpha: 0.40);
      case VerifState.pending:
        return const Color(0xFFB07830).withValues(alpha: 0.40);
      case VerifState.rejected:
        return const Color(0xFFE63946).withValues(alpha: 0.35);
      case VerifState.open:
        return Colors.white.withValues(alpha: 0.12);
    }
  }

  Color get _badgeColor {
    switch (state) {
      case VerifState.done:
        return const Color(0xFF2D6A4F);
      case VerifState.pending:
        return const Color.fromARGB(206, 168, 82, 28);
      case VerifState.rejected:
        return const Color(0xFFE63946);
      case VerifState.open:
        return const Color.fromARGB(235, 74, 129, 240);
    }
  }

  String get _badgeLabel {
    switch (state) {
      case VerifState.done:
        return doneLabel;
      case VerifState.pending:
        return "In Prüfung";
      case VerifState.rejected:
        return "Abgelehnt";
      case VerifState.open:
        return "Offen";
    }
  }

  Color get _iconColor {
    switch (state) {
      case VerifState.done:
        return const Color(0xFF74C69D);
      case VerifState.pending:
        return const Color(0xFFF4A261);
      case VerifState.rejected:
        return const Color(0xFFE63946);
      case VerifState.open:
        return Colors.white60;
    }
  }

  IconData get _stateIcon {
    switch (state) {
      case VerifState.done:
        return Icons.check_rounded;
      case VerifState.pending:
        return Icons.hourglass_top_rounded;
      case VerifState.rejected:
        return Icons.close_rounded;
      case VerifState.open:
        return icon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 110,
        child: AppCard(
          padding: const EdgeInsets.all(14),
          gradientColors: _gradientColors,
          borderColor: _borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_stateIcon, size: 18, color: _iconColor),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _badgeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _badgeLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
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
                state == VerifState.done
                    ? doneLabel
                    : state == VerifState.pending
                        ? "Wird geprüft"
                        : state == VerifState.rejected
                            ? (cta ?? "Neu hochladen")
                            : (cta ?? "Erforderlich"),
                style: const TextStyle(
                  color: Colors.white54,
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
// EMAIL VERIF SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _EmailVerifSheet extends StatefulWidget {
  final String email;
  const _EmailVerifSheet({required this.email});

  @override
  State<_EmailVerifSheet> createState() => _EmailVerifSheetState();
}

class _EmailVerifSheetState extends State<_EmailVerifSheet> {
  bool _sent = false;
  bool _loading = false;
  String? _error;

  String _mapFirebaseError(Object e) {
    final msg = e.toString();
    if (msg.contains('too-many-requests')) {
      return 'Zu viele Versuche. Bitte warte kurz und versuche es erneut.';
    }
    if (msg.contains('network-request-failed')) {
      return 'Keine Internetverbindung.';
    }
    return 'Fehler beim Senden. Bitte versuche es erneut.';
  }

  Future<void> _sendEmail({bool isResend = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<IAuthRepository>().sendEmailVerification();
      if (!mounted) return;
      setState(() => _sent = true);
      if (isResend) {
        AppSnackbar.show(context, message: 'Bestätigungsmail wurde erneut gesendet.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = _mapFirebaseError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkVerified() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final verified =
          await context.read<IAuthRepository>().reloadAndCheckEmailVerified();
      if (!mounted) return;
      if (verified) {
        Navigator.pop(context);
        AppSnackbar.show(context, message: 'E-Mail erfolgreich verifiziert!');
      } else {
        setState(() => _error = 'E-Mail noch nicht bestätigt. Bitte den Link in der Mail antippen.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = _mapFirebaseError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          const SizedBox(height: 20),
          const Text(
            "E-Mail verifizieren",
            style: TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _sent
                ? "Wir haben eine Bestätigungsmail an ${widget.email} gesendet.\nBitte öffne die E-Mail und tippe auf den Link.\n\nFalls du keine E-Mail siehst, prüfe deinen Spam-Ordner."
                : "Zur Verifizierung senden wir dir eine E-Mail an ${widget.email}.",
            style: const TextStyle(
                color: Colors.white54, fontSize: 13, height: 1.5),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style:
                    const TextStyle(color: Color(0xFFE63946), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          if (!_sent)
            _SheetButton(
              label: "Bestätigungsmail senden",
              loading: _loading,
              onTap: _sendEmail,
            )
          else
            _SheetButton(
              label: "Bestätigung prüfen",
              loading: _loading,
              onTap: _checkVerified,
            ),
          if (_sent) ...[
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: _loading ? null : () => _sendEmail(isResend: true),
                child: const Text(
                  "E-Mail erneut senden",
                  style: TextStyle(color: Color(0xFF4A80F0), fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHONE VERIF SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneVerifSheet extends StatefulWidget {
  const _PhoneVerifSheet();

  @override
  State<_PhoneVerifSheet> createState() => _PhoneVerifSheetState();
}

class _PhoneVerifSheetState extends State<_PhoneVerifSheet> {
  final _ctrl = TextEditingController(text: '+43');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _ctrl.text.trim();
    if (phone.length < 8) {
      setState(() => _error = 'Bitte eine gültige Telefonnummer eingeben.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<IAuthRepository>();
      if (!kPhoneVerifEnabled) {
        await auth.savePhone(phone);
        if (mounted) {
          Navigator.pop(context);
          AppSnackbar.show(context, message: 'Telefonnummer gespeichert.');
        }
      } else {
        await auth.startPhoneVerification(
          phone,
          onCodeSent: (vId) {
            if (!mounted) return;
            Navigator.pop(context);
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF1A1F2E),
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => _OtpSheet(
                phone: phone,
                verificationId: vId,
              ),
            );
          },
          onError: (err) {
            if (mounted) setState(() => _error = err);
          },
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          const SizedBox(height: 20),
          const Text(
            "Telefon verifizieren",
            style: TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            kPhoneVerifEnabled
                ? "Du erhältst einen SMS-Code zur Bestätigung."
                : "Gib deine Telefonnummer ein. Sie wird in deinem Profil gespeichert.",
            style:
                const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          _SheetTextField(
            controller: _ctrl,
            label: "Telefonnummer",
            keyboardType: TextInputType.phone,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style:
                    const TextStyle(color: Color(0xFFE63946), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          _SheetButton(
            label: kPhoneVerifEnabled ? "SMS-Code senden" : "Speichern",
            loading: _loading,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP SHEET (nur bei kPhoneVerifEnabled = true)
// ─────────────────────────────────────────────────────────────────────────────

class _OtpSheet extends StatefulWidget {
  final String phone;
  final String verificationId;
  const _OtpSheet({required this.phone, required this.verificationId});

  @override
  State<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends State<_OtpSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final code = _ctrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Bitte den 6-stelligen Code eingeben.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context
          .read<IAuthRepository>()
          .confirmPhoneCode(widget.verificationId, code);
      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.show(context, message: 'Telefon erfolgreich verifiziert!');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Ungültiger Code.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          const SizedBox(height: 20),
          const Text(
            "SMS-Code eingeben",
            style: TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            "Wir haben einen 6-stelligen Code an ${widget.phone} gesendet.",
            style:
                const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          _SheetTextField(
            controller: _ctrl,
            label: "6-stelliger Code",
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style:
                    const TextStyle(color: Color(0xFFE63946), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          _SheetButton(
            label: "Bestätigen",
            loading: _loading,
            onTap: _confirm,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LICENSE SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _LicenseSheet extends StatefulWidget {
  const _LicenseSheet();

  @override
  State<_LicenseSheet> createState() => _LicenseSheetState();
}

class _LicenseSheetState extends State<_LicenseSheet> {
  bool _loading = false;
  bool _accepted = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (picked == null || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<IAuthRepository>().uploadLicense(File(picked.path));
      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.show(context,
            message: 'Führerschein hochgeladen. Wird in Kürze geprüft.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Upload fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSourceChoice() {
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
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: Colors.white70),
              title: const Text('Galerie',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white70),
              title: const Text('Kamera',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          const SizedBox(height: 20),
          const Text(
            "Führerschein hochladen",
            style: TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            "Lade ein klares Foto deines Führerscheins hoch. Das Foto wird ausschließlich manuell durch den Betreiber geprüft und nur zur Verifizierung verwendet.",
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _accepted,
                onChanged: (v) => setState(() => _accepted = v ?? false),
                fillColor: WidgetStateProperty.resolveWith<Color>(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.blueAccent
                      : Colors.white30,
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    children: [
                      const TextSpan(text: 'Ich stimme der Verarbeitung meines Führerschein-Fotos gemäß der '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            AppRoute(
                              builder: (_) => const LegalPage(
                                title: 'Datenschutzerklärung',
                                content: kDatenschutzText,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Datenschutzerklärung',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' zu.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style:
                    const TextStyle(color: Color(0xFFE63946), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _SheetButton(
                  label: "Foto auswählen",
                  onTap: _accepted ? _showSourceChoice : null,
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME TOWN SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTownSheet extends StatefulWidget {
  final String current;
  const _HomeTownSheet({required this.current});

  @override
  State<_HomeTownSheet> createState() => _HomeTownSheetState();
}

class _HomeTownSheetState extends State<_HomeTownSheet> {
  late final TextEditingController _ctrl;
  bool _loading = false;
  String? _error;
  String? _selectedName;
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedLat == null) {
      if (_ctrl.text.trim() == widget.current.trim()) {
        Navigator.pop(context);
        return;
      }
      setState(() =>
          _error = 'Bitte eine Gemeinde aus der Vorschlagsliste auswählen.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<IAuthRepository>().setHomeTown(
            _selectedName!,
            lat: _selectedLat,
            lng: _selectedLng,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          const SizedBox(height: 20),
          const Text(
            "Heimatgemeinde",
            style: TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            "Gib an, aus welcher Gemeinde du kommst, um Events und Mitfahrten dorthin zu filtern.",
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          GooglePlaceAutoCompleteTextField(
            textEditingController: _ctrl,
            googleAPIKey: "AIzaSyB97RZAMf-fmZKhdFFniU20CqK0QWCV3KE",
            inputDecoration: InputDecoration(
              labelText: "Gemeinde",
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF4A80F0), width: 1.5),
              ),
            ),
            textStyle: const TextStyle(color: Colors.white),
            boxDecoration: const BoxDecoration(color: Colors.transparent),
            debounceTime: 500,
            countries: const ["at"],
            placeType: PlaceType.cities,
            language: 'de',
            isLatLngRequired: true,
            getPlaceDetailWithLatLng: (prediction) {
              setState(() {
                _selectedName =
                    prediction.structuredFormatting?.mainText ??
                        prediction.description ??
                        '';
                _selectedLat = double.tryParse(prediction.lat ?? '');
                _selectedLng = double.tryParse(prediction.lng ?? '');
                _error = null;
              });
            },
            itemClick: (prediction) {
              _ctrl.text = prediction.structuredFormatting?.mainText ??
                  prediction.description ??
                  '';
              _ctrl.selection = TextSelection.fromPosition(
                TextPosition(offset: _ctrl.text.length),
              );
            },
            itemBuilder: (context, index, prediction) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3F78),
                  border: Border(
                    left: BorderSide(
                      color: const Color(0xFF5DA9FF).withValues(alpha: 0.6),
                      width: 3,
                    ),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Color(0xFF5DA9FF), size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        prediction.description ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            seperatedBuilder: Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style:
                    const TextStyle(color: Color(0xFFE63946), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          _SheetButton(label: "Speichern", loading: _loading, onTap: _save),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAR INFO SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CarInfoSheet extends StatefulWidget {
  final CarInfo? current;
  const _CarInfoSheet({this.current});

  @override
  State<_CarInfoSheet> createState() => _CarInfoSheetState();
}

class _CarInfoSheetState extends State<_CarInfoSheet> {
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _seatsCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _makeCtrl = TextEditingController(text: c?.make ?? '');
    _modelCtrl = TextEditingController(text: c?.model ?? '');
    _colorCtrl = TextEditingController(text: c?.color ?? '');
    _seatsCtrl =
        TextEditingController(text: c?.seats != null ? '${c!.seats}' : '');
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final make = _makeCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    if (make.isEmpty || model.isEmpty) {
      setState(() => _error = 'Marke und Modell sind erforderlich.');
      return;
    }
    final seats = int.tryParse(_seatsCtrl.text.trim());
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<IAuthRepository>().updateCarInfo(
            make,
            model,
            _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
            seats,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          const SizedBox(height: 20),
          const Text(
            "Auto-Infos",
            style: TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            "Deine Auto-Daten helfen Mitfahrern zu wissen, was sie erwartet.",
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          _SheetTextField(
              controller: _makeCtrl, label: "Marke (z. B. VW)"),
          const SizedBox(height: 10),
          _SheetTextField(
              controller: _modelCtrl, label: "Modell (z. B. Golf)"),
          const SizedBox(height: 10),
          _SheetTextField(
              controller: _colorCtrl,
              label: "Farbe (optional)"),
          const SizedBox(height: 10),
          _SheetTextField(
            controller: _seatsCtrl,
            label: "Verfügbare Sitzplätze (optional)",
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style:
                    const TextStyle(color: Color(0xFFE63946), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          _SheetButton(label: "Speichern", loading: _loading, onTap: _save),
        ],
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

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _SheetButton({
    required this.label,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color:
              loading ? Colors.white12 : const Color(0xFF4A80F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
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

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _SheetTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF4A80F0), width: 1.5),
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

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

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

// ─────────────────────────────────────────────────────────────────────────────
// OWN REVIEWS SECTION
// Zeigt die eigenen empfangenen Bewertungen oder einen Platzhalter.
// ─────────────────────────────────────────────────────────────────────────────

class _OwnReviewsSection extends StatefulWidget {
  final AppUser user;

  const _OwnReviewsSection({required this.user});

  @override
  State<_OwnReviewsSection> createState() => _OwnReviewsSectionState();
}

class _OwnReviewsSectionState extends State<_OwnReviewsSection> {
  List<Review>? _reviews;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void didUpdateWidget(_OwnReviewsSection old) {
    super.didUpdateWidget(old);
    if (old.user.ratingCount != widget.user.ratingCount) {
      _loadReviews();
    }
  }

  Future<void> _loadReviews() async {
    try {
      // kein orderBy → kein Composite Index nötig; client-side sortieren
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('reviewedId', isEqualTo: widget.user.userId)
          .limit(20)
          .get();
      if (mounted) {
        final sorted = snap.docs.map(Review.fromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        setState(() => _reviews = sorted.take(2).toList());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('_loadReviews error: $e');
      if (mounted) setState(() => _reviews = []);
    }
  }

  void _openList() {
    Navigator.push(
      context,
      AppRoute(
        builder: (_) => ReviewsListPage(
          userId: widget.user.userId,
          userName: widget.user.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ladezustand
    if (_reviews == null) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2),
        ),
      );
    }

    // Leerer Zustand — tappbar damit man trotzdem zur Liste navigieren kann
    if (_reviews!.isEmpty) {
      return GestureDetector(
        onTap: _openList,
        child: SizedBox(
          width: double.infinity,
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.star_border_rounded, color: Colors.white54),
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
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    }

    // Reviews vorhanden
    final count = _reviews!.length;
    final totalCount = widget.user.ratingCount > 0 ? widget.user.ratingCount : count;
    final avg = widget.user.ratingAvg ??
        (_reviews!.map((r) => r.rating.toDouble()).reduce((a, b) => a + b) / count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zusammenfassung
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < avg.round();
                      return Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 18,
                        color: filled ? Colors.amber : Colors.white24,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalCount ${totalCount == 1 ? 'Bewertung' : 'Bewertungen'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Review-Karten (Vorschau: max. 2)
        for (final review in _reviews!) ...[
          ReviewCard(
            review: review,
            onReport: () => showReviewReportSheet(context, review),
            onReviewerTap: () => Navigator.push(
              context,
              AppRoute(
                builder: (_) => PublicProfilePage(
                  userId: review.reviewerId,
                  name: review.reviewerName,
                  photoUrl: review.reviewerPhotoUrl,
                ),
              ),
            ),
          ),
          if (review != _reviews!.last) const SizedBox(height: 6),
        ],
        if (totalCount > 2) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _openList,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Alle $totalCount Bewertungen ansehen',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.white38, size: 14),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
