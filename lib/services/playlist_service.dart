import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class PlaylistService {
  Future<List<Song>> fetchSpotifyPlaylist(String url) async {
    
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
    
    String? nextUrl = "https://$apiHost/v1/playlists/$playlistId/items?limit=100";
    List<Song> songs = [];

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
          if (trackData['artists'] != null && (trackData['artists'] as List).isNotEmpty) {
            artist = trackData['artists'][0]['name']?.toString() ?? "Unbekannter Künstler";
          }

        String releaseDate = trackData['album']?['release_date']?.toString() ?? "2000";
          int year = int.tryParse(releaseDate.split('-')[0]) ?? 2000;
          
          String uri = trackData['uri']?.toString() ?? ""; 
          
          int durationMs = trackData['duration_ms'] as int? ?? 180000; 

          songs.add(Song(title, artist, year, uri, durationMs)); // Parameter hinzufügen!
        }
      } catch (e) {
        print("❌ FEHLER BEIM PARSEN EINES SONGS: $e");
      }

      nextUrl = data['next']; 
      
      if (nextUrl != null) {
        print("LOG: Lade nächste Seite... (Bisher ${songs.length} Songs geladen)");
      }
    }

    print("--- ERFOLG: ALLE ${songs.length} Songs geladen ---");
    return songs;
  }
}