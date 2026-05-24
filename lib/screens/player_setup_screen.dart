import 'package:beat_guess/services/language_service.dart';
import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'api_settings_screen.dart';
import '../services/spotify_auth_service.dart';
import '../services/playlist_service.dart';
import '../utils/NotificationHelper.dart';

class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final SpotifyAuthService _authService = SpotifyAuthService();
  final PlaylistService _playlistService = PlaylistService();

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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      bool loggedIn = await _authService.checkAndRefreshLogin();
      List<Map<String, String>> playlists = await _playlistService
          .getSavedPlaylists();

      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
          _savedPlaylists = playlists;
        });
      }
    } catch (e) {
      NotificationHelper.showError(t('error_loading_player_setup_screen'));
    }
  }

  void addPlayer() {
    try {
      String newName = _nameController.text.trim();
      if (newName.isNotEmpty) {
        if (players.contains(newName)) {
          NotificationHelper.showError(t('username_already_exists'));
          return;
        }

        setState(() {
          players.add(newName);
          _nameController.clear();
        });
      }
    } catch (e) {
      NotificationHelper.showError(t('error_adding_player'));
    }
  }

  Future<void> startGame() async {
    try {
      if (players.isEmpty) players.add(t('solo_player'));

      setState(() => _isStarting = true);
      String url = _playlistController.text.trim();

      if (url.isNotEmpty) {
        bool alreadySaved = _savedPlaylists.any((p) => p['url'] == url);
        if (!alreadySaved) {
          var details = await _playlistService.fetchPlaylistDetails(url);
          await _playlistService.savePlaylist(
            details['name']!,
            url,
            details['imageUrl']!,
          );
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
      ).then((_) {
        if (mounted) setState(() => _isStarting = false);
      });
    } catch (e) {
      NotificationHelper.showError(t('error_starting_game'));
    }
  }

  Future<void> _deletePlaylist(String url) async {
    await _playlistService.deletePlaylist(url);

    if (_playlistController.text == url) {
      _playlistController.clear();
    }

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('new_game'),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: !_isLoggedIn,
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
              _loadData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPlayerCard(),
            const SizedBox(height: 20),
            _buildRulesCard(),
            const SizedBox(height: 32),
            _buildStartButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_alt, color: Colors.deepPurple),
                SizedBox(width: 10),
                Text(
                  t('whos_in'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      labelText: "${t('player_name')}",
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                    onDeleted: () => setState(() => players.removeAt(idx)),
                  );
                }).toList(),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                t('no_players_added'),
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRulesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.deepPurple),
                SizedBox(width: 10),
                Text(
                  t('game_rules'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              t('points_to_win'),
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
                  label: Text("$value ${t('cards')}"),
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
            Text(
              t('game_mode'),
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
                  label: Text(t('first_one_wins')),
                  selected: !_playUntilAllFinish,
                  selectedColor: Colors.deepPurple,
                  labelStyle: TextStyle(
                    color: !_playUntilAllFinish ? Colors.white : Colors.black87,
                    fontWeight: !_playUntilAllFinish
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _playUntilAllFinish = false);
                  },
                ),
                ChoiceChip(
                  label: Text(t('everyone_done')),
                  selected: _playUntilAllFinish,
                  selectedColor: Colors.deepPurple,
                  labelStyle: TextStyle(
                    color: _playUntilAllFinish ? Colors.white : Colors.black87,
                    fontWeight: _playUntilAllFinish
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _playUntilAllFinish = true);
                  },
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1),
            ),
            Text(
              t('playlist'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _playlistController,
              decoration: InputDecoration(
                labelText: "${t('insert_spotify_link')}",
                hintText: "http://spotify.com/playlist/...",
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
              const SizedBox(height: 24),
              Text(
                t('playlist_library'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _savedPlaylists.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    var playlist = _savedPlaylists[index];
                    String imageUrl = playlist['imageUrl'] ?? "";
                    bool isSelected =
                        _playlistController.text == playlist['url'];

                    return GestureDetector(
                      onTap: () {
                        setState(
                          () => _playlistController.text = playlist['url']!,
                        );
                      },
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stack erlaubt es uns, das X über das Bild zu legen
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.deepPurple
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    _buildPlaceholderImage(),
                                          )
                                        : _buildPlaceholderImage(),
                                  ),
                                ),
                                // Das "X" Icon zum Entfernen oben rechts
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Verhindert, dass das Antippen des X auch die Playlist auswählt
                                      _deletePlaylist(playlist['url']!);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(
                                          0.6,
                                        ), // Halbtransparenter Kreis
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              playlist['name']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.deepPurple
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.deepPurple.shade100,
      child: const Icon(Icons.music_note, color: Colors.deepPurple, size: 40),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
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
            : Text(
                t('start_game'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}
