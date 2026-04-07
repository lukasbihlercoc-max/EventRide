// settings_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/notifiers.dart';
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
  bool _isDarkMode = true;
  bool _notificationsEnabled = true;
  bool _locationEnabled = false;
  String _selectedLanguage = "Deutsch";

  final _townController = TextEditingController();
  bool _isSaving = false;
  bool _isEditingTown = false;
  String _originalTown = '';
  late final Stream<AppUser?> _authStream;

  @override
  void initState() {
    super.initState();
    _isDarkMode = isDarkModeNotifier.value;
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
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
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

                    // ── App-Einstellungen ──────────────────────────────────
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "App",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.dark_mode,
                          color: Colors.blueAccent),
                      title: const Text("Dark Mode",
                          style: TextStyle(color: Colors.white)),
                      trailing: Switch(
                        value: _isDarkMode,
                        onChanged: (value) {
                          setState(() => _isDarkMode = value);
                          isDarkModeNotifier.value = value;
                        },
                      ),
                    ),
                    const Divider(color: Colors.white30),
                    ListTile(
                      leading: const Icon(Icons.notifications,
                          color: Colors.orange),
                      title: const Text("Benachrichtigungen",
                          style: TextStyle(color: Colors.white)),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) =>
                            setState(() => _notificationsEnabled = value),
                      ),
                    ),
                    const Divider(color: Colors.white30),
                    ListTile(
                      leading:
                          const Icon(Icons.location_on, color: Colors.green),
                      title: const Text("Standort freigeben",
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text("Für bessere Fahrten-Vorschläge",
                          style: TextStyle(color: Colors.white70)),
                      trailing: Switch(
                        value: _locationEnabled,
                        onChanged: (value) =>
                            setState(() => _locationEnabled = value),
                      ),
                    ),
                    const Divider(color: Colors.white30),
                    ListTile(
                      leading:
                          const Icon(Icons.language, color: Colors.purple),
                      title: const Text("Sprache",
                          style: TextStyle(color: Colors.white)),
                      trailing: DropdownButton<String>(
                        value: _selectedLanguage,
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(
                              value: "Deutsch", child: Text("Deutsch")),
                          DropdownMenuItem(
                              value: "English", child: Text("English")),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedLanguage = value!),
                      ),
                    ),
                    const Divider(color: Colors.white30),

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
                      onTap: () {},
                    ),
                    const Divider(color: Colors.white30),
                    ListTile(
                      leading: const Icon(Icons.description,
                          color: Colors.grey),
                      title: const Text("AGB",
                          style: TextStyle(color: Colors.white)),
                      onTap: () {},
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Account löschen",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "Diese Aktion kann nicht rückgängig gemacht werden. Alle deine Daten werden gelöscht.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Abbrechen",
                style: TextStyle(color: Colors.blueAccent)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final auth = context.read<IAuthRepository>();
              await auth.deleteAccount();
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            child: const Text("Löschen",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
