// settings_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/event_request.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/license_request.dart';
import 'package:my_app/data/notification_service.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/views/pages/admin_event_requests_page.dart';
import 'package:my_app/views/pages/admin_license_page.dart';
import 'package:my_app/config/legal_texts.dart';
import 'package:my_app/views/pages/legal_page.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  final String title;
  const SettingsPage({super.key, required this.title});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  final _townController = TextEditingController();
  bool _isSaving = false;
  bool _isEditingTown = false;
  String _originalTown = '';
  late final Stream<AppUser?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = context.read<IAuthRepository>().authStateChanges;
    _loadTown();
  }

  Future<void> _loadTown() async {
    final town = await context.read<IAuthRepository>().getHomeTown();
    if (!mounted) return;
    setState(() {
      _townController.text = town ?? '';
      _originalTown = town ?? '';
    });
  }

  Future<void> _saveTown() async {
    setState(() => _isSaving = true);
    await context
        .read<IAuthRepository>()
        .setHomeTown(_townController.text.trim());
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditingTown = false;
      _originalTown = _townController.text;
    });
    AppSnackbar.show(context, message: "Wohnort gespeichert");
  }

  void _cancelEditTown() {
    setState(() {
      _townController.text = _originalTown;
      _isEditingTown = false;
    });
  }

  @override
  void dispose() {
    _townController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppBackground(child: Container()),
        Container(color: Colors.black.withValues(alpha: 0.4)),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(color: Colors.transparent),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(widget.title),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: StreamBuilder<AppUser?>(
            stream: _authStream,
            builder: (context, snapshot) {
              final user = snapshot.data;
              final auth = context.read<IAuthRepository>();
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    // ── Admin (nur für Admins) ─────────────────────────────
                    if (user != null && auth.isAdmin) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Admin",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      StreamBuilder<List<LicenseRequest>>(
                        stream: auth.pendingLicenseRequests,
                        builder: (context, snap) {
                          final count = snap.data?.length ?? 0;
                          return ListTile(
                            leading: const Icon(
                              Icons.credit_card_outlined,
                              color: Color(0xFFE07B00),
                            ),
                            title: const Text(
                              "Führerschein-Prüfungen",
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: count > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE07B00),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.chevron_right_rounded,
                                    color: Colors.white38),
                            onTap: () => Navigator.push(
                              context,
                              AppRoute(
                                  builder: (_) => const AdminLicensePage()),
                            ),
                          );
                        },
                      ),
                      StreamBuilder<List<EventRequest>>(
                        stream: auth.pendingEventRequests,
                        builder: (context, snap) {
                          final count = snap.data?.length ?? 0;
                          return ListTile(
                            leading: const Icon(
                              Icons.event_note_outlined,
                              color: Color(0xFF5DA9FF),
                            ),
                            title: const Text(
                              'Event-Anfragen',
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: count > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5DA9FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.chevron_right_rounded,
                                    color: Colors.white38),
                            onTap: () => Navigator.push(
                              context,
                              AppRoute(
                                  builder: (_) =>
                                      const AdminEventRequestsPage()),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Colors.white30),
                    ],

                    // ── Meine Daten (nur wenn eingeloggt) ─────────────────
                    if (user != null) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Meine Daten",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Wohnort
                      ListTile(
                        leading: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.blueAccent,
                        ),
                        title: const Text(
                          "Wohnort",
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: _isEditingTown
                            ? TextField(
                                controller: _townController,
                                autofocus: true,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15),
                                decoration: const InputDecoration(
                                  hintText: "z. B. Villach",
                                  hintStyle: TextStyle(color: Colors.white30),
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                              )
                            : Text(
                                _townController.text.isEmpty
                                    ? "Hinzufügen"
                                    : _townController.text,
                                style: TextStyle(
                                  color: _townController.text.isEmpty
                                      ? Colors.white38
                                      : Colors.white70,
                                ),
                              ),
                        trailing: _isEditingTown
                            ? _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white54),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded,
                                            color: Colors.white38),
                                        onPressed: _cancelEditTown,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check_rounded,
                                            color: Colors.greenAccent),
                                        onPressed: _saveTown,
                                      ),
                                    ],
                                  )
                            : IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: Colors.white54, size: 20),
                                onPressed: () => setState(() {
                                  _originalTown = _townController.text;
                                  _isEditingTown = true;
                                }),
                              ),
                      ),
                      const Divider(color: Colors.white30),
                      // E-Mail
                      ListTile(
                        leading: const Icon(
                          Icons.email_outlined,
                          color: Colors.blueAccent,
                        ),
                        title: const Text(
                          "E-Mail",
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          user.email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: const Icon(Icons.lock_outline_rounded,
                            color: Colors.white24, size: 18),
                      ),
                      const Divider(color: Colors.white30),
                    ],

                    // ── Rechtliches ────────────────────────────────────────
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Rechtliches",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.security, color: Colors.red),
                      title: const Text("Datenschutz",
                          style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white38),
                      onTap: () => Navigator.push(
                        context,
                        AppRoute(
                          builder: (_) => LegalPage(
                            title: 'Datenschutzerklärung',
                            content: kDatenschutzText,
                          ),
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white30),
                    ListTile(
                      leading: const Icon(Icons.description,
                          color: Colors.grey),
                      title: const Text("AGB",
                          style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white38),
                      onTap: () => Navigator.push(
                        context,
                        AppRoute(
                          builder: (_) => LegalPage(
                            title: 'AGB',
                            content: kAgbText,
                          ),
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white30),

                    // ── Account ────────────────────────────────────────────
                    if (user != null) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Account",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.logout, color: Colors.amber),
                        title: const Text("Abmelden",
                            style: TextStyle(color: Colors.white)),
                        onTap: () => _showLogoutDialog(context),
                      ),
                      const Divider(color: Colors.white30),
                      ListTile(
                        leading: const Icon(Icons.delete,
                            color: Colors.redAccent),
                        title: const Text("Account löschen",
                            style: TextStyle(color: Colors.white)),
                        onTap: () => _showDeleteAccountDialog(context),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final authRepository = context.read<IAuthRepository>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text("Abmelden", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Möchtest du dich wirklich abmelden?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Abbrechen",
                style: TextStyle(color: Colors.blueAccent)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final userId = authRepository.currentUser?.userId ?? '';
              if (userId.isNotEmpty) {
                await context.read<NotificationService>().removeToken(userId);
              }
              await authRepository.signOut();
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            child: const Text("Abmelden",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Account löschen",
              style: TextStyle(color: Colors.white)),
          content: loading
              ? const SizedBox(
                  height: 60,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  ),
                )
              : const Text(
                  "Diese Aktion kann nicht rückgängig gemacht werden. Alle deine Daten, Fahrten und Nachrichten werden dauerhaft gelöscht.",
                  style: TextStyle(color: Colors.white70),
                ),
          actions: loading
              ? []
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("Abbrechen",
                        style: TextStyle(color: Colors.blueAccent)),
                  ),
                  TextButton(
                    onPressed: () async {
                      setDialogState(() => loading = true);
                      try {
                        final auth = context.read<IAuthRepository>();
                        final userId = auth.currentUser?.userId ?? '';
                        if (userId.isNotEmpty) {
                          await context
                              .read<NotificationService>()
                              .removeToken(userId);
                        }
                        await auth.deleteAccount();
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          Navigator.popUntil(
                              context, (route) => route.isFirst);
                        }
                      } on FirebaseAuthException catch (e) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => loading = false);
                        if (e.code == 'requires-recent-login') {
                          Navigator.pop(dialogContext);
                          if (context.mounted) {
                            _showReauthAndDeleteDialog(context);
                          }
                        } else {
                          if (context.mounted) {
                            AppSnackbar.show(context,
                                message: 'Account konnte nicht gelöscht werden.');
                          }
                        }
                      } catch (_) {
                        if (dialogContext.mounted) {
                          setDialogState(() => loading = false);
                        }
                        if (context.mounted) {
                          AppSnackbar.show(context,
                              message: 'Account konnte nicht gelöscht werden.');
                        }
                      }
                    },
                    child: const Text("Endgültig löschen",
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
        ),
      ),
    );
  }

  Future<void> _showReauthAndDeleteDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    bool loading = false;
    bool obscure = true;
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Passwort bestätigen",
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Bitte gib dein Passwort ein, um den Account zu löschen.",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  labelStyle: const TextStyle(color: Colors.white70),
                  errorText: errorText,
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: Colors.white54),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscure = !obscure),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Colors.redAccent, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: loading
              ? [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.redAccent),
                    ),
                  )
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("Abbrechen",
                        style: TextStyle(color: Colors.blueAccent)),
                  ),
                  TextButton(
                    onPressed: () async {
                      final password = passwordController.text;
                      if (password.isEmpty) {
                        setDialogState(
                            () => errorText = 'Bitte Passwort eingeben');
                        return;
                      }
                      setDialogState(() {
                        loading = true;
                        errorText = null;
                      });
                      try {
                        final auth = context.read<IAuthRepository>();
                        await auth.reauthenticate(password);
                        await auth.deleteAccount();
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          Navigator.popUntil(
                              context, (route) => route.isFirst);
                        }
                      } on FirebaseAuthException catch (e) {
                        if (!dialogContext.mounted) return;
                        final msg = e.code == 'wrong-password' ||
                                e.code == 'invalid-credential'
                            ? 'Falsches Passwort'
                            : 'Fehler beim Löschen';
                        setDialogState(() {
                          loading = false;
                          errorText = msg;
                        });
                      } catch (_) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() {
                          loading = false;
                          errorText = 'Fehler beim Löschen';
                        });
                      }
                    },
                    child: const Text("Löschen",
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
        ),
      ),
    );
    passwordController.dispose();
  }
}

