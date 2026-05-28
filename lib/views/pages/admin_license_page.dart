// admin_license_page.dart
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/license_request.dart';
import 'package:my_app/views/widgets/app_bottom_sheet.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';

class AdminLicensePage extends StatelessWidget {
  const AdminLicensePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<IAuthRepository>();

    // Defense in depth: Seite zeigt nichts für Nicht-Admins
    if (!auth.isAdmin) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1F2E),
        body: Center(
          child: Text('Kein Zugriff',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Führerschein-Prüfungen',
              style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: StreamBuilder<List<LicenseRequest>>(
          stream: auth.pendingLicenseRequests,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Fehler: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent)),
              );
            }

            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white38, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text('Keine offenen Anfragen',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 15)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final req = requests[index];
                return _RequestCard(
                  request: req,
                  onTap: () => _showReviewSheet(context, req),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showReviewSheet(BuildContext context, LicenseRequest req) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReviewSheet(request: req),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REQUEST CARD
// ─────────────────────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final LicenseRequest request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final submitted = request.submittedAt;
    final dateStr =
        '${submitted.day.toString().padLeft(2, '0')}.${submitted.month.toString().padLeft(2, '0')}.${submitted.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF2A3044),
              backgroundImage: request.userPhotoUrl != null
                  ? NetworkImage(request.userPhotoUrl!)
                  : null,
              child: request.userPhotoUrl == null
                  ? Text(
                      request.userName.isNotEmpty
                          ? request.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.userName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Eingereicht am $dateStr',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Badge + Chevron
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE07B00),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Offen',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEW SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewSheet extends StatefulWidget {
  final LicenseRequest request;
  const _ReviewSheet({required this.request});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  Uint8List? _imageBytes;
  bool _loadingImage = true;
  String? _imageError;
  bool _actioning = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final ref =
          FirebaseStorage.instance.ref(widget.request.licensePath);
      final bytes = await ref.getData(5 * 1024 * 1024);
      if (mounted) setState(() => _imageBytes = bytes);
    } catch (e) {
      if (mounted) setState(() => _imageError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingImage = false);
    }
  }

  Future<void> _approve() async {
    setState(() => _actioning = true);
    try {
      await context
          .read<IAuthRepository>()
          .approveLicense(widget.request.uid);
      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.show(context, message: 'Führerschein angenommen.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: 'Fehler: $e');
      }
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  void _showRejectDialog() {
    showAppSheet<void>(
      context,
      (ctx) => _RejectDialog(
        onConfirm: (reason) async {
          Navigator.pop(ctx);
          setState(() => _actioning = true);
          try {
            await context
                .read<IAuthRepository>()
                .rejectLicense(widget.request.uid, reason);
            if (mounted) Navigator.pop(context);
          } catch (e) {
            if (mounted) AppSnackbar.show(context, message: 'Fehler: $e');
          } finally {
            if (mounted) setState(() => _actioning = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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

          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2A3044),
                backgroundImage: widget.request.userPhotoUrl != null
                    ? NetworkImage(widget.request.userPhotoUrl!)
                    : null,
                child: widget.request.userPhotoUrl == null
                    ? Text(
                        widget.request.userName.isNotEmpty
                            ? widget.request.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                widget.request.userName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bild
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                color: Colors.white.withValues(alpha: 0.05),
                child: _loadingImage
                    ? const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.white54),
                        ),
                      )
                    : _imageError != null
                        ? SizedBox(
                            height: 120,
                            child: Center(
                              child: Text(
                                'Bild konnte nicht geladen werden',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 13),
                              ),
                            ),
                          )
                        : Image.memory(
                            _imageBytes!,
                            fit: BoxFit.contain,
                          ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Buttons
          if (_actioning)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Ablehnen',
                    color: const Color(0xFFE63946),
                    onTap: _showRejectDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'Annehmen',
                    color: const Color(0xFF2D6A4F),
                    onTap: _approve,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REJECT DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _RejectDialog extends StatefulWidget {
  final void Function(String reason) onConfirm;
  const _RejectDialog({required this.onConfirm});

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  static const _suggestions = [
    'Bild unscharf',
    'Falsches Dokument',
    'Dokument abgelaufen',
  ];

  String? _selected;
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _selected == 'Anderes'
        ? _customCtrl.text.trim()
        : _selected ?? '';
    if (reason.isEmpty) return;
    widget.onConfirm(reason);
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _selected != null &&
        !(_selected == 'Anderes' && _customCtrl.text.trim().isEmpty);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: AppSheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetHeader(
              icon: Icons.block,
              iconColor: const Color(0xFFE63946),
              title: 'Ablehnungsgrund',
            ),
            const SizedBox(height: 16),
            ...[..._suggestions, 'Anderes'].map((s) => GestureDetector(
                  onTap: () => setState(() => _selected = s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selected == s
                                  ? const Color(0xFFF5A04A)
                                  : Colors.white.withValues(alpha: 0.30),
                              width: 2,
                            ),
                          ),
                          child: _selected == s
                              ? Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFF5A04A),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(s,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 14)),
                      ],
                    ),
                  ),
                )),
            if (_selected == 'Anderes') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: (_) => setState(() {}),
                decoration: sheetInputDecoration(label: 'Begründung eingeben'),
              ),
            ],
            const SizedBox(height: 22),
            canConfirm
                ? AppSheetDangerButton(label: 'Ablehnen', onTap: _confirm)
                : _DisabledButton(label: 'Ablehnen'),
            const SizedBox(height: 10),
            AppSheetGhostButton(
              label: 'Abbrechen',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _DisabledButton extends StatelessWidget {
  final String label;
  const _DisabledButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.30),
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
