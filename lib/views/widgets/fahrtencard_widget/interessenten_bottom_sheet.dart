// lib/views/widgets/fahrtencard_widget/interessenten_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/fahrt_service.dart';
import 'package:my_app/data/interessenten_daten.dart';
import 'package:my_app/data/interessenten_service.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/trust_shields_widget.dart';
import 'package:my_app/views/widgets/user_avatar_widget.dart';
import 'package:my_app/views/pages/public_profile_page.dart';


void showInteressentenSheet(BuildContext context, FahrtDaten fahrt) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InteressentenSheet(fahrt: fahrt),
  );
}

// ---------------------------------------------------------------------------
// Sheet-Widget
// ---------------------------------------------------------------------------
class _InteressentenSheet extends StatefulWidget {
  const _InteressentenSheet({required this.fahrt});
  final FahrtDaten fahrt;

  @override
  State<_InteressentenSheet> createState() => _InteressentenSheetState();
}

class _InteressentenSheetState extends State<_InteressentenSheet> {
  /// UserIds die in dieser Session bereits eingeladen wurden
  final Set<String> _eingeladen = {};

  /// UserIds bei denen gerade eine Anfrage läuft
  final Set<String> _loading = {};

  @override
  Widget build(BuildContext context) {
    final interessenten = context
        .watch<InteressentenService>()
        .getForEvent(widget.fahrt.eventId);

    final alleAnfragen = context.watch<AnfrageService>().alleAnfragen;

    final liveFahrt = context
        .watch<FahrtService>()
        .alleFahrten
        .firstWhere((f) => f.id == widget.fahrt.id, orElse: () => widget.fahrt);
    final istVoll = liveFahrt.freiePlaetze <= 0;

    // Leute ausblenden, die bereits bei irgendeinem Fahrer dieses Events akzeptiert wurden
    final filtered = interessenten.where((i) {
      return !alleAnfragen.any((a) =>
          a.eventId == widget.fahrt.eventId &&
          a.requesterId == i.userId &&
          a.status == AnfrageStatus.akzeptiert);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A2744),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag-Handle ──
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline,
                        color: Colors.amber, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Interessenten · ${widget.fahrt.eventName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white12, height: 1),

              // ── Inhalt ──
              Expanded(
                child: filtered.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (_, i) {
                          final person = filtered[i];
                          final bereitsEingeladen =
                              _eingeladen.contains(person.userId) ||
                                  alleAnfragen.any((a) =>
                                      a.fahrtId == widget.fahrt.id &&
                                      a.requesterId == person.userId &&
                                      a.vonFahrer &&
                                      a.status == AnfrageStatus.offen);
                          return _InteressentTile(
                            interessent: person,
                            istEingeladen: bereitsEingeladen,
                            isLoading: _loading.contains(person.userId),
                            onEinladen: istVoll ? null : () => _einladen(person),
                            onBereitsEingeladen: () => AppSnackbar.show(
                              context,
                              message:
                                  '${person.userName} wurde bereits eingeladen.',
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sentiment_neutral, color: Colors.white24, size: 48),
          SizedBox(height: 12),
          Text(
            'Niemand wartet auf eine Mitfahrt',
            style: TextStyle(color: Colors.white38, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Future<void> _einladen(InteressentenDaten interessent) async {
    if (_eingeladen.contains(interessent.userId) ||
        _loading.contains(interessent.userId)) {
      return;
    }

    setState(() => _loading.add(interessent.userId));

    final currentUser = context.read<IAuthRepository>().currentUser;
    if (currentUser == null) {
      setState(() => _loading.remove(interessent.userId));
      return;
    }

    final anfrageService = context.read<AnfrageService>();

    await anfrageService.einladenVomFahrer(
      fahrt: widget.fahrt,
      interessent: interessent,
      fahrerName: currentUser.name,
    );

    if (!mounted) { return; }
    setState(() {
      _loading.remove(interessent.userId);
      _eingeladen.add(interessent.userId);
    });
  }
}

// ---------------------------------------------------------------------------
// Einzelner Eintrag
// ---------------------------------------------------------------------------
class _InteressentTile extends StatelessWidget {
  const _InteressentTile({
    required this.interessent,
    required this.istEingeladen,
    required this.onBereitsEingeladen,
    required this.isLoading,
    required this.onEinladen,
  });

  final InteressentenDaten interessent;
  final bool istEingeladen;
  final bool isLoading;
  final VoidCallback? onEinladen;
  final VoidCallback onBereitsEingeladen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Avatar
          UserAvatarWidget(
            name: interessent.userName,
            photoUrl: interessent.userPhotoUrl,
            radius: 20,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PublicProfilePage(
                  userId: interessent.userId,
                  name: interessent.userName,
                  photoUrl: interessent.userPhotoUrl,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + Bezirk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        interessent.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const TrustShields(filled: 1, size: 13),
                  ],
                ),
                if (interessent.bezirk != null &&
                    interessent.bezirk!.isNotEmpty)
                  Text(
                    interessent.bezirk!,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Button-Bereich
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.amber),
            )
          else if (istEingeladen)
            OutlinedButton(
              onPressed: onBereitsEingeladen,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Angefragt',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            )
          else
            ElevatedButton(
              onPressed: onEinladen,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Einladen', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }

}