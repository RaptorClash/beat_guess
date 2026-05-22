import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'screens/start_screen.dart';

import 'services/spotify_auth_service.dart'; 

import 'services/url_helper_stub.dart'
    if (dart.library.html) 'services/url_helper_web.dart'
    as url_helper;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = SpotifyAuthService();

  String? code = url_helper.getWebUrlCode();
  if (code != null) {
    url_helper.clearWebUrl();
  }

  if (!kIsWeb) {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((uri) {
      if (uri.queryParameters.containsKey('code')) {
        String appCode = uri.queryParameters['code']!;
        authService.exchangeCodeForToken(appCode);
      }
    });
  }

  runApp(const BeatGuessApp());

  if (code != null) {
    await authService.exchangeCodeForToken(code);
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