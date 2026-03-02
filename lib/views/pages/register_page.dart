// register_page.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // Für ImageFilter.blur
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppBackground(child: Container()),
        Container(color: Colors.black.withOpacity(0.4)),
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
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Registrieren",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Erstelle dein sicheres Profil",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 30),

                  // Name Felder
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          style: TextStyle(color: Colors.white, fontSize: 18),
                          decoration: InputDecoration(
                            labelText: "Vorname",
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bitte Vorname eingeben';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          style: TextStyle(color: Colors.white, fontSize: 18),
                          decoration: InputDecoration(
                            labelText: "Nachname",
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                  SizedBox(height: 20),

                  // E-Mail Feld
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: "E-Mail",
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.email, color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                  SizedBox(height: 20),

                  // Telefonnummer Feld
                  TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: "Telefonnummer",
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.phone, color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte Telefonnummer eingeben';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  // Passwort Feld
                  TextFormField(
                    controller: _passwordController,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: "Passwort",
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.lock, color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte Passwort eingeben';
                      }
                      if (value.length < 6) {
                        return 'Mindestens 6 Zeichen';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  // Passwort bestätigen Feld
                  TextFormField(
                    controller: _confirmPasswordController,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: "Passwort bestätigen",
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
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
                  SizedBox(height: 20),

                  // AGB Checkbox
                  Row(
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
                        child: GestureDetector(
                          onTap: () {
                            // AGB anzeigen
                          },
                          child: Text(
                            "Ich akzeptiere die AGB und Datenschutzbestimmungen",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),

                  // Registrieren Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading || !_acceptTerms ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _acceptTerms ? Colors.blueAccent : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text("Konto erstellen", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Login-Link
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
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
      await auth.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      // Zurück zur Root-Route; AuthGate's StreamBuilder zeigt WidgetTree
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authError(e.code))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrierung fehlgeschlagen')),
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
        return 'Passwort zu schwach (mind. 6 Zeichen)';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse';
      default:
        return 'Registrierung fehlgeschlagen';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
