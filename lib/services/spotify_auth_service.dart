import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/NotificationHelper.dart';

class SpotifyAuthService {
  Future<void> exchangeCodeForToken(String code) async {
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

      print("Sende Token-Anfrage an Spotify...");

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

        print("ERFOLG: Spotify Token wurde gespeichert!");
        NotificationHelper.showSuccess("Spotify Token wurde gespeichert!");
      } else {
        NotificationHelper.showError(
          "Fehler vom Spotify-Server: Code ${response.statusCode}",
        );
      }
    } catch (e) {
      NotificationHelper.showError("Fehler beim Verarbeiten des Logins: $e");
    }
  }

  Future<bool> checkAndRefreshLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int expires = prefs.getInt('spotify_token_expires') ?? 0;
      String? refreshToken = prefs.getString('spotify_refresh_token');

      int now = DateTime.now().millisecondsSinceEpoch;

      if (now > expires - 300000) {
        if (refreshToken != null) {
          return await refreshAccessToken(refreshToken);
        } else {
          return false;
        }
      }
      return true;
    } catch (e) {
      NotificationHelper.showError("Fehler beim aktualisieren des Logins");
      return false;
    }
  }

  Future<bool> refreshAccessToken(String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String clientId = prefs.getString('spotify_client_id') ?? '';
      String clientSecret = prefs.getString('spotify_client_secret') ?? '';

      String credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));

      var response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'refresh_token', 'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        await prefs.setString('spotify_access_token', data['access_token']);

        if (data['refresh_token'] != null) {
          await prefs.setString('spotify_refresh_token', data['refresh_token']);
        }
        await prefs.setInt(
          'spotify_token_expires',
          DateTime.now().millisecondsSinceEpoch + 3600000,
        );
        return true;
      }
      return false;
    } catch (e) {
      NotificationHelper.showError("Fehler beim aktualisieren des Refresh Tokens");
      return false;
    }
  }
}
