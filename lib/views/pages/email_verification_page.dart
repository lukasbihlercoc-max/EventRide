import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/utils/async_guard.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/sizehelper_widget.dart';
import 'package:provider/provider.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  const EmailVerificationPage({super.key, required this.email});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isResending = false;
  bool _resentSuccess = false;
  late String _currentEmail;
  final _scrollController = ScrollController();
  Timer? _autoCheckTimer;
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.email;
    WidgetsBinding.instance.addObserver(this);
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final verified =
            await context.read<IAuthRepository>().reloadAndCheckEmailVerified();
        if (!mounted) return;
        if (verified) {
          _autoCheckTimer?.cancel();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (_) {}
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<IAuthRepository>().reloadAndCheckEmailVerified().then((verified) {
        if (!mounted) return;
        if (verified) {
          _autoCheckTimer?.cancel();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dotController.dispose();
    _autoCheckTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isResending = true;
      _resentSuccess = false;
    });
    try {
      await guarded(context.read<IAuthRepository>().sendEmailVerification());
      if (mounted) setState(() => _resentSuccess = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: e.code == 'too-many-requests'
            ? 'Zu viele Versuche – bitte später erneut versuchen'
            : 'Fehler beim Senden der E-Mail',
        accentColor: Colors.redAccent,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Fehler beim Senden der E-Mail',
        accentColor: Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _signOut() async {
    await context.read<IAuthRepository>().signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _changeEmail(String newEmail, String password) async {
    try {
      await guarded(
          context.read<IAuthRepository>().changeEmail(newEmail, password));
      if (!mounted) return;

      Navigator.pop(context);

      setState(() {
        _currentEmail = newEmail;
        _resentSuccess = false;
      });

      AppSnackbar.show(
        context,
        message: 'Neue Bestätigungs-E-Mail wurde gesendet',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Falsches Passwort';
        case 'email-already-in-use':
          message = 'E-Mail wird bereits verwendet';
        case 'invalid-email':
          message = 'Ungültige E-Mail-Adresse';
        default:
          message = 'Fehler beim Ändern der E-Mail';
      }
      AppSnackbar.show(
        context,
        message: message,
        accentColor: Colors.redAccent,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Fehler beim Ändern der E-Mail',
        accentColor: Colors.redAccent,
      );
    }
  }

  Future<void> _showChangeEmailDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChangeEmailSheet(onSave: _changeEmail),
    );
  }

  Widget _buildWaitingIndicator() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _dotController,
          builder: (_, __) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final phase = (_dotController.value * 3 - i) % 3.0;
              final dy = phase < 1.0 ? -8.0 * math.sin(phase * math.pi) : 0.0;
              final alpha = phase < 1.0 ? 0.4 + 0.6 * math.sin(phase * math.pi) : 0.4;
              return Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: alpha),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Warte auf Bestätigung …',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
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
            leading: Navigator.canPop(context)
                ? const BackButton(color: Colors.white70)
                : null,
          ),
          body: SafeArea(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  SizedBox(height: SizeHelper.h(context, 0.06)),
                  const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                  SizedBox(height: SizeHelper.h(context, 0.025)),
                  const Text(
                    'E-Mail bestätigen',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: SizeHelper.h(context, 0.015)),
                  Text(
                    'Wir haben eine Bestätigungs-E-Mail an\n$_currentEmail\ngesendet.\n\nBitte klicke auf den Link in der E-Mail.',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: SizeHelper.h(context, 0.025)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline, color: Colors.orange, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tipp: Schau auch in deinem Spam-Ordner nach – die E-Mail landet manchmal dort.',
                            style: TextStyle(
                                color: Colors.orange, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeHelper.h(context, 0.04)),
                  _buildWaitingIndicator(),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isResending ? null : _resendEmail,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isResending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            )
                          : Text(
                              _resentSuccess
                                  ? 'E-Mail erneut gesendet'
                                  : 'E-Mail erneut senden',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  SizedBox(height: SizeHelper.h(context, 0.02)),
                  TextButton(
                    onPressed: _signOut,
                    child: const Text(
                      'Abmelden',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Falsche E-Mail eingegeben?',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  TextButton(
                    onPressed: _showChangeEmailDialog,
                    child: const Text(
                      'E-Mail ändern',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bottom Sheet als eigener StatefulWidget ──────────────────────────────────
// Controller-Lifecycle ist damit an den Widget-Lifecycle gebunden —
// kein try/finally nötig, kein "used after disposed".

class _ChangeEmailSheet extends StatefulWidget {
  final Future<void> Function(String email, String password) onSave;
  const _ChangeEmailSheet({required this.onSave});

  @override
  State<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<_ChangeEmailSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'E-Mail ändern',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Neue E-Mail',
              labelStyle: TextStyle(color: Colors.white60),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Passwort bestätigen',
              labelStyle: TextStyle(color: Colors.white60),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Speichern'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
