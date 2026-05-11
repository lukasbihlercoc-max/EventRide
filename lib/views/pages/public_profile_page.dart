// public_profile_page.dart
// Öffentliches Profil eines anderen Nutzers (read-only).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/review.dart';
import 'package:my_app/views/widgets/app_card.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/trust_shields_widget.dart';
import 'package:my_app/views/widgets/review_card_widget.dart';
import 'package:my_app/views/widgets/user_avatar_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────


Color _parseCarColor(String? raw) {
  final s = raw?.toLowerCase() ?? '';
  if (s.contains('schwarz') || s.contains('black')) return const Color(0xFF1A1A1A);
  if (s.contains('weiß') || s.contains('weiss') || s.contains('white')) return const Color(0xFFF0F0F0);
  if (s.contains('silber') || s.contains('silver')) return const Color(0xFFB8B8B8);
  if (s.contains('anthrazit') || s.contains('anthracite')) return const Color(0xFF2C2C3A);
  if (s.contains('grau') || s.contains('grey') || s.contains('gray')) return const Color(0xFF808080);
  if (s.contains('dunkelblau') || s.contains('navy')) return const Color(0xFF0D2137);
  if (s.contains('blau') || s.contains('blue')) return const Color(0xFF1565C0);
  if (s.contains('rot') || s.contains('red')) return const Color(0xFFD32F2F);
  if (s.contains('grün') || s.contains('green')) return const Color(0xFF388E3C);
  if (s.contains('gelb') || s.contains('yellow')) return const Color(0xFFFBC02D);
  if (s.contains('orange')) return const Color(0xFFE64A19);
  if (s.contains('braun') || s.contains('brown')) return const Color(0xFF5D4037);
  if (s.contains('beige') || s.contains('creme') || s.contains('cream')) return const Color(0xFFD7C4A3);
  if (s.contains('lila') || s.contains('purple') || s.contains('violet')) return const Color(0xFF6A1B9A);
  return const Color(0xFF607D8B);
}

bool _istVergangen(DateTime eventDatum) {
  if (eventDatum.year == 2000) return false;
  final ende = eventDatum.add(const Duration(hours: 3));
  final anzeigeGrenze = ende.add(const Duration(days: 30));
  final now = DateTime.now();
  return ende.isBefore(now) && anzeigeGrenze.isAfter(now);
}

String _formatMemberSince(DateTime dt) {
  const months = [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];
  return '${months[dt.month - 1]} ${dt.year}';
}

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
  bool _licenseVerified = false;
  int _fahrtCount = 0;
  int _mitfahrerCount = 0;
  DateTime? _memberSince;
  double? _ratingAvg;
  int _ratingCount = 0;
  List<Review> _reviews = [];

  bool _canReview = false;
  bool _hasReviewed = false;

  CarInfo? _car;

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
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      final results = await Future.wait([
        db.collection('users').doc(widget.userId).get(),
        db.collection('fahrten').where('ownerId', isEqualTo: widget.userId).count().get(),
        db
            .collection('reviews')
            .where('reviewedId', isEqualTo: widget.userId)
            .limit(20)
            .get(),
        db
            .collection('anfragen')
            .where('fahrtOwnerId', isEqualTo: widget.userId)
            .where('status', isEqualTo: 1)
            .count()
            .get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final fahrtCount = (results[1] as AggregateQuerySnapshot).count ?? 0;
      final reviewSnap = results[2] as QuerySnapshot;
      final mitfahrerCount = (results[3] as AggregateQuerySnapshot).count ?? 0;

      bool canReview = false;
      bool hasReviewed = false;
      if (currentUid != null && currentUid != widget.userId) {
        final sharedResults = await Future.wait<QuerySnapshot>([
          db
              .collection('anfragen')
              .where('fahrtOwnerId', isEqualTo: widget.userId)
              .where('requesterId', isEqualTo: currentUid)
              .where('status', isEqualTo: 1)
              .get(),
          db
              .collection('anfragen')
              .where('fahrtOwnerId', isEqualTo: currentUid)
              .where('requesterId', isEqualTo: widget.userId)
              .where('status', isEqualTo: 1)
              .get(),
        ]);

        final allAnfragen = [...sharedResults[0].docs, ...sharedResults[1].docs];

        bool hasPastEvent = false;
        for (final anfrageDoc in allAnfragen) {
          final fahrtId =
              (anfrageDoc.data() as Map<String, dynamic>)['fahrtId'] as String?;
          if (fahrtId == null) continue;
          final fahrtDoc = await db.collection('fahrten').doc(fahrtId).get();
          if (!fahrtDoc.exists) continue;
          final eventId =
              (fahrtDoc.data() as Map<String, dynamic>)['eventId'] as String?;
          if (eventId == null) continue;
          final eventDoc = await db.collection('events').doc(eventId).get();
          if (!eventDoc.exists) continue;
          final rawDatum =
              (eventDoc.data() as Map<String, dynamic>)['datum'];
          DateTime? eventDatum;
          if (rawDatum is String) {
            eventDatum = DateTime.tryParse(rawDatum);
          } else if (rawDatum is Timestamp) {
            eventDatum = rawDatum.toDate();
          }
          if (eventDatum != null && _istVergangen(eventDatum)) {
            hasPastEvent = true;
            break;
          }
        }

        if (hasPastEvent) {
          final alreadyReviewedSnap = await db
              .collection('reviews')
              .where('reviewerId', isEqualTo: currentUid)
              .where('reviewedId', isEqualTo: widget.userId)
              .limit(1)
              .get();
          hasReviewed = alreadyReviewedSnap.docs.isNotEmpty;
          canReview = true;
        }
      }

      if (!mounted) return;

      if (userDoc.exists) {
        final d = userDoc.data()! as Map<String, dynamic>;
        final first = d['firstName'] as String? ?? '';
        final last = d['lastName'] as String? ?? '';
        final fullName = '$first $last'.trim();

        DateTime? memberSince;
        final ts = d['createdAt'];
        if (ts is Timestamp) memberSince = ts.toDate();

        setState(() {
          _name = fullName.isNotEmpty ? fullName : widget.name;
          _photoUrl = (d['photoUrl'] as String?)?.isNotEmpty == true
              ? d['photoUrl'] as String
              : widget.photoUrl;
          _homeTown =
              (d['homeTown'] as String?)?.isNotEmpty == true ? d['homeTown'] as String : null;
          _hasPhone = d['phoneVerified'] as bool? ?? false;
          _emailVerified = d['emailVerified'] as bool? ?? false;
          _licenseVerified = (d['licenseStatus'] as String?) == 'verified';
          _memberSince = memberSince;
          _fahrtCount = fahrtCount;
          _mitfahrerCount = mitfahrerCount;
          _ratingAvg = (d['ratingAvg'] as num?)?.toDouble();
          _ratingCount = (d['ratingCount'] as num?)?.toInt() ?? 0;
          final allReviews = reviewSnap.docs.map(Review.fromDoc).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _reviews = allReviews.take(5).toList();
          _canReview = canReview;
          _hasReviewed = hasReviewed;
          final carMap = d['car'] as Map<String, dynamic>?;
          if (carMap != null) {
            final ci = CarInfo.fromMap(carMap);
            _car = (ci.make.isNotEmpty || ci.model.isNotEmpty) ? ci : null;
          }
          _loading = false;
        });
      } else {
        setState(() {
          _fahrtCount = fahrtCount;
          _mitfahrerCount = mitfahrerCount;
          final allReviews2 = reviewSnap.docs.map(Review.fromDoc).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _reviews = allReviews2.take(5).toList();
          _canReview = canReview;
          _hasReviewed = hasReviewed;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewBottomSheet(
        reviewedId: widget.userId,
        reviewedName: _name,
        onSubmitted: _onReviewSubmitted,
      ),
    );
  }

  void _onReviewSubmitted() {
    setState(() {
      _hasReviewed = true;
      _canReview = false;
    });
    _load();
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _ProfileHeader(
                        name: _name,
                        photoUrl: _photoUrl,
                        emailVerified: _emailVerified,
                        phoneVerified: _hasPhone,
                        licenseVerified: _licenseVerified,
                        memberSince: _memberSince,
                        homeTown: _homeTown,
                      ),
                      const SizedBox(height: 20),
                      _StatsCard(
                        fahrtCount: _fahrtCount,
                        mitfahrerCount: _mitfahrerCount,
                        ratingAvg: _ratingAvg,
                        ratingCount: _ratingCount,
                      ),
                      if (_car != null) ...[
                        const SizedBox(height: 12),
                        _CarCard(car: _car!),
                      ],
                      const SizedBox(height: 20),
                      _ReviewsSection(
                        avg: _ratingAvg,
                        count: _ratingCount,
                        reviews: _reviews,
                        canReview: _canReview && !_hasReviewed,
                        hasReviewed: _hasReviewed,
                        onReview: _openReviewSheet,
                      ),
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
  final bool emailVerified;
  final bool phoneVerified;
  final bool licenseVerified;
  final DateTime? memberSince;
  final String? homeTown;

  const _ProfileHeader({
    required this.name,
    required this.photoUrl,
    required this.emailVerified,
    required this.phoneVerified,
    required this.licenseVerified,
    required this.memberSince,
    required this.homeTown,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (memberSince != null) subtitleParts.add('Mitglied seit ${_formatMemberSince(memberSince!)}');
    if (homeTown != null) subtitleParts.add(homeTown!);

    return Column(
      children: [
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
          child: UserAvatarWidget(name: name, photoUrl: photoUrl, radius: 52),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            TrustShields(
              filled: [emailVerified, phoneVerified, licenseVerified].where((v) => v).length,
              size: 16,
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showTrustInfo(context),
              child: const Icon(Icons.info_outline, size: 14, color: Colors.white38),
            ),
          ],
        ),
        if (subtitleParts.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitleParts.join(' · '),
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  void _showTrustInfo(BuildContext context) {
    final verified = <String>[
      if (emailVerified) 'E-Mail verifiziert',
      if (phoneVerified) 'Telefon verifiziert',
      if (licenseVerified) 'Führerschein verifiziert',
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verifikationen',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              if (verified.isEmpty)
                const Text('Noch keine Verifikationen vorhanden.', style: TextStyle(color: Colors.white70))
              else
                ...verified.map((label) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, size: 16, color: Color(0xFF4A80F0)),
                          const SizedBox(width: 8),
                          Text(label, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK', style: TextStyle(color: Colors.blueAccent)),
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
// STATS CARD  (Fahrten | Mitfahrer | Bewertung)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final int fahrtCount;
  final int mitfahrerCount;
  final double? ratingAvg;
  final int ratingCount;

  const _StatsCard({
    required this.fahrtCount,
    required this.mitfahrerCount,
    required this.ratingAvg,
    required this.ratingCount,
  });

  @override
  Widget build(BuildContext context) {
    final showRating = ratingAvg != null && ratingCount >= 1;
    final ratingLabel = showRating ? ratingAvg!.toStringAsFixed(1) : '—';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _StatCell(value: '$fahrtCount', label: 'Fahrten')),
            VerticalDivider(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
              thickness: 1,
            ),
            Expanded(child: _StatCell(value: '$mitfahrerCount', label: 'Mitfahrer')),
            VerticalDivider(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
              thickness: 1,
            ),
            Expanded(child: _StatCell(value: ratingLabel, label: 'Bewertung')),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;

  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// CAR CARD  (horizontal layout)
// ─────────────────────────────────────────────────────────────────────────────

class _CarCard extends StatelessWidget {
  final CarInfo car;
  const _CarCard({required this.car});

  @override
  Widget build(BuildContext context) {
    final color = _parseCarColor(car.color);
    final carName = [car.make, car.model].where((s) => s.isNotEmpty).join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'FAHRZEUG',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Icon(
                    Icons.directions_car_rounded,
                    size: 40,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (carName.isNotEmpty)
                      Text(
                        carName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (car.color != null) ...[
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white38, width: 0.5),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            car.color!,
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ],
                        if (car.color != null && car.seats != null)
                          const Text(
                            ' · ',
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        if (car.seats != null)
                          Text(
                            '${car.seats} Plätze',
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEWS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final double? avg;
  final int count;
  final List<Review> reviews;
  final bool canReview;
  final bool hasReviewed;
  final VoidCallback onReview;

  const _ReviewsSection({
    required this.avg,
    required this.count,
    required this.reviews,
    required this.canReview,
    required this.hasReviewed,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bewertungen',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (avg != null && count >= 3) ...[
          _RatingSummary(avg: avg!, count: count),
          const SizedBox(height: 8),
        ],
        if (count > 0) _ReviewList(reviews: reviews) else const _ReviewsEmptyState(),
        if (canReview) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onReview,
              icon: const Icon(Icons.star_rounded, size: 18),
              label: const Text('Bewertung hinterlassen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        if (hasReviewed) ...[
          const SizedBox(height: 12),
          _ReviewedHint(),
        ],
      ],
    );
  }
}

class _ReviewsEmptyState extends StatelessWidget {
  const _ReviewsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            'Noch keine Bewertungen vorhanden',
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'Nach gemeinsamen Fahrten können Nutzer Bewertungen hinterlassen.',
            style: TextStyle(color: Colors.white24, fontSize: 12, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RATING SUMMARY
// ─────────────────────────────────────────────────────────────────────────────

class _RatingSummary extends StatelessWidget {
  final double avg;
  final int count;

  const _RatingSummary({required this.avg, required this.count});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            avg.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
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
                    size: 16,
                    color: filled ? Colors.amber : Colors.white24,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '$count ${count == 1 ? 'Bewertung' : 'Bewertungen'}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEW LIST
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewList extends StatelessWidget {
  final List<Review> reviews;

  const _ReviewList({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final review in reviews) ...[
          _ReviewCard(review: review),
          if (review != reviews.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  void _showReportSheet(BuildContext context) {
    final reporterId = FirebaseAuth.instance.currentUser?.uid;
    if (reporterId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _ReviewReportSheet(
        review: review,
        reporterId: reporterId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final canReport = currentUid != null && currentUid != review.reviewerId;

    return ReviewCard(
      review: review,
      onReport: canReport ? () => _showReportSheet(context) : null,
    );
  }
}

class _ReviewReportSheet extends StatefulWidget {
  final Review review;
  final String reporterId;

  const _ReviewReportSheet({required this.review, required this.reporterId});

  @override
  State<_ReviewReportSheet> createState() => _ReviewReportSheetState();
}

class _ReviewReportSheetState extends State<_ReviewReportSheet> {
  bool _loading = false;
  bool _done = false;

  Future<void> _report(String reason) async {
    if (_loading || _done) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('review_reports').add({
        'reviewId': widget.review.id,
        'reporterId': widget.reporterId,
        'reviewedUserId': widget.review.reviewedId,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() => _done = true);
        Navigator.pop(context);
        AppSnackbar.show(context,
            message: 'Gemeldet. Wir prüfen die Bewertung.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        AppSnackbar.show(context, message: 'Fehler beim Melden. Bitte erneut versuchen.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const reasons = [
      ('Beleidigung', Icons.sentiment_very_dissatisfied_outlined),
      ('Falschinformation', Icons.info_outline),
      ('Spam', Icons.block_outlined),
      ('Unangemessen', Icons.flag_outlined),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.flag_outlined, color: Colors.white54, size: 18),
                SizedBox(width: 8),
                Text(
                  'Bewertung melden',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white54),
            )
          else
            for (final (label, icon) in reasons)
              ListTile(
                leading: Icon(icon, color: Colors.white54, size: 18),
                title: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                onTap: () => _report(label),
                dense: true,
                visualDensity: const VisualDensity(vertical: -1),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEWED HINT
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewedHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: Colors.white38, size: 16),
          SizedBox(width: 8),
          Text(
            'Du hast diese Person bereits bewertet',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEW BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewBottomSheet extends StatefulWidget {
  final String reviewedId;
  final String reviewedName;
  final VoidCallback onSubmitted;

  const _ReviewBottomSheet({
    required this.reviewedId,
    required this.reviewedName,
    required this.onSubmitted,
  });

  @override
  State<_ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<_ReviewBottomSheet> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<String?> _findSharedFahrtId() async {
    final db = FirebaseFirestore.instance;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return null;

    final snap1 = await db
        .collection('anfragen')
        .where('fahrtOwnerId', isEqualTo: widget.reviewedId)
        .where('requesterId', isEqualTo: currentUid)
        .where('status', isEqualTo: 1)
        .limit(1)
        .get();

    if (snap1.docs.isNotEmpty) return snap1.docs.first.data()['fahrtId'] as String?;

    final snap2 = await db
        .collection('anfragen')
        .where('fahrtOwnerId', isEqualTo: currentUid)
        .where('requesterId', isEqualTo: widget.reviewedId)
        .where('status', isEqualTo: 1)
        .limit(1)
        .get();

    if (snap2.docs.isNotEmpty) return snap2.docs.first.data()['fahrtId'] as String?;
    return null;
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      AppSnackbar.show(
        context,
        message: 'Bitte wähle mindestens 1 Stern',
        accentColor: Colors.orange,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final fahrtId = await _findSharedFahrtId();
      if (fahrtId == null) {
        if (mounted) {
          AppSnackbar.show(
            context,
            message: 'Keine gemeinsame Fahrt gefunden',
            accentColor: Colors.redAccent,
          );
        }
        return;
      }

      await FirebaseFunctions.instance.httpsCallable('submitReview').call({
        'reviewedId': widget.reviewedId,
        'fahrtId': fahrtId,
        'rating': _selectedRating,
        'comment': _commentController.text.trim(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSubmitted();
        AppSnackbar.show(
          context,
          message: 'Bewertung erfolgreich abgegeben',
          accentColor: Colors.amber,
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        final msg = switch (e.code) {
          'unauthenticated' => 'Bitte melde dich an',
          'invalid-argument' => e.message ?? 'Ungültige Eingabe',
          'already-exists' => 'Du hast diese Person bereits bewertet',
          'failed-precondition' => e.message ?? 'Bewertung noch nicht möglich',
          'not-found' => 'Fahrt nicht gefunden',
          _ => 'Bewertung konnte nicht abgegeben werden',
        };
        AppSnackbar.show(context, message: msg, accentColor: Colors.redAccent);
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Fehler beim Abgeben der Bewertung',
          accentColor: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.reviewedName} bewerten',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final filled = i < _selectedRating;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 40,
                      color: filled ? Colors.amber : Colors.white24,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _commentController,
            maxLength: 120,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Kommentar (optional)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              counterStyle: const TextStyle(color: Colors.white38, fontSize: 11),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4A80F0), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Bewertung abgeben',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
