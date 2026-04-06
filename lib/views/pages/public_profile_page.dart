// public_profile_page.dart
// Öffentliches Profil eines anderen Nutzers (read-only).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/widgets/app_card.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/user_avatar_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class PublicProfilePage extends StatefulWidget {
  final String userId;
  final String name;
  final String? photoUrl;

  const PublicProfilePage({
    super.key,
    required this.userId,
    required this.name,
    this.photoUrl,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  bool _loading = true;

  late String _name;
  String? _photoUrl;
  String? _homeTown;
  bool _hasPhone = false;
  bool _emailVerified = false;
  int _fahrtCount = 0;
  int? _memberSinceYear;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _photoUrl = widget.photoUrl;
    _load();
  }

  Future<void> _load() async {
    try {
      final db = FirebaseFirestore.instance;

      final userDoc =
          await db.collection('users').doc(widget.userId).get();

      final fahrtSnap = await db
          .collection('fahrten')
          .where('ownerId', isEqualTo: widget.userId)
          .count()
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final d = userDoc.data()!;
        final first = d['firstName'] as String? ?? '';
        final last  = d['lastName']  as String? ?? '';
        final fullName = '$first $last'.trim();

        int? year;
        final ts = d['createdAt'];
        if (ts is Timestamp) year = ts.toDate().year;

        setState(() {
          _name = fullName.isNotEmpty ? fullName : widget.name;
          _photoUrl = (d['photoUrl'] as String?)?.isNotEmpty == true
              ? d['photoUrl'] as String
              : widget.photoUrl;
          _homeTown = (d['homeTown'] as String?)?.isNotEmpty == true
              ? d['homeTown'] as String
              : null;
          _hasPhone = (d['phone'] as String?)?.isNotEmpty == true;
          _emailVerified = (d['email'] as String?)?.isNotEmpty == true;
          _memberSinceYear = year;
          _fahrtCount = fahrtSnap.count ?? 0;
          _loading = false;
        });
      } else {
        setState(() {
          _fahrtCount = fahrtSnap.count ?? 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _ProfileHeader(
                        name: _name,
                        photoUrl: _photoUrl,
                        fahrtCount: _fahrtCount,
                      ),
                      const SizedBox(height: 24),
                      _InfoCard(
                        fahrtCount: _fahrtCount,
                        homeTown: _homeTown,
                        memberSinceYear: _memberSinceYear,
                      ),
                      const SizedBox(height: 16),
                      _TrustBadgeRow(
                        emailVerified: _emailVerified,
                        phoneVerified: _hasPhone,
                      ),
                      // Bewertungen: Abschnitt wird erst angezeigt,
                      // wenn echte Reviews vorhanden sind.
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final int fahrtCount;

  const _ProfileHeader({
    required this.name,
    required this.photoUrl,
    required this.fahrtCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar mit Glow
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A80F0).withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: UserAvatarWidget(
            name: name,
            photoUrl: photoUrl,
            radius: 52,
          ),
        ),

        const SizedBox(height: 16),

        // Name
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Fahrten-Badge (nur wenn vorhanden)
        if (fahrtCount > 0)
          _Chip(
            icon: Icons.directions_car_rounded,
            label:
                '$fahrtCount ${fahrtCount == 1 ? 'Fahrt' : 'Fahrten'} angeboten',
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white60),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final int fahrtCount;
  final String? homeTown;
  final int? memberSinceYear;

  const _InfoCard({
    required this.fahrtCount,
    required this.homeTown,
    required this.memberSinceYear,
  });

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label})>[
      (
        icon: Icons.directions_car_rounded,
        label: '$fahrtCount ${fahrtCount == 1 ? 'Fahrt' : 'Fahrten'}',
      ),
      if (homeTown != null)
        (
          icon: Icons.location_on_outlined,
          label: homeTown!,
        ),
      if (memberSinceYear != null)
        (
          icon: Icons.calendar_today_outlined,
          label: 'Dabei seit $memberSinceYear',
        ),
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _InfoRow(icon: items[i].icon, label: items[i].label),
            if (i < items.length - 1) ...[
              const SizedBox(height: 4),
              Divider(
                color: Colors.white.withValues(alpha: 0.08),
                height: 20,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: Colors.white60),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRUST BADGES
// ─────────────────────────────────────────────────────────────────────────────

class _TrustBadgeRow extends StatelessWidget {
  final bool emailVerified;
  final bool phoneVerified;

  const _TrustBadgeRow({
    required this.emailVerified,
    required this.phoneVerified,
  });

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (emailVerified)
        _TrustBadge(
            icon: Icons.verified_outlined, label: 'E-Mail bestätigt'),
      if (phoneVerified)
        _TrustBadge(
            icon: Icons.phone_outlined, label: 'Telefon bestätigt'),
    ];

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: badges,
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF52B788).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF74C69D)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF74C69D),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
