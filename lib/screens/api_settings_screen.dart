import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../utils/NotificationHelper.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final TextEditingController _clientIdController = TextEditingController();
  final TextEditingController _clientSecretController = TextEditingController();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _clientIdController.text = prefs.getString('spotify_client_id') ?? '';
        _clientSecretController.text =
            prefs.getString('spotify_client_secret') ?? '';

        int expires = prefs.getInt('spotify_token_expires') ?? 0;
        _isLoggedIn = DateTime.now().millisecondsSinceEpoch < expires;
      });
    } catch (e) {
      NotificationHelper.showError("Fehler beim laden der api_settings_screen.dart.");
    }
  }

  Future<void> _loginSpotify() async {
    try {
      String clientId = _clientIdController.text.trim();
      String clientSecret = _clientSecretController.text.trim();

      if (clientId.isEmpty || clientSecret.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bitte Client ID UND Secret eingeben!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('spotify_client_id', clientId);
      await prefs.setString('spotify_client_secret', clientSecret);

      String redirectUri = kIsWeb
          ? "http://127.0.0.1:8080/"
          : "beatguess://callback";
      String authHost = "accounts.spotify.com";
      String scopes =
          "playlist-read-private playlist-read-collaborative user-read-private user-read-email user-modify-playback-state";

      Uri authUri = Uri.https(authHost, '/authorize', {
        'client_id': clientId,
        'response_type': 'code',
        'redirect_uri': redirectUri,
        'scope': scopes,
        'show_dialog': 'true',
      });

      try {
        await launchUrl(
          authUri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_self',
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fehler: Konnte den Browser nicht öffnen!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      NotificationHelper.showError("Fehler beim einloggen mit Spotify");
    }
  }

  Future<void> _logoutSpotify() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('spotify_access_token');
      await prefs.remove('spotify_token_expires');

      setState(() {
        _isLoggedIn = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Abgemeldet! Du kannst dich jetzt mit einem anderen Account einloggen.",
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      NotificationHelper.showError("Fehler beim ausloggen mit Spotify");
    }
  }

  Widget _buildInstructionStep(
    int step,
    String text, {
    List<String>? copyTexts,
    String? linkUrl,
    String? linkText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            child: Text(
              step.toString(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
                if (linkUrl != null) ...[
                  const SizedBox(height: 4),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse(linkUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(
                      linkText ?? "Öffnen",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],

                if (copyTexts != null) ...[
                  const SizedBox(height: 8),
                  ...copyTexts.map(
                    (copyText) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepPurple.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                child: SelectableText(
                                  copyText,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                size: 20,
                                color: Colors.deepPurple,
                              ),
                              tooltip: "Kopieren",
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: copyText),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "In die Zwischenablage kopiert!",
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Spotify API Setup")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.settings_suggest, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          "Verknüpfung einrichten",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildInstructionStep(
                      1,
                      "Erstelle eine eigene Entwickler-App im Spotify Dashboard.",
                      linkUrl: "https://developer.spotify.com/dashboard",
                      linkText: "Zum Spotify Dashboard",
                    ),
                    _buildInstructionStep(
                      2,
                      "Gehe zu 'User Management' und füge deinen Namen sowie die E-Mail-Adresse deines Spotify-Accounts hinzu.",
                    ),
                    _buildInstructionStep(
                      3,
                      "Fülle die 'Basic Information' aus (z.B. App Name und Beschreibung).",
                    ),
                    _buildInstructionStep(
                      4,
                      "Trage unter 'Redirect URIs' die folgenden Links exakt so ein (du kannst beide eintragen):",
                      copyTexts: [
                        "http://127.0.0.1:8080/",
                        "beatguess://callback",
                      ],
                    ),
                    _buildInstructionStep(
                      5,
                      "Kopiere die 'Client ID' und das 'Client Secret' aus dem Dashboard und füge sie hier unten ein.",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _clientIdController,
              decoration: const InputDecoration(
                labelText: "Spotify Client ID",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clientSecretController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Spotify Client Secret",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoggedIn
                      ? Colors.green
                      : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: _loginSpotify,
                icon: Icon(_isLoggedIn ? Icons.check : Icons.login),
                label: Text(
                  _isLoggedIn
                      ? "VERBUNDEN (Klick zum Erneuern)"
                      : "MIT SPOTIFY EINLOGGEN",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (_isLoggedIn) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: _logoutSpotify,
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    "Von Spotify abmelden",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
