// profile_page.dart
import 'package:flutter/material.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/views/pages/login_page.dart';
import 'package:my_app/views/pages/register_page.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        
        body: StreamBuilder<AppUser?>(
          stream: context.read<IAuthRepository>().authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data != null) {
              return const LoggedInProfileView();
            }
            return _buildLoginOptions(context);
          },
        ),
      ),
    );
  }

  Widget _buildLoginOptions(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: const Text(
              "Mitfahrgelegenheiten sicher nutzen",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Logge dich ein für volle Funktionen\nund mehr Sicherheit",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.login),
            label: const Text("Anmelden"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text("Registrieren"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 40),
          
          // Linksbündiger Text mit Sternesystem-Erklärung
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Linksbündig
              children: [
                Text(
                  "Sternesystem für mehr Sicherheit:",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("⭐ ", style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        "Basis-Verifikation (E-Mail & Telefon)",
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("⭐⭐ ", style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        "Profilfoto hinzugefügt",
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("⭐⭐⭐ ", style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        "Führerschein verifiziert",
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  "Je mehr Sterne, desto vertrauenswürdiger\ndas Profil für andere Nutzer.",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoggedInProfileView extends StatefulWidget {
  const LoggedInProfileView({super.key});

  @override
  State<LoggedInProfileView> createState() => _LoggedInProfileViewState();
}

class _LoggedInProfileViewState extends State<LoggedInProfileView> {
  final TextEditingController _townController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadHomeTown();
  }

  Future<void> _loadHomeTown() async {
    final town = await context.read<IAuthRepository>().getHomeTown();
    if (!mounted) return;
    _townController.text = town ?? '';
  }

  Future<void> _saveHomeTown() async {
    final town = _townController.text.trim();
    setState(() => _isSaving = true);
    await context.read<IAuthRepository>().setHomeTown(town);
    if (!mounted) return;
    setState(() => _isSaving = false);

    AppSnackbar.show(
        context,
        message: "Wohnort gespeichert",
      );
  }

  @override
  void dispose() {
    _townController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/image/default_avatar.png"),
            ),
            const SizedBox(height: 16),
            const Text(
              "Dein Profil",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // 🔹 Wohnort-Feld
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Wohnort",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _townController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: "z. B. Villach",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white38),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white38),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.blueAccent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveHomeTown,
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
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Wohnort speichern", style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 32),

            // Hier kannst du später dein Sternesystem etc. weiter reinbauen
          ],
        ),
      ),
    );
  }
}
