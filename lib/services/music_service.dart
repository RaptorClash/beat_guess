import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class MusicService {
  bool isPlaying = false;
  Timer? _playbackTimer;

  Future<void> playSongSnippet(Song song) async {
    if (song.spotifyUri.isEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('spotify_access_token');

      _playbackTimer?.cancel();

      int startPosition = (song.durationMs * 0.3).round();

      var response = await http.put(
        Uri.parse('https://api.spotify.com/v1/me/player/play'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "uris": [song.spotifyUri],
          "position_ms": startPosition 
        }),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        isPlaying = true;
        
        _playbackTimer = Timer(const Duration(seconds: 30), () {
          if (isPlaying) { 
             stopMusic();
          }
        });

      } else if (response.statusCode == 404) {
        print("FEHLER: Kein aktives Gerät gefunden! Bitte Spotify kurz am PC/Handy antippen.");
      } else {
        print("FEHLER bei Spotify Playback: Code ${response.statusCode}");
      }
    } catch (e) {
      print("Fehler im MusicService: $e");
    }
  }

  Future<void> stopMusic() async {
    isPlaying = false;
    
    _playbackTimer?.cancel(); 
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('spotify_access_token');

      var response = await http.put(
        Uri.parse('https://api.spotify.com/v1/me/player/pause'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 401) {
        print("Token abgelaufen, bitte neu einloggen.");
      }
    } catch (e) {
      print("Fehler beim Stoppen: $e");
    }
  }
}