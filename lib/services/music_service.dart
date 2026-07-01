import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../utils/notification_helper.dart';
import '../services/language_service.dart';

class MusicService {
  bool isPlaying = false;
  Timer? _playbackTimer;

  Future<bool> playSongSnippet(Song song) async {
    try {
      if (song.spotifyUri.isEmpty) {
        return false;
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
            "position_ms": startPosition,
          }),
        );

        if (response.statusCode == 204 || response.statusCode == 200) {
          isPlaying = true;

          _playbackTimer = Timer(const Duration(seconds: 30), () {
            if (isPlaying) {
              stopMusic();
            }
          });

          return true;
        } else if (response.statusCode == 404) {
          NotificationHelper.showError(t('error_no_active_device_found'));
          return false;
        } else {
          NotificationHelper.showError(
            t('error_during_spotify_playback', {
              'statusCode': response.statusCode.toString(),
            }),
          );
          return false;
        }
      } catch (e) {
        NotificationHelper.showError(
          t('error_in_musicservice', {'error': e.toString()}),
        );
        return false;
      }
    } catch (e) {
      NotificationHelper.showError(t('error_while_playing_song'));
      return false;
    }
  }

  Future<void> stopMusic() async {
    try {
      isPlaying = false;
      _playbackTimer?.cancel();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('spotify_access_token');

      var response = await http.put(
        Uri.parse('https://api.spotify.com/v1/me/player/pause'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        print(t('token_expired'));
      }
    } catch (e) {
      NotificationHelper.showError(t('error_stopping_music'));
    }
  }
}
