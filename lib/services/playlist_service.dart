import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../utils/NotificationHelper.dart';

class PlaylistService {
  Future<List<Song>> fetchSpotifyPlaylist(String url) async {
    List<Song> songs = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('spotify_access_token');
      final expires = prefs.getInt('spotify_token_expires') ?? 0;

      if (token == null || DateTime.now().millisecondsSinceEpoch > expires) {
        return [];
      }

      String playlistId = '';
      try {
        Uri uri = Uri.parse(url);
        playlistId = uri.pathSegments.last;
      } catch (e) {
        return [];
      }

      String apiHost = "api.spotify.com";

      String? nextUrl =
          "https://$apiHost/v1/playlists/$playlistId/items?limit=100";

      while (nextUrl != null) {
        var playlistResponse = await http.get(
          Uri.parse(nextUrl),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (playlistResponse.statusCode != 200) {
          break;
        }

        var data = jsonDecode(playlistResponse.body);

        try {
          var items = data['items'] ?? [];

          for (var item in items) {
            var trackData = item['item'] ?? item['track'];
            if (trackData == null) continue;

            String title = trackData['name']?.toString() ?? "Unbekannter Titel";

            String artist = "Unbekannter Künstler";
            if (trackData['artists'] != null &&
                (trackData['artists'] as List).isNotEmpty) {
              artist =
                  trackData['artists'][0]['name']?.toString() ??
                  "Unbekannter Künstler";
            }

            String releaseDate =
                trackData['album']?['release_date']?.toString() ?? "2000";
            int year = int.tryParse(releaseDate.split('-')[0]) ?? 2000;

            String uri = trackData['uri']?.toString() ?? "";

            int durationMs = trackData['duration_ms'] as int? ?? 180000;

            songs.add(
              Song(title, artist, year, uri, durationMs),
            ); // Parameter hinzufügen!
          }
        } catch (e) {
          NotificationHelper.showError("Fehler beim parsen eines Songs: $e");
        }

        nextUrl = data['next'];

        if (nextUrl != null) {
          NotificationHelper.showInfo(
            "LOG: Lade nächste Seite... (Bisher ${songs.length} Songs geladen)",
          );
        }
      }

      NotificationHelper.showSuccess(
        "--- ERFOLG: ALLE ${songs.length} Songs geladen ---",
      );
      return songs;
    } catch (e) {
      NotificationHelper.showError("Fehler beim auslesen der Spotifyplaylist");
      return songs;
    }
  }

  Future<List<Map<String, String>>> getSavedPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList('saved_playlists') ?? [];
    return list.map((item) {
      var parts = item.split('|||');
      return {
        "name": parts[0],
        "url": parts.length > 1 ? parts[1] : "",
        "imageUrl": parts.length > 2 ? parts[2] : "",
      };
    }).toList();
  }

  Future<void> savePlaylist(String name, String url, String imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, String>> playlists = await getSavedPlaylists();

      playlists.removeWhere((p) => p['url'] == url);
      playlists.insert(0, {"name": name, "url": url, "imageUrl": imageUrl});

      List<String> list = playlists
          .map((p) => "${p['name']}|||${p['url']}|||${p['imageUrl']}")
          .toList();
      await prefs.setStringList('saved_playlists', list);
    } catch (e) {
      NotificationHelper.showError("Fehler beim Speichern der Playlist");
    }
  }

  Future<Map<String, String>> fetchPlaylistDetails(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('spotify_access_token');
      if (token == null) return {"name": "Unbekannte Playlist", "imageUrl": ""};

      Uri uri = Uri.parse(url);
      String playlistId = uri.pathSegments.last;

      // Regulärer Spotify-API Endpunkt für Playlists
      var response = await http.get(
        Uri.parse('https://api.spotify.com/v1/playlists/$playlistId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String name = data['name'] ?? "Eigene Playlist";
        String imageUrl = "";

        // Bild-URL auslesen, falls vorhanden
        if (data['images'] != null && (data['images'] as List).isNotEmpty) {
          imageUrl = data['images'][0]['url']?.toString() ?? "";
        }

        return {"name": name, "imageUrl": imageUrl};
      }
    } catch (e) {
      NotificationHelper.showError(
        "Fehler beim Abrufen der Playlist-Details: $e",
      );
    }
    return {"name": "Eigene Playlist", "imageUrl": ""};
  }

  Future<void> deletePlaylist(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, String>> playlists = await getSavedPlaylists();

      // Playlist aus der Liste entfernen
      playlists.removeWhere((p) => p['url'] == url);

      // Liste neu speichern
      List<String> list = playlists
          .map((p) => "${p['name']}|||${p['url']}|||${p['imageUrl']}")
          .toList();
      await prefs.setStringList('saved_playlists', list);
    } catch (e) {
      NotificationHelper.showError("Fehler beim Löschen der Playlist");
    }
  }
}
