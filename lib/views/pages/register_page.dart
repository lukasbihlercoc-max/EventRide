// register_page.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // Für ImageFilter.blur
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/utils/async_guard.dart';
import 'package:my_app/views/pages/email_verification_page.dart';
import 'package:my_app/config/legal_texts.dart';
import 'package:my_app/views/pages/legal_page.dart';
import 'package:my_app/views/pages/login_page.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  InputDecoration _fieldDecoration({
    required String label,
    Widget? prefix,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: prefix,
        suffixIcon: suffix,
        border: _border(Colors.white70),
        enabledBorder: _border(Colors.white70),
        focusedBorder: _border(Colors.blueAccent, width: 2),
      );

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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Registrieren",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Erstelle dein sicheres Profil",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 30),

                  // Name Felder
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          decoration: _fieldDecoration(label: "Vorname"),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bitte Vorname eingeben';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          decoration: _fieldDecoration(label: "Nachname"),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bitte Nachname eingeben';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // E-Mail Feld
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: _fieldDecoration(
                      label: "E-Mail",
                      prefix: const Icon(Icons.email, color: Colors.white70),
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
                    decoration: _fieldDecoration(
                      label: "Passwort",
                      prefix: const Icon(Icons.lock, color: Colors.white70),
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte Passwort eingeben';
                      }
                      if (value.length < 8) {
                        return 'Mindestens 8 Zeichen';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'Mindestens ein Großbuchstabe erforderlich';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Mindestens eine Zahl erforderlich';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Passwort bestätigen Feld
                  TextFormField(
                    controller: _confirmPasswordController,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: _fieldDecoration(
                      label: "Passwort bestätigen",
                      prefix: const Icon(Icons.lock_outline, color: Colors.white70),
                      suffix: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    obscureText: _obscureConfirm,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte Passwort bestätigen';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwörter stimmen nicht überein';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // AGB Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                        fillColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.blueAccent;
                            }
                            return Colors.white30;
                          },
                        ),
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            children: [
                              const TextSpan(text: 'Ich akzeptiere die '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    AppRoute(
                                      builder: (_) => const LegalPage(
                                        title: 'AGB',
                                        content: kAgbText,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'AGB',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ' und die '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    AppRoute(
                                      builder: (_) => const LegalPage(
                                        title: 'Datenschutzerklärung',
                                        content: kDatenschutzText,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Datenschutzerklärung',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Registrieren Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading || !_acceptTerms ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _acceptTerms ? Colors.blueAccent : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Konto erstellen", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login-Link
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        AppRoute(builder: (_) => const LoginPage()),
                      ),
                      child: RichText(
                        text: const TextSpan(
                          text: "Bereits registriert? ",
                          style: TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: "Anmelden",
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
      ],
    );
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = context.read<IAuthRepository>();
      final email = _emailController.text.trim();
      await guarded(auth.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: email,
        password: _passwordController.text,
      ));
      await guarded(auth.sendEmailVerification());
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          AppRoute(
            builder: (_) => EmailVerificationPage(email: email),
          ),
          (route) => route.isFirst,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: _authError(e.code),
        accentColor: Colors.redAccent,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Registrierung fehlgeschlagen',
        accentColor: Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'E-Mail bereits registriert';
      case 'weak-password':
        return 'Passwort zu schwach (mind. 8 Zeichen, Großbuchstabe und Zahl)';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse';
      case 'too-many-requests':
        return 'Zu viele Versuche – bitte später erneut versuchen';
      case 'user-disabled':
        return 'Dieses Konto wurde deaktiviert';
      default:
        return 'Registrierung fehlgeschlagen';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
