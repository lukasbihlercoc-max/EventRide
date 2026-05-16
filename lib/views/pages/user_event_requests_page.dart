import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/data/event_request.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/views/widgets/app_card.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:provider/provider.dart';

class UserEventRequestsPage extends StatelessWidget {
  const UserEventRequestsPage({super.key});

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
            'Meine Einreichungen',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: StreamBuilder<List<EventRequest>>(
          stream: context.read<IAuthRepository>().myEventRequests,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              );
            }

            final requests = snapshot.data ?? [];
            if (requests.isEmpty) {
              return const Center(
                child: Text(
                  'Noch keine Einreichungen.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _RequestCard(request: requests[index]),
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final EventRequest request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isFlyer = request.submissionType == 'flyer';
    final title = isFlyer
        ? 'Flyer-Upload'
        : (request.eventName ?? 'Unbenanntes Event');
    final dateStr =
        DateFormat('dd.MM.yyyy').format(request.submittedAt);

    final (statusLabel, statusColor) = switch (request.status) {
      'approved' => ('Angenommen', const Color(0xFF43A047)),
      'discarded' => ('Abgelehnt', const Color(0xFFE53935)),
      _ => ('Ausstehend', const Color(0xFFF5A04A)),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Eingereicht am $dateStr',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (request.standort != null && !isFlyer) ...[
            const SizedBox(height: 4),
            Text(
              request.standort!,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          if (request.status == 'discarded' &&
              request.rejectReason != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFE53935).withValues(alpha: 0.3)),
              ),
              child: Text(
                request.rejectReason!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
