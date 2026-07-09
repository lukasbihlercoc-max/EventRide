import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/data/review.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/utils/async_guard.dart';
import 'package:my_app/views/pages/public_profile_page.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/review_card_widget.dart';

class ReviewsListPage extends StatefulWidget {
  final String userId;
  final String userName;

  const ReviewsListPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ReviewsListPage> createState() => _ReviewsListPageState();
}

class _ReviewsListPageState extends State<ReviewsListPage> {
  List<Review>? _reviews;
  double? _ratingAvg;
  int _ratingCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = FirebaseFirestore.instance;
      final results = await guarded(Future.wait([
        db
            .collection('reviews')
            .where('reviewedId', isEqualTo: widget.userId)
            .limit(50)
            .get(),
        db.collection('users').doc(widget.userId).get(),
      ]));
      if (!mounted) return;

      final reviewSnap = results[0] as QuerySnapshot;
      final userDoc = results[1] as DocumentSnapshot;

      double? avg;
      int count = 0;
      if (userDoc.exists) {
        final d = userDoc.data()! as Map<String, dynamic>;
        avg = (d['ratingAvg'] as num?)?.toDouble();
        count = (d['ratingCount'] as num?)?.toInt() ?? 0;
      }

      final sorted = reviewSnap.docs.map(Review.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _reviews = sorted;
        _ratingAvg = avg;
        _ratingCount = count;
      });
    } catch (_) {
      if (mounted) setState(() => _reviews = []);
    }
  }

  void _showReportSheet(BuildContext context, Review review) {
    showReviewReportSheet(context, review);
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
          title: const Text(
            'Bewertungen',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600),
          ),
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_reviews == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white30));
    }
    if (_reviews!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border_rounded, size: 32, color: Colors.white30),
              SizedBox(height: 12),
              Text(
                'Noch keine Bewertungen',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Nach gemeinsamen Fahrten erscheinen Bewertungen hier.',
                style:
                    TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _reviews!.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildHeader();
        final review = _reviews![index - 1];
        final canReport =
            currentUid != null && currentUid != review.reviewerId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ReviewCard(
            review: review,
            onReport: canReport
                ? () => _showReportSheet(context, review)
                : null,
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
            expanded: true,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    if (_ratingAvg == null || _ratingCount == 0) {
      return const SizedBox(height: 8);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        children: [
          Text(
            _ratingAvg!.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: List.generate(5, (i) {
              final filled = i < _ratingAvg!.round();
              return Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 16,
                color: filled ? Colors.amber : Colors.white24,
              );
            }),
          ),
          const SizedBox(width: 10),
          Text(
            '$_ratingCount ${_ratingCount == 1 ? 'Bewertung' : 'Bewertungen'}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

