import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/player.dart';
import '../services/music_service.dart';
import '../services/playlist_service.dart';
import '../utils/NotificationHelper.dart';

class GameController extends ChangeNotifier {
  final MusicService musicService = MusicService();
  final PlaylistService _playlistService = PlaylistService();

  final List<String> playerNames;
  final int cardsToWin;
  final String playlistUrl;
  final bool playUntilAllFinish;

  List<Player> players = [];
  int currentPlayerIndex = 0;
  Song? currentGuessSong;
  bool isGameLoading = true;
  bool isMusicLoading = false;
  int totalSongs = 0;

  List<Song> unplayedSongs = [
    Song(
      "Take On Me",
      "a-ha",
      1984,
      "spotify:track:2WfaOiMkCvy7F5fcp2zZ8L",
      120000,
    ),
    Song(
      "Smells Like Teen Spirit",
      "Nirvana",
      1991,
      "spotify:track:1f3yAtsJtY87CTmM8RLnxf",
      120000,
    ),
    Song(
      "Macarena",
      "Los del Río",
      1993,
      "spotify:track:1hlM2XzHn0GzXW2H36x5sK",
      120000,
    ),
    Song(
      "Rolling in the Deep",
      "Adele",
      2010,
      "spotify:track:4OSBTYWVwsQhGLF9NHvIbR",
      120000,
    ),
    Song(
      "Blinding Lights",
      "The Weeknd",
      2019,
      "spotify:track:0VjIjW4GlUZAMYd2vXMi3b",
      120000,
    ),
    Song(
      "As It Was",
      "Harry Styles",
      2022,
      "spotify:track:4LRPiXqCikLlN15c3yImP7",
      120000,
    ),
  ];

  Player get currentPlayer => players[currentPlayerIndex];
  int get songsLeft =>
      unplayedSongs.length + (currentGuessSong != null ? 1 : 0);

  GameController({
    required this.playerNames,
    required this.cardsToWin,
    required this.playlistUrl,
    required this.playUntilAllFinish,
  });

  Future<void> initGame(VoidCallback onPlaylistLoadError) async {
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
        if (unplayedSongs.isNotEmpty) {
          player.timeline.add(unplayedSongs.removeLast());
        }
      }

      isGameLoading = false;
      drawNextSong();
      notifyListeners();
    } catch (e) {
      NotificationHelper.showError("Fehler beim Initialisieren des Spiels");
    }
  }

  void drawNextSong() {
    try {
      if (unplayedSongs.isNotEmpty) {
        currentGuessSong = unplayedSongs.removeLast();
      } else {
        currentGuessSong = null;
      }
      notifyListeners();
    } catch (e) {
      NotificationHelper.showError("Fehler beim nächsten Song abspielen");
    }
  }

  bool checkGameEnd() {
    try {
      if (!playUntilAllFinish && players.any((p) => p.score >= cardsToWin)) {
        return true;
      }
      if (playUntilAllFinish && players.every((p) => p.score >= cardsToWin)) {
        return true;
      }
      if (unplayedSongs.isEmpty && currentGuessSong == null) {
        return true;
      }
      return false;
    } catch (e) {
      NotificationHelper.showError(
        "Fehler beim Nachschauen, ob das Spiel zu ende ist.",
      );
      return false;
    }
  }

  int getNextPlayerIndex() {
    try {
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
    } catch (e) {
      NotificationHelper.showError("Fehler nächster Spieler am Zug.");
      return 0;
    }
  }

  void advanceToNextTurn(int nextIndex) {
    currentPlayerIndex = nextIndex;
    drawNextSong();
  }

  bool guessPlacement(int index) {
    try {
      if (currentGuessSong == null) return false;

      Song guessedSong = currentGuessSong!;
      currentGuessSong = null;

      musicService.stopMusic();

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

      notifyListeners();
      return isCorrect;
    } catch (e) {
      NotificationHelper.showError("Fehler beim eintragen es Songs");
      return false;
    }
  }

  Future<bool> playMusic() async {
    try {
      if (currentGuessSong == null || isMusicLoading) return false;
      isMusicLoading = true;
      notifyListeners();

      await musicService.playSongSnippet(currentGuessSong!);

      isMusicLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      NotificationHelper.showError("Fehler beim abspielen der Musik");
      return false;
    }
  }

  void stopMusic() {
    musicService.stopMusic();
  }

  List<Player> getLeaderboard() {
    try {
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
    } catch (e) {
      NotificationHelper.showError("Fehler beim öffnen der Rangliste");
      return List.from(players);
    }
  }
}
