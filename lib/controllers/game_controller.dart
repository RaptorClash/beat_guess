import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/player.dart';
import '../services/music_service.dart';
import '../services/playlist_service.dart';
import '../utils/NotificationHelper.dart';
import '../services/network_service.dart';

class GameController extends ChangeNotifier {
  final MusicService musicService = MusicService();
  final PlaylistService _playlistService = PlaylistService();
  final NetworkService networkService = NetworkService();

  List<String> playerNames = [];
  String localPlayerName = '';

  int cardsToWin = 10;
  String playlistUrl = '';
  bool playUntilAllFinish = false;

  List<Player> players = [];
  int currentPlayerIndex = 0;
  Song? currentGuessSong;
  bool isGameLoading = true;

  bool isMusicLoading = false;
  bool isMusicPlaying = false;

  int totalSongs = 0;
  List<Song> unplayedSongs = [];
  int _clientUnplayedCount = 0;

  bool isMultiplayer = false;
  String? hostCode;

  Function(bool isCorrect, Song song)? onGuessEvaluated;
  VoidCallback? onGameEnd;
  VoidCallback? onConnectionLost; // NEU

  Player get currentPlayer =>
      players.isNotEmpty ? players[currentPlayerIndex] : Player(name: 'Dummy');
  int get songsLeft =>
      (networkService.isClient ? _clientUnplayedCount : unplayedSongs.length) +
      (currentGuessSong != null ? 1 : 0);

  bool get isMyTurn {
    if (!isMultiplayer) return true;
    if (players.isEmpty) return false;
    return currentPlayer.name == localPlayerName;
  }

  GameController() {
    networkService.onStateReceived = _applyStateFromHost;
    networkService.onActionReceived = _handleClientAction;

    networkService.onPlayerDisconnected = _handlePlayerDisconnect;
    networkService.onHostDisconnected = _handleHostDisconnect;
  }

  void _handlePlayerDisconnect(String name) {
    if (!isGameLoading && players.isNotEmpty) {
      int disconnectedIndex = players.indexWhere((p) => p.name == name);
      if (disconnectedIndex != -1) {
        players.removeAt(disconnectedIndex);

        if (players.isEmpty) {
          networkService.broadcastState({'type': 'GAME_END', 'players': []});
          onGameEnd?.call();
          return;
        }

        if (disconnectedIndex < currentPlayerIndex) {
          currentPlayerIndex--;
        } else if (disconnectedIndex == currentPlayerIndex) {
          currentPlayerIndex = currentPlayerIndex % players.length;
          if (isMusicPlaying) {
            musicService.stopMusic();
            isMusicPlaying = false;
          }
          drawNextSong();
        }
        _broadcastGameState();
      }
    } else {
      playerNames.remove(name);
      _broadcastLobbyState();
    }
  }

  void _handleHostDisconnect() {
    onConnectionLost?.call();
  }

  Future<void> startAsHost(String hostName) async {
    isMultiplayer = true;
    localPlayerName = hostName;
    playerNames.add(hostName);

    hostCode = await networkService.startHosting();
    if (hostCode == null) {
      NotificationHelper.showError(
        "Konnte Lobby nicht erstellen (WLAN prüfen)",
      );
    }
    notifyListeners();
  }

  Future<bool> joinAsClient(String code, String clientName) async {
    isMultiplayer = true;
    localPlayerName = clientName;
    isGameLoading = true;
    notifyListeners();

    bool success = await networkService.joinGame(code);
    if (success) {
      networkService.sendAction({'type': 'JOIN', 'name': clientName});
    } else {
      isGameLoading = false;
      NotificationHelper.showError("Verbindung fehlgeschlagen");
      notifyListeners();
    }
    return success;
  }

  Future<void> initGame(VoidCallback onPlaylistLoadError) async {
    if (networkService.isClient) return;

    try {
      players = playerNames.map((name) => Player(name: name)).toList();

      if (playlistUrl.isNotEmpty) {
        List<Song> fetchedSongs = await _playlistService.fetchSpotifyPlaylist(
          playlistUrl,
        );
        if (fetchedSongs.isNotEmpty) {
          unplayedSongs = fetchedSongs;
        } else {
          onPlaylistLoadError();
        }
      }

      totalSongs = unplayedSongs.length;
      unplayedSongs.shuffle();

      for (var player in players) {
        if (unplayedSongs.isNotEmpty)
          player.timeline.add(unplayedSongs.removeLast());
      }

      isGameLoading = false;
      drawNextSong();
    } catch (e) {
      NotificationHelper.showError('Fehler beim Initialisieren');
    }
  }

  void drawNextSong() {
    if (networkService.isClient) return;
    if (unplayedSongs.isNotEmpty) {
      currentGuessSong = unplayedSongs.removeLast();
    } else {
      currentGuessSong = null;
    }
    _broadcastGameState();
  }

  bool guessPlacement(int index) {
    if (networkService.isClient) {
      networkService.sendAction({'type': 'GUESS', 'index': index});
      return false;
    }

    if (currentGuessSong == null) return false;

    Song guessedSong = currentGuessSong!;
    currentGuessSong = null;

    musicService.stopMusic();
    isMusicPlaying = false;

    Player p = currentPlayer;
    p.turns++;
    bool isCorrect = true;
    int songYear = guessedSong.year;

    if (index > 0 && p.timeline[index - 1].year > songYear) isCorrect = false;
    if (index < p.timeline.length && p.timeline[index].year < songYear)
      isCorrect = false;

    if (isCorrect) {
      p.timeline.insert(index, guessedSong);
    } else {
      p.wrongGuesses++;
      unplayedSongs.insert(0, guessedSong);
    }

    onGuessEvaluated?.call(isCorrect, guessedSong);

    networkService.broadcastState({
      'type': 'GUESS_RESULT',
      'isCorrect': isCorrect,
      'song': guessedSong.toJson(),
    });

    _broadcastGameState();
    return isCorrect;
  }

  void advanceToNextTurn(int nextIndex) {
    if (networkService.isClient) return;
    currentPlayerIndex = nextIndex;
    drawNextSong();
  }

  Future<bool> playMusic() async {
    if (networkService.isClient) {
      networkService.sendAction({'type': 'PLAY_MUSIC'});
      return true;
    }

    if (currentGuessSong == null || isMusicLoading || isMusicPlaying)
      return false;

    isMusicLoading = true;
    notifyListeners();

    bool success = await musicService.playSongSnippet(currentGuessSong!);

    isMusicLoading = false;

    if (success) {
      isMusicPlaying =
          true; 
    } else {
      isMusicPlaying = false;
    }

    _broadcastGameState();
    return success;
  }

  void stopMusic() {
    if (networkService.isClient) {
      networkService.sendAction({'type': 'STOP_MUSIC'});
      return;
    }
    musicService.stopMusic();
    isMusicPlaying = false;
    _broadcastGameState();
  }

  void _broadcastLobbyState() {
    if (!networkService.isHost) return;
    networkService.broadcastState({
      'type': 'LOBBY_UPDATE',
      'players': playerNames,
    });
  }

  void _broadcastGameState() {
    if (!networkService.isHost) {
      notifyListeners();
      return;
    }
    Map<String, dynamic> state = {
      'type': 'GAME_STATE',
      'currentPlayerIndex': currentPlayerIndex,
      'isGameLoading': isGameLoading,
      'currentGuessSong': currentGuessSong?.toJson(),
      'players': players.map((p) => p.toJson()).toList(),
      'isMusicPlaying': isMusicPlaying,
      'totalSongs': totalSongs,
      'unplayedCount': unplayedSongs.length,
    };
    networkService.broadcastState(state);
    notifyListeners();
  }

  void _applyStateFromHost(Map<String, dynamic> state) {
    if (state['type'] == 'LOBBY_UPDATE') {
      playerNames = List<String>.from(state['players']);
      notifyListeners();
      return;
    }

    if (state['type'] == 'GUESS_RESULT') {
      bool isCorrect = state['isCorrect'];
      Song song = Song.fromJson(state['song']);
      onGuessEvaluated?.call(isCorrect, song);
      return;
    }

    if (state['type'] == 'GAME_END') {
      if (state['players'] != null) {
        players = (state['players'] as List)
            .map((p) => Player.fromJson(p))
            .toList();
      }
      onGameEnd?.call();
      return;
    }

    if (state['type'] == 'GAME_STATE') {
      currentPlayerIndex = state['currentPlayerIndex'] ?? 0;
      isGameLoading = state['isGameLoading'] ?? false;
      isMusicPlaying = state['isMusicPlaying'] ?? false;

      totalSongs = state['totalSongs'] ?? 0;
      _clientUnplayedCount = state['unplayedCount'] ?? 0;

      if (state['currentGuessSong'] != null) {
        currentGuessSong = Song.fromJson(state['currentGuessSong']);
      } else {
        currentGuessSong = null;
      }

      if (state['players'] != null) {
        players = (state['players'] as List)
            .map((p) => Player.fromJson(p))
            .toList();
      }
      notifyListeners();
    }
  }

  void _handleClientAction(Map<String, dynamic> action) {
    if (action['type'] == 'JOIN') {
      String newName = action['name'];
      if (!playerNames.contains(newName)) {
        playerNames.add(newName);
        _broadcastLobbyState();
      }
    } else if (action['type'] == 'PLAY_MUSIC') {
      playMusic();
    } else if (action['type'] == 'STOP_MUSIC') {
      stopMusic();
    } else if (action['type'] == 'GUESS') {
      int guessedIndex = action['index'];
      guessPlacement(guessedIndex);
    }
  }

  bool checkGameEnd() {
    if (players.isEmpty) return false;
    if (!playUntilAllFinish && players.any((p) => p.score >= cardsToWin))
      return true;
    if (playUntilAllFinish && players.every((p) => p.score >= cardsToWin))
      return true;
    if (unplayedSongs.isEmpty && currentGuessSong == null) return true;
    return false;
  }

  int getNextPlayerIndex() {
    if (players.isEmpty) return 0;
    int nextIndex = (currentPlayerIndex + 1) % players.length;
    if (playUntilAllFinish) {
      int safetyCounter = 0;
      while (players[nextIndex].score >= cardsToWin &&
          safetyCounter < players.length) {
        nextIndex = (nextIndex + 1) % players.length;
        safetyCounter++;
      }
    }
    return nextIndex;
  }

  List<Player> getLeaderboard() {
    List<Player> leaderboard = List.from(players);
    leaderboard.sort((a, b) {
      int scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) return scoreComparison;
      if (playUntilAllFinish) {
        int turnComparison = a.turns.compareTo(b.turns);
        if (turnComparison != 0) return turnComparison;
      }
      return a.wrongGuesses.compareTo(b.wrongGuesses);
    });
    return leaderboard;
  }

  @override
  void dispose() {
    networkService.closeConnections();
    super.dispose();
  }
}
