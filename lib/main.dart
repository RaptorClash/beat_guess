import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'screens/start_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

import 'services/url_helper_stub.dart'
    if (dart.library.html) 'services/url_helper_web.dart'
    as url_helper;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? code = url_helper.getWebUrlCode();
  if (code != null) {
    url_helper.clearWebUrl();
  }

  if (!kIsWeb) {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((uri) {
      if (uri.queryParameters.containsKey('code')) {
        String appCode = uri.queryParameters['code']!;
        _exchangeCodeForToken(appCode);
      }
    });
  }

  runApp(const BeatGuessApp());

  if (code != null) {
    await _exchangeCodeForToken(code);
  }
}

Future<void> _exchangeCodeForToken(String code) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String clientId = prefs.getString('spotify_client_id') ?? '';
    String clientSecret = prefs.getString('spotify_client_secret') ?? '';

    if (clientId.isEmpty || clientSecret.isEmpty) {
      print("FEHLER: Client ID oder Secret fehlen in den SharedPreferences!");
      return;
    }

    String credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));

    String redirectUri = kIsWeb
        ? "http://127.0.0.1:8080/"
        : "beatguess://callback";

    print("Sende Token-Anfrage an Spotify..."); // <-- LOG

    // HIER IST DIE ECHTE SPOTIFY URL:
    var response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'), 
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      String token = data['access_token'];
      String? refreshToken = data['refresh_token'];

      await prefs.setString('spotify_access_token', token);

      if (refreshToken != null) {
        await prefs.setString('spotify_refresh_token', refreshToken);
      }

      await prefs.setInt(
        'spotify_token_expires',
        DateTime.now().millisecondsSinceEpoch + 3600000,
      );
      
      print("ERFOLG: Spotify Token wurde gespeichert!"); // <-- LOG
    } else {
      print("FEHLER vom Spotify-Server: Code ${response.statusCode}"); // <-- LOG
      print("Antwort: ${response.body}"); // <-- LOG (Ganz wichtig für uns!)
    }
  } catch (e) {
    print("FEHLER beim Verarbeiten des Logins: $e");
  }
}

class BeatGuessApp extends StatelessWidget {
  const BeatGuessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeatGuess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const StartScreen(),
    );
  }
}
