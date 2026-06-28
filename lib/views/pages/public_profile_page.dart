// public_profile_page.dart
// Öffentliches Profil eines anderen Nutzers (read-only).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/data/block_service.dart';
import 'package:my_app/data/review.dart';
import 'package:my_app/views/widgets/app_card.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/trust_shields_widget.dart';
import 'package:my_app/views/widgets/app_bottom_sheet.dart';
import 'package:my_app/views/widgets/review_card_widget.dart';
import 'package:my_app/views/widgets/user_avatar_widget.dart';
import 'package:provider/provider.dart';

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
  final String? fahrtId;

  const PublicProfilePage({
    super.key,
    required this.userId,
    required this.name,
    this.photoUrl,
    this.fahrtId,
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
  String? _sharedFahrtId;
  bool _isBlockedByThem = false;

  CarInfo? _car;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _photoUrl = widget.photoUrl;
    _load();
  }

  Future<void> _load() async {
    final db = FirebaseFirestore.instance;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // Schritt 1: User-Dokument laden (Schilde hängen nur davon ab)
    DocumentSnapshot? userDoc;
    try {
      userDoc = await db.collection('users').doc(widget.userId).get();
    } catch (_) {}

    // Schritt 2: Counts + Reviews parallel laden (eigener try-catch)
    int fahrtCount = 0;
    int mitfahrerCount = 0;
    QuerySnapshot? reviewSnap;
    try {
      final results = await Future.wait([
        db.collection('fahrten').where('ownerId', isEqualTo: widget.userId).count().get(),
        db.collection('reviews').where('reviewedId', isEqualTo: widget.userId).limit(20).get(),
        db.collection('anfragen')
            .where('fahrtOwnerId', isEqualTo: widget.userId)
            .where('status', isEqualTo: 1)
            .count()
            .get(),
      ]);
      fahrtCount = (results[0] as AggregateQuerySnapshot).count ?? 0;
      reviewSnap = results[1] as QuerySnapshot;
      mitfahrerCount = (results[2] as AggregateQuerySnapshot).count ?? 0;
    } catch (_) {}

    // Schritt 3: Bewertungs-Berechtigung prüfen (eigener try-catch)
    bool canReview = false;
    bool hasReviewed = false;
    String? sharedFahrtId;
    try {
      if (currentUid != null && currentUid != widget.userId) {
        final sharedSnap = await db
            .collection('anfragen')
            .where('fahrtOwnerId', isEqualTo: widget.userId)
            .where('requesterId', isEqualTo: currentUid)
            .where('status', isEqualTo: 1)
            .get();

        for (final anfrageDoc in sharedSnap.docs) {
          final fahrtId = anfrageDoc.data()['fahrtId'] as String?;
          if (fahrtId == null) continue;
          final fahrtDoc = await db.collection('fahrten').doc(fahrtId).get();
          if (!fahrtDoc.exists) continue;
          final eventId =
              (fahrtDoc.data() as Map<String, dynamic>)['eventId'] as String?;
          if (eventId == null) continue;
          final eventDoc = await db.collection('events').doc(eventId).get();
          if (!eventDoc.exists) continue;
          final rawDatum = (eventDoc.data() as Map<String, dynamic>)['datum'];
          DateTime? eventDatum;
          if (rawDatum is String) {
            eventDatum = DateTime.tryParse(rawDatum);
          } else if (rawDatum is Timestamp) {
            eventDatum = rawDatum.toDate();
          }
          if (eventDatum != null && _istVergangen(eventDatum)) {
            sharedFahrtId = fahrtId;
            break;
          }
        }

        if (sharedFahrtId != null) {
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
    } catch (_) {}

    if (!mounted) return;

    if (userDoc != null && userDoc.exists) {
      final d = userDoc.data()! as Map<String, dynamic>;
      final first = d['firstName'] as String? ?? '';
      final last = d['lastName'] as String? ?? '';
      final fullName = '$first $last'.trim();

      final theirBlockedIds = (d['blockedUserIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [];
      final blockedByThem =
          currentUid != null && theirBlockedIds.contains(currentUid);

      DateTime? memberSince;
      final ts = d['createdAt'];
      if (ts is Timestamp) memberSince = ts.toDate();

      setState(() {
        _isBlockedByThem = blockedByThem;
        _name = fullName.isNotEmpty ? fullName : widget.name;
        _photoUrl = (d['photoUrl'] as String?)?.isNotEmpty == true
            ? d['photoUrl'] as String
            : widget.photoUrl;
        _homeTown = (d['homeTown'] as String?)?.isNotEmpty == true
            ? d['homeTown'] as String
            : null;
        _hasPhone = d['phoneVerified'] as bool? ?? false;
        _emailVerified = d['emailVerified'] as bool? ?? false;
        _licenseVerified = (d['licenseStatus'] as String?) == 'verified';
        _memberSince = memberSince;
        _fahrtCount = fahrtCount;
        _mitfahrerCount = mitfahrerCount;
        _ratingAvg = (d['ratingAvg'] as num?)?.toDouble();
        _ratingCount = (d['ratingCount'] as num?)?.toInt() ?? 0;
        final allReviews = (reviewSnap?.docs ?? []).map(Review.fromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _reviews = allReviews.take(5).toList();
        _canReview = canReview;
        _hasReviewed = hasReviewed;
        _sharedFahrtId = sharedFahrtId;
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
        final allReviews2 = (reviewSnap?.docs ?? []).map(Review.fromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _reviews = allReviews2.take(5).toList();
        _canReview = canReview;
        _hasReviewed = hasReviewed;
        _sharedFahrtId = sharedFahrtId;
        _loading = false;
      });
    }
  }

  void _openReviewSheet() {
    if (_sharedFahrtId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewBottomSheet(
        reviewedId: widget.userId,
        reviewedName: _name,
        fahrtId: _sharedFahrtId!,
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

  void _showReportSheet(BuildContext context) {
    String? selectedReason;
    showAppSheet(context, (ctx) {
      return StatefulBuilder(builder: (_, setSheetState) {
        return AppSheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSheetHeader(
                icon: Icons.flag_outlined,
                iconColor: Colors.orangeAccent,
                title: 'Nutzer melden',
              ),
              const SizedBox(height: 16),
              for (final reason in ['Spam', 'Belästigung', 'Fake-Profil', 'Sonstiges'])
                InkWell(
                  onTap: () => setSheetState(() => selectedReason = reason),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          selectedReason == reason
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selectedReason == reason
                              ? const Color(0xFFF5A04A)
                              : Colors.white38,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          reason,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              AppSheetPrimaryButton(
                label: 'Melden',
                onTap: selectedReason == null
                    ? () {}
                    : () async {
                        Navigator.pop(ctx);
                        final currentUid =
                            FirebaseAuth.instance.currentUser?.uid;
                        if (currentUid == null) return;
                        final blockSvc = context.read<BlockService>();
                        try {
                          await blockSvc.reportUser(
                            currentUid: currentUid,
                            targetUid: widget.userId,
                            reason: selectedReason!,
                          );
                          if (mounted) {
                            AppSnackbar.show(this.context,
                                message: 'Nutzer wurde gemeldet');
                          }
                        } catch (_) {
                          if (mounted) {
                            AppSnackbar.show(this.context,
                                message: 'Fehler beim Melden');
                          }
                        }
                      },
              ),
              const SizedBox(height: 10),
              AppSheetGhostButton(
                label: 'Abbrechen',
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      });
    });
  }

  void _showBlockDialog(BuildContext context) {
    showAppSheet(context, (ctx) {
      return AppBottomSheet(
        icon: Icons.block,
        iconColor: Colors.redAccent,
        title: 'Nutzer blockieren?',
        body:
            '$_name wird aus deinem Feed entfernt. Du kannst ihn/sie jederzeit über das Profil entsperren.',
        primaryLabel: 'Blockieren',
        secondaryLabel: 'Abbrechen',
        danger: true,
        onSecondary: () => Navigator.pop(ctx),
        onPrimary: () async {
          Navigator.pop(ctx);
          final currentUid = FirebaseAuth.instance.currentUser?.uid;
          if (currentUid == null) return;
          final blockSvc = context.read<BlockService>();
          try {
            await blockSvc.blockUser(
              currentUid: currentUid,
              targetUid: widget.userId,
            );
            if (mounted) {
              AppSnackbar.show(this.context,
                  message: '$_name blockiert');
            }
          } catch (_) {
            if (mounted) {
              AppSnackbar.show(this.context,
                  message: 'Fehler beim Blockieren');
            }
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final blockService = context.watch<BlockService>();
    final isBlocked = blockService.isBlocked(widget.userId) || _isBlockedByThem;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = currentUid == widget.userId;

    final appBar = AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: isOwnProfile
          ? null
          : [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: const Color(0xFF1E2C47),
                onSelected: (value) {
                  if (value == 'report') _showReportSheet(context);
                  if (value == 'block') _showBlockDialog(context);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(children: [
                      Icon(Icons.flag_outlined, size: 18, color: Colors.white70),
                      SizedBox(width: 10),
                      Text('Nutzer melden',
                          style: TextStyle(color: Colors.white)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(children: [
                      Icon(Icons.block, size: 18, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text('Nutzer blockieren',
                          style: TextStyle(color: Colors.redAccent)),
                    ]),
                  ),
                ],
              ),
            ],
    );

    if (isBlocked) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block,
                      size: 52, color: Colors.white.withValues(alpha: 0.35)),
                  const SizedBox(height: 20),
                  Text(
                    'Profil nicht verfügbar',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Du hast diesen Nutzer blockiert.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
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
                        _CarCard(
                          car: _car!,
                          hasLicensePlate: _car!.hasLicensePlate,
                          fahrtId: widget.fahrtId,
                        ),
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

    showAppSheet<void>(
      context,
      (ctx) => AppSheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetHeader(
              icon: Icons.verified_user_outlined,
              iconColor: const Color(0xFF4A80F0),
              title: 'Verifikationen',
            ),
            const SizedBox(height: 14),
            if (verified.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'Noch keine Verifikationen vorhanden.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13.5),
                ),
              )
            else
              ...verified.map((label) => Padding(
                    padding: const EdgeInsets.only(left: 48, bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: Color(0xFF4A80F0)),
                        const SizedBox(width: 8),
                        Text(label,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 14)),
                      ],
                    ),
                  )),
            const SizedBox(height: 20),
            AppSheetGhostButton(
                label: 'Schließen', onTap: () => Navigator.pop(ctx)),
          ],
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

class _PlateResult {
  final String? plate;
  final DateTime? releasedAt;
  final bool expired;
  const _PlateResult({this.plate, this.releasedAt, this.expired = false});
}

class _CarCard extends StatefulWidget {
  final CarInfo car;
  final bool hasLicensePlate;
  final String? fahrtId;

  const _CarCard({
    required this.car,
    required this.hasLicensePlate,
    this.fahrtId,
  });

  @override
  State<_CarCard> createState() => _CarCardState();
}

class _CarCardState extends State<_CarCard> {
  _PlateResult? _plateResult;
  bool _plateLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.fahrtId != null) {
      _plateLoading = true;
      _loadPlate();
    }
  }

  Future<void> _loadPlate() async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getLicensePlate')
          .call({'fahrtId': widget.fahrtId});
      final data = result.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _plateResult = _PlateResult(
          plate: data['plate'] as String?,
          releasedAt: data['releasedAt'] != null
              ? DateTime.tryParse(data['releasedAt'] as String)
              : null,
          expired: data['expired'] as bool? ?? false,
        );
        _plateLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _plateLoading = false);
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}. '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} Uhr';
  }

  void _showInfoSheet(BuildContext context) {
    final hasPlate = widget.car.hasLicensePlate;
    final result = _plateResult;
    final revealedPlate =
        (result?.plate != null && result!.plate!.isNotEmpty) ? result.plate : null;
    final locked = result?.releasedAt != null;

    late final IconData icon;
    late final Color iconColor;
    late final String title;
    late final String body;

    if (revealedPlate != null) {
      icon = Icons.check_circle_rounded;
      iconColor = const Color(0xFF4CAF50);
      title = 'Kennzeichen';
      body = 'Das Kennzeichen des Fahrers wurde freigegeben. '
          'Prüfe das Fahrzeug vor dem Einsteigen.';
    } else if (locked) {
      icon = Icons.lock_clock_outlined;
      iconColor = const Color(0xFFF5A04A);
      title = 'Noch gesperrt';
      body = 'Wird am ${_formatDate(result!.releasedAt!)} freigegeben — '
          '24 Stunden vor der Abfahrt.';
    } else if (hasPlate) {
      icon = Icons.check_circle_rounded;
      iconColor = const Color(0xFF4CAF50);
      title = 'Kennzeichen hinterlegt';
      body = 'Der Fahrer hat sein Kennzeichen hinterlegt. '
          'Du kannst es 24 Stunden vor der Fahrt auf deiner Mitfahrt-Seite einsehen '
          'und das Fahrzeug vor dem Einsteigen prüfen.';
    } else {
      icon = Icons.credit_card_off_outlined;
      iconColor = Colors.white38;
      title = 'Kein Kennzeichen';
      body = 'Dieser Fahrer hat noch kein Kennzeichen hinterlegt.';
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E1B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (revealedPlate != null) ...[
              const SizedBox(height: 4),
              _LicensePlateIndicator(hasPlate: true, revealedPlate: revealedPlate),
              const SizedBox(height: 8),
            ],
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Schließen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseCarColor(widget.car.color);
    final carName =
        [widget.car.make, widget.car.model].where((s) => s.isNotEmpty).join(' ');

    final result = _plateResult;
    final revealedPlate =
        (result?.plate != null && result!.plate!.isNotEmpty) ? result.plate : null;
    final locked = result?.releasedAt != null;
    final showGreen = widget.hasLicensePlate && revealedPlate == null;

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
        GestureDetector(
          onTap: () => _showInfoSheet(context),
          child: AppCard(
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
                      Icons.time_to_leave_rounded,
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
                          if (widget.car.color != null) ...[
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white38, width: 0.5),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.car.color!,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 13),
                            ),
                          ],
                          if (widget.car.color != null && widget.car.seats != null)
                            const Text(
                              ' · ',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13),
                            ),
                          if (widget.car.seats != null)
                            Text(
                              '${widget.car.seats} Plätze',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 13),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_plateLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Colors.white38),
                        )
                      else ...[
                        _LicensePlateIndicator(
                          hasPlate: widget.hasLicensePlate,
                          revealedPlate: revealedPlate,
                          highlighted: showGreen,
                        ),
                        if (locked) ...[
                          const SizedBox(height: 5),
                          _PlaceLockBadge(
                              label:
                                  'Ab ${_formatDate(result!.releasedAt!)}'),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.info_outline,
                  color: showGreen
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.6)
                      : Colors.white24,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Kleine Badge "ab ..." wenn Kennzeichen noch gesperrt ist
class _PlaceLockBadge extends StatelessWidget {
  final String label;
  const _PlaceLockBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_clock_outlined, size: 10, color: Colors.white38),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// Stilisierte Kennzeichen-Plakette
class _LicensePlateIndicator extends StatelessWidget {
  final bool hasPlate;
  final String? revealedPlate;
  final bool highlighted;

  const _LicensePlateIndicator({
    required this.hasPlate,
    this.revealedPlate,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool revealed = revealedPlate != null && revealedPlate!.isNotEmpty;
    final Color borderColor = revealed
        ? const Color(0xFF4CAF50).withValues(alpha: 0.7)
        : highlighted
            ? const Color(0xFF4CAF50).withValues(alpha: 0.45)
            : hasPlate
                ? Colors.white24
                : Colors.white12;
    final Color bgColor = revealed
        ? Colors.green.withValues(alpha: 0.10)
        : highlighted
            ? Colors.green.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: hasPlate ? 0.06 : 0.02);

    return Container(
      height: 22,
      constraints: const BoxConstraints(maxWidth: 140),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            decoration: BoxDecoration(
              color: (hasPlate || revealed)
                  ? const Color(0xFF003399)
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(3)),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            revealed ? revealedPlate! : (hasPlate ? 'AT ••–•••••' : 'AT  –  –  –'),
            style: TextStyle(
              color: revealed
                  ? Colors.white
                  : hasPlate
                      ? Colors.white60
                      : Colors.white24,
              fontSize: 11,
              fontWeight: revealed ? FontWeight.w700 : FontWeight.normal,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
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
  final String fahrtId;
  final VoidCallback onSubmitted;

  const _ReviewBottomSheet({
    required this.reviewedId,
    required this.reviewedName,
    required this.fahrtId,
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
      await FirebaseFunctions.instance.httpsCallable('submitReview').call({
        'reviewedId': widget.reviewedId,
        'fahrtId': widget.fahrtId,
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
