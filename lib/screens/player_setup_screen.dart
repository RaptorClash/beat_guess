import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'game_screen.dart';
import 'api_settings_screen.dart';

class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final List<String> players = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _playlistController = TextEditingController();
  int _cardsToWin = 10;
  bool _playUntilAllFinish = false;
  bool _isStarting = false;
  bool _isLoggedIn = true;
  List<Map<String, String>> _savedPlaylists = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPlaylists();
    _checkAndRefreshLogin();
  }

  Future<void> _checkAndRefreshLogin() async {
    final prefs = await SharedPreferences.getInstance();
    int expires = prefs.getInt('spotify_token_expires') ?? 0;
    String? refreshToken = prefs.getString('spotify_refresh_token');

    int now = DateTime.now().millisecondsSinceEpoch;

    if (now > expires - 300000) {
      if (refreshToken != null) {
        await _refreshAccessToken(
          refreshToken,
        );
      } else {
        setState(
          () => _isLoggedIn = false,
        );
      }
    } else {
      setState(() => _isLoggedIn = true);
    }
  }

  Future<void> _refreshAccessToken(String refreshToken) async {
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

        setState(() => _isLoggedIn = true);
      } else {
        setState(() => _isLoggedIn = false);
      }
    } catch (e) {
      setState(() => _isLoggedIn = false);
    }
  }

  Future<void> _loadSavedPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList('saved_playlists') ?? [];

    setState(() {
      _savedPlaylists = list.map((item) {
        var parts = item.split('|||');
        return {"name": parts[0], "url": parts.length > 1 ? parts[1] : ""};
      }).toList();
    });
  }

  Future<void> _savePlaylist(String name, String url) async {
    final prefs = await SharedPreferences.getInstance();

    _savedPlaylists.removeWhere((p) => p['url'] == url);
    _savedPlaylists.insert(0, {"name": name, "url": url});

    List<String> list = _savedPlaylists
        .map((p) => "${p['name']}|||${p['url']}")
        .toList();
    await prefs.setStringList('saved_playlists', list);

    setState(() {});
  }

  Future<String> _fetchPlaylistName(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('spotify_access_token');
      if (token == null) return "Unbekannte Playlist";

      Uri uri = Uri.parse(url);
      String playlistId = uri.pathSegments.last;

      var response = await http.get(
        Uri.parse('https://api.spotify.com/v1/playlists/$playlistId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['name'] ?? "Eigene Playlist";
      }
    } catch (e) {
      print("Fehler beim Abrufen des Playlist-Namens: $e");
    }
    return "Eigene Playlist";
  }

  Future<void> _deleteSavedPlaylist(String url) async {
    final prefs = await SharedPreferences.getInstance();
    _savedPlaylists.removeWhere((p) => p['url'] == url);
    List<String> list = _savedPlaylists
        .map((p) => "${p['name']}|||${p['url']}")
        .toList();
    await prefs.setStringList('saved_playlists', list);
    setState(() {});
  }

  void addPlayer() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        players.add(_nameController.text.trim());
        _nameController.clear();
      });
    }
  }

  Future<void> startGame() async {
    if (players.isEmpty) players.add("Solo-Spieler");

    setState(() => _isStarting = true);

    String url = _playlistController.text.trim();

    if (url.isNotEmpty) {
      bool alreadySaved = _savedPlaylists.any((p) => p['url'] == url);
      if (!alreadySaved) {
        String name = await _fetchPlaylistName(url);
        await _savePlaylist(name, url);
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          playerNames: players,
          cardsToWin: _cardsToWin,
          playlistUrl: url,
          playUntilAllFinish: _playUntilAllFinish,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Neues Spiel",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible:
                  !_isLoggedIn,
              backgroundColor: Colors.redAccent,
              smallSize: 12,
              child: const Icon(Icons.settings),
            ),
            tooltip: 'API Setup',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApiSettingsScreen(),
                ),
              );

              _checkAndRefreshLogin();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.people_alt, color: Colors.deepPurple),
                        SizedBox(width: 10),
                        Text(
                          "Wer spielt mit?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: "Spielername",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => addPlayer(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: addPlayer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),

                    if (players.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: players.asMap().entries.map((entry) {
                          int idx = entry.key;
                          String name = entry.value;
                          return InputChip(
                            label: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            avatar: CircleAvatar(
                              backgroundColor: Colors.deepPurple.shade700,
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            backgroundColor: Colors.deepPurple.shade50,
                            deleteIconColor: Colors.red.shade400,
                            onDeleted: () =>
                                setState(() => players.removeAt(idx)),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      const Text(
                        "Noch keine Spieler hinzugefügt.\n(Startest du jetzt, spielst du alleine!)",
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.tune, color: Colors.deepPurple),
                        SizedBox(width: 10),
                        Text(
                          "Spielregeln",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Punkte zum Sieg:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12.0,
                      children: [5, 10, 15, 20].map((int value) {
                        bool isSelected = _cardsToWin == value;
                        return ChoiceChip(
                          label: Text("$value Karten"),
                          selected: isSelected,
                          selectedColor: Colors.deepPurple,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _cardsToWin = value);
                          },
                        );
                      }).toList(),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(height: 1),
                    ),

                    const Text(
                      "Spielmodus:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 8.0,
                      children: [
                        ChoiceChip(
                          label: const Text("Bis der Erste gewinnt"),
                          selected: !_playUntilAllFinish,
                          selectedColor: Colors.deepPurple,
                          labelStyle: TextStyle(
                            color: !_playUntilAllFinish
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: !_playUntilAllFinish
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected)
                              setState(() => _playUntilAllFinish = false);
                          },
                        ),
                        ChoiceChip(
                          label: const Text("Bis alle fertig sind"),
                          selected: _playUntilAllFinish,
                          selectedColor: Colors.deepPurple,
                          labelStyle: TextStyle(
                            color: _playUntilAllFinish
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: _playUntilAllFinish
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected)
                              setState(() => _playUntilAllFinish = true);
                          },
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(height: 1),
                    ),

                    const Text(
                      "Playlist:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _playlistController,
                      decoration: InputDecoration(
                        labelText: "Spotify Playlist-Link einfügen",
                        hintText: "https://open.spotify.com/playlist/...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.queue_music),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _playlistController.clear(),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),

                    if (_savedPlaylists.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        "Zuletzt gespielt:",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _savedPlaylists.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            var playlist = _savedPlaylists[index];
                            return ActionChip(
                              label: Text(playlist['name']!),
                              avatar: const Icon(
                                Icons.history,
                                size: 16,
                                color: Colors.deepPurple,
                              ),
                              backgroundColor: Colors.deepPurple.shade50,
                              onPressed: () {
                                setState(() {
                                  _playlistController.text = playlist['url']!;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isStarting ? null : startGame,
                child: _isStarting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SPIEL STARTEN",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
