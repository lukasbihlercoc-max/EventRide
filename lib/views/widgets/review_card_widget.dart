import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/data/review.dart';
import 'package:my_app/views/widgets/app_card.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/trust_shields_widget.dart';
import 'package:my_app/views/widgets/user_avatar_widget.dart';

String reviewRelativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays <= 0) return 'Heute';
  if (diff.inDays == 1) return 'vor 1 Tag';
  if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
  if (diff.inDays < 30) {
    final w = (diff.inDays / 7).round().clamp(1, 4);
    return 'vor $w ${w == 1 ? 'Woche' : 'Wochen'}';
  }
  if (diff.inDays < 365) {
    final m = (diff.inDays / 30).round().clamp(1, 11);
    return 'vor $m ${m == 1 ? 'Monat' : 'Monaten'}';
  }
  final y = (diff.inDays / 365).round();
  return 'vor $y ${y == 1 ? 'Jahr' : 'Jahren'}';
}

class ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback? onReport;
  final VoidCallback? onReviewerTap;
  final VoidCallback? onCardTap;

  /// true = voller Text ohne Kürzung (z.B. auf der eigenen Listen-Seite,
  /// wo der Nutzer bereits aktiv hingetippt hat, um alles zu lesen).
  final bool expanded;

  const ReviewCard({
    super.key,
    required this.review,
    this.onReport,
    this.onReviewerTap,
    this.onCardTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onReviewerTap,
                  child: UserAvatarWidget(
                    name: review.reviewerName,
                    photoUrl: review.reviewerPhotoUrl,
                    radius: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onReviewerTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                review.reviewerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            TrustShieldsByUserId(userId: review.reviewerId, size: 12),
                          ],
                        ),
                        Text(
                          reviewRelativeTime(review.createdAt),
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: List.generate(5, (i) {
                    final filled = i < review.rating;
                    return Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 13,
                      color: filled ? Colors.amber : Colors.white24,
                    );
                  }),
                ),
                if (onReport != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onReport,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Icon(Icons.more_horiz, size: 16, color: Colors.white24),
                    ),
                  ),
                ],
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.comment,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.4),
                maxLines: expanded ? null : 3,
                overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

void showReviewReportSheet(BuildContext context, Review review) {
  final reporterId = FirebaseAuth.instance.currentUser?.uid;
  if (reporterId == null) return;
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1F2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ReviewReportSheet(review: review, reporterId: reporterId),
  );
}

class ReviewReportSheet extends StatefulWidget {
  final Review review;
  final String reporterId;

  const ReviewReportSheet({
    super.key,
    required this.review,
    required this.reporterId,
  });

  @override
  State<ReviewReportSheet> createState() => _ReviewReportSheetState();
}

class _ReviewReportSheetState extends State<ReviewReportSheet> {
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
        AppSnackbar.show(context, message: 'Gemeldet. Wir prüfen die Bewertung.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        AppSnackbar.show(context,
            message: 'Fehler beim Melden. Bitte erneut versuchen.');
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
