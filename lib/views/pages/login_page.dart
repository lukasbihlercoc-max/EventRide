// login_page.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // Für ImageFilter.blur
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/views/widgets/app_bottom_sheet.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/pages/register_page.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

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
            automaticallyImplyLeading: Navigator.canPop(context),
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Anmelden",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Willkommen zurück",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // E-Mail Feld
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: "E-Mail",
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.email, color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte E-Mail eingeben';
                      }
                      if (!value.contains('@')) {
                        return 'Ungültige E-Mail-Adresse';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Passwort Feld
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: "Passwort",
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte Passwort eingeben';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _showResetPasswordDialog,
                      child: const Text("Passwort vergessen?",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 16,
                          )),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Anmelden", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Registrierungs-Link
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        AppRoute(builder: (_) => const RegisterPage()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: "Noch kein Konto? ",
                          style: const TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: "Registrieren",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ],
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = context.read<IAuthRepository>();
      await auth.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint('[Login] FirebaseAuthException code=${e.code} message=${e.message}');
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: _authError(e.code),
        accentColor: Colors.redAccent,
      );
    } catch (e, st) {
      debugPrint('[Login] Unerwarteter Fehler: ${e.runtimeType}: $e');
      debugPrint('[Login] Stacktrace: $st');
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Anmeldung fehlgeschlagen',
        accentColor: Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    bool loading = false;

    await showAppSheet<void>(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: AppSheetShell(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSheetHeader(
                  icon: Icons.lock_reset,
                  iconColor: const Color(0xFFF5A04A),
                  title: 'Passwort zurücksetzen',
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Text(
                    'Gib deine E-Mail-Adresse ein. Wir senden dir einen Link zum Zurücksetzen.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13.5,
                        height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: sheetInputDecoration(
                    label: 'E-Mail',
                    prefixIcon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 22),
                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          color: Color(0xFFF5A04A), strokeWidth: 2),
                    ),
                  )
                else ...[
                  AppSheetPrimaryButton(
                    label: 'Senden',
                    onTap: () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) return;
                      setSheetState(() => loading = true);
                      try {
                        await context
                            .read<IAuthRepository>()
                            .resetPassword(email);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;
                        AppSnackbar.show(context,
                            message: 'E-Mail zum Zurücksetzen wurde gesendet');
                      } on FirebaseFunctionsException catch (e) {
                        setSheetState(() => loading = false);
                        if (!mounted) return;
                        AppSnackbar.show(context,
                            message: _resetError(e.code),
                            accentColor: Colors.redAccent);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  AppSheetGhostButton(
                    label: 'Abbrechen',
                    onTap: () => Navigator.pop(ctx),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    emailController.dispose();
  }

  // Bewusst ohne "Kein Konto gefunden"-Fall: die Cloud Function gibt aus
  // Enumeration-Schutz-Gründen immer Erfolg zurück, egal ob die E-Mail
  // existiert. Diese Fehler treten nur bei echten Netzwerk-/Server-Problemen auf.
  String _resetError(String code) {
    switch (code) {
      case 'invalid-argument':
        return 'Ungültige E-Mail-Adresse';
      default:
        return 'Fehler beim Senden der E-Mail';
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'E-Mail nicht gefunden';
      case 'wrong-password':
        return 'Falsches Passwort';
      case 'invalid-credential':
        return 'E-Mail oder Passwort falsch';
      case 'too-many-requests':
        return 'Zu viele Versuche – bitte später erneut versuchen';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse';
      case 'user-disabled':
        return 'Dieses Konto wurde deaktiviert';
      default:
        return 'Anmeldung fehlgeschlagen';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
