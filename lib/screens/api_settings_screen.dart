import 'package:beat_guess/services/language_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../utils/notification_helper.dart';

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
      NotificationHelper.showError(t('error_laoding_api_settings_screen'));
    }
  }

  Future<void> _loginSpotify() async {
    try {
      String clientId = _clientIdController.text.trim();
      String clientSecret = _clientSecretController.text.trim();

      if (clientId.isEmpty || clientSecret.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('enterClientAndSecret')),
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
          SnackBar(
            content: Text(t('error_cannot_open_browser')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      NotificationHelper.showError(t('error_login_spotify'));
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
        SnackBar(
          content: Text(t('logout_spotify')),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      NotificationHelper.showError(t('error_logout_spotify'));
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
                                    content: Text(t('copy_to_clipboard')),
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
      appBar: AppBar(title: Text(t('api_setup'))),
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
                      children: [
                        Icon(Icons.settings_suggest, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          t('set_up_link'),
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
                      t('create_developer_app'),
                      linkUrl: "https://developer.spotify.com/dashboard",
                      linkText: t('api_tutorial_step1'),
                    ),
                    _buildInstructionStep(2, t('api_tutorial_step2')),
                    _buildInstructionStep(3, t('api_tutorial_step3')),
                    _buildInstructionStep(
                      4,
                      t('api_tutorial_step4'),
                      copyTexts: [
                        "http://127.0.0.1:8080/",
                        "beatguess://callback",
                      ],
                    ),
                    _buildInstructionStep(5, t('api_tutorial_step5')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _clientIdController,
              decoration: InputDecoration(
                labelText: t('spotify_client_id'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clientSecretController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: t('spotify_client_secret'),
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
                      ? t('connected_to_spotify')
                      : t('signin_with_spotify'),
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
                  label: Text(
                    t('signout_spotify'),
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
