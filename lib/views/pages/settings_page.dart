// settings_page.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // Für ImageFilter.blur
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/notifiers.dart';
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

  @override
  void initState() {
    super.initState();
    // Initialwerte aus den Notifiers laden
    _isDarkMode = isDarkModeNotifier.value;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🔧 Hintergrundverlauf (genau wie in DetailPage)
        AppBackground(child: Container()),
        Container(color: Colors.black.withOpacity(0.4)),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(color: Colors.transparent),
        ),

        // 🔧 Eigentlicher Inhalt
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
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // Dark Mode Toggle
                ListTile(
                  leading: const Icon(
                    Icons.dark_mode,
                    color: Colors.blueAccent,
                  ),
                  title: const Text(
                    "Dark Mode",
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Switch(
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() => _isDarkMode = value);
                      isDarkModeNotifier.value = value;
                    },
                  ),
                ),
                const Divider(color: Colors.white30),

                // Benachrichtigungen
                ListTile(
                  leading: const Icon(
                    Icons.notifications,
                    color: Colors.orange,
                  ),
                  title: const Text(
                    "Benachrichtigungen",
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) =>
                        setState(() => _notificationsEnabled = value),
                  ),
                ),
                const Divider(color: Colors.white30),

                // Standortfreigabe
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.green),
                  title: const Text(
                    "Standort freigeben",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    "Für bessere Fahrten-Vorschläge",
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: Switch(
                    value: _locationEnabled,
                    onChanged: (value) =>
                        setState(() => _locationEnabled = value),
                  ),
                ),
                const Divider(color: Colors.white30),

                // Sprache
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.purple),
                  title: const Text(
                    "Sprache",
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: "Deutsch",
                        child: Text("Deutsch"),
                      ),
                      DropdownMenuItem(
                        value: "English",
                        child: Text("English"),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedLanguage = value!),
                  ),
                ),
                const Divider(color: Colors.white30),

                // Datenschutz
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.red),
                  title: const Text(
                    "Datenschutz",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    // Datenschutz-Seite öffnen
                  },
                ),
                const Divider(color: Colors.white30),

                // AGB
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.grey),
                  title: const Text(
                    "AGB",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    // AGB-Seite öffnen
                  },
                ),
                const Divider(color: Colors.white30),

                // Account Management
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

                // Ausloggen
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.amber),
                  title: const Text(
                    "Ausloggen",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                ),
                const Divider(color: Colors.white30),

                // Account löschen
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text(
                    "Account löschen",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    _showDeleteAccountDialog(context);
                  },
                ),
              ],
            ),
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
        title: const Text("Ausloggen", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Möchtest du dich wirklich ausloggen?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Abbrechen",
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await authRepository.signOut();
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            child: const Text("Ausloggen", style: TextStyle(color: Colors.red)),
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
        title: const Text(
          "Account löschen",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Diese Aktion kann nicht rückgängig gemacht werden. Alle deine Daten werden gelöscht.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Abbrechen",
              style: TextStyle(color: Colors.blueAccent),
            ),
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
            child: const Text("Löschen", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
