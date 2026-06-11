// admin_user_reports_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/views/pages/public_profile_page.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:provider/provider.dart';

class AdminUserReportsPage extends StatelessWidget {
  const AdminUserReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<IAuthRepository>();
    if (!auth.isAdmin) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1F2E),
        body: Center(
          child: Text('Kein Zugriff', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Nutzer-Meldungen',
              style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_reports')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Text('Fehler: ${snap.error}',
                    style: const TextStyle(color: Colors.white54)),
              );
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Text('Keine Meldungen',
                    style: TextStyle(color: Colors.white54, fontSize: 16)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12),
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                return _UserReportTile(data: data);
              },
            );
          },
        ),
      ),
    );
  }
}

class _UserReportTile extends StatefulWidget {
  final Map<String, dynamic> data;
  const _UserReportTile({required this.data});

  @override
  State<_UserReportTile> createState() => _UserReportTileState();
}

class _UserReportTileState extends State<_UserReportTile> {
  late final Future<(String, String)> _namesFuture;

  @override
  void initState() {
    super.initState();
    _namesFuture = _loadNames();
  }

  Future<String> _fetchName(String uid) async {
    if (uid.isEmpty) return 'Unbekannt';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) return 'Nutzer ${uid.substring(0, 6)}';
      final d = doc.data()!;
      final first = (d['firstName'] as String? ?? '').trim();
      final last = (d['lastName'] as String? ?? '').trim();
      final name = '$first $last'.trim();
      return name.isNotEmpty ? name : 'Nutzer ${uid.substring(0, 6)}';
    } catch (_) {
      return 'Nutzer ${uid.substring(0, 6)}';
    }
  }

  Future<(String, String)> _loadNames() async {
    try {
      final reporterUid = widget.data['reporterUid'] as String? ?? '';
      final reportedUid = widget.data['reportedUid'] as String? ?? '';
      final results = await Future.wait(
        [_fetchName(reporterUid), _fetchName(reportedUid)],
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => ['?', '?'],
      );
      return (results[0], results[1]);
    } catch (_) {
      return ('?', '?');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = widget.data['reason'] as String? ?? '';
    final ts = widget.data['createdAt'] as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('dd.MM.yy HH:mm').format(ts.toDate().toLocal())
        : '';
    final reportedUid = widget.data['reportedUid'] as String? ?? '';

    return FutureBuilder<(String, String)>(
      future: _namesFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.white10,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white38),
              ),
            ),
            title: Text('Lädt...',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
          );
        }
        final reporterName = snap.data?.$1 ?? '?';
        final reportedName = snap.data?.$2 ?? '?';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: Colors.redAccent.withValues(alpha: 0.18),
            child: const Icon(Icons.flag, color: Colors.redAccent, size: 20),
          ),
          title: Text(
            '$reporterName meldet $reportedName',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grund: $reason',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (dateStr.isNotEmpty)
                Text(dateStr,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
            ],
          ),
          isThreeLine: true,
          trailing: reportedUid.isNotEmpty
              ? TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    AppRoute(
                        builder: (_) => PublicProfilePage(
                              userId: reportedUid,
                              name: reportedName,
                            )),
                  ),
                  child: const Text('Profil',
                      style: TextStyle(color: Color(0xFFF5A04A))),
                )
              : null,
        );
      },
    );
  }
}
