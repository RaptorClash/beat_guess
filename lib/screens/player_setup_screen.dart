import 'package:beat_guess/services/language_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_screen.dart';
import 'api_settings_screen.dart';
import '../services/spotify_auth_service.dart';
import '../services/playlist_service.dart';
import '../utils/notification_helper.dart';
import '../controllers/game_controller.dart';

class PlayerSetupScreen extends StatefulWidget {
  final bool isHost;
  final String? hostName;
  final bool isBluetooth;

  const PlayerSetupScreen({
    super.key,
    required this.isHost,
    this.hostName,
    this.isBluetooth = false,
  });

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final SpotifyAuthService _authService = SpotifyAuthService();
  final PlaylistService _playlistService = PlaylistService();

  late GameController
  _controller;

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
    _controller = GameController();

    if (widget.isHost && widget.hostName != null) {
      _controller.startAsHost(
        widget.hostName!,
        useBluetooth: widget.isBluetooth,
      );
      _controller.addListener(() {
        if (mounted) setState(() {});
      });
    }
    _loadData();
  }

  Future<bool> _showExitWarning(String messageKey) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t('warning'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Text(t(messageKey)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    t('cancel'),
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    t('yes_leave'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _loadData() async {
    try {
      bool loggedIn = await _authService.checkAndRefreshLogin();
      List<Map<String, String>> playlists = await _playlistService
          .getSavedPlaylists();
      if (mounted)
        setState(() {
          _isLoggedIn = loggedIn;
          _savedPlaylists = playlists;
        });
    } catch (e) {
      NotificationHelper.showError(t('error_loading_player_setup_screen'));
    }
  }

  void addPlayer() {
    String newName = _nameController.text.trim();
    if (newName.isNotEmpty && !_controller.playerNames.contains(newName)) {
      setState(() {
        _controller.playerNames.add(newName);
        _nameController.clear();
      });
    }
  }

  Future<void> startGame() async {
    try {
      if (_controller.playerNames.isEmpty)
        _controller.playerNames.add(t('solo_player'));
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

      _controller.cardsToWin = _cardsToWin;
      _controller.playlistUrl = url;
      _controller.playUntilAllFinish = _playUntilAllFinish;

      await _controller.initGame(() {
        NotificationHelper.showError(t('playlist_error'));
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: _controller,
            child: GameScreen(isHost: widget.isHost),
          ),
        ),
      );
    } catch (e) {
      NotificationHelper.showError(t('error_starting_game'));
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _deletePlaylist(String url) async {
    await _playlistService.deletePlaylist(url);
    if (_playlistController.text == url) _playlistController.clear();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldLeave = await _showExitWarning('exit_setup_warning');
        if (shouldLeave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            t('new_game'),
            style: const TextStyle(fontWeight: FontWeight.bold),
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
              if (widget.isHost) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.isBluetooth
                            ? t('bluetooth_radar_active')
                            : t('code_for_friends'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _controller.hostCode == null
                          ? const CircularProgressIndicator(color: Colors.white)
                          : (widget.isBluetooth
                                ? Text(
                                    t('friends_can_join'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : Text(
                                    _controller.hostCode!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                    ),
                                  )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _buildPlayerCard(),
              const SizedBox(height: 20),
              _buildRulesCard(),
              const SizedBox(height: 32),
              _buildStartButton(),
              const SizedBox(height: 20),
            ],
          ),
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
                const Icon(Icons.people_alt, color: Colors.deepPurple),
                const SizedBox(width: 10),
                Text(
                  t('whos_in'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!widget.isHost)
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

            if (_controller.playerNames.isNotEmpty) ...[
              if (!widget.isHost) const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _controller.playerNames.asMap().entries.map((entry) {
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
                    deleteIconColor: widget.isHost
                        ? Colors.transparent
                        : Colors.red.shade400,
                    onDeleted: widget.isHost
                        ? null
                        : () => setState(
                            () => _controller.playerNames.removeAt(idx),
                          ),
                  );
                }).toList(),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                t('no_players_added'),
                style: const TextStyle(
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
                const Icon(Icons.tune, color: Colors.deepPurple),
                const SizedBox(width: 10),
                Text(
                  t('game_rules'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              t('points_to_win'),
              style: const TextStyle(
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
              style: const TextStyle(
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
              style: const TextStyle(
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
              ),
            ),
            if (_savedPlaylists.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                t('playlist_library'),
                style: const TextStyle(
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
                    bool isSelected =
                        _playlistController.text == playlist['url'];
                    return GestureDetector(
                      onTap: () => setState(
                        () => _playlistController.text = playlist['url']!,
                      ),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child:
                                        (playlist['imageUrl'] ?? "").isNotEmpty
                                        ? Image.network(
                                            playlist['imageUrl']!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                _buildPlaceholderImage(),
                                          )
                                        : _buildPlaceholderImage(),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _deletePlaylist(playlist['url']!),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}
