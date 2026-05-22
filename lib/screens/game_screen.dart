import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/player.dart';
import '../widgets/song_card.dart';
import '../widgets/timeline_slot.dart';
import '../widgets/player_switch_dialog.dart';
import '../widgets/game_stats_banner.dart';
import '../widgets/player_queue_list.dart';
import '../controllers/game_controller.dart';
import '../utils/NotificationHelper.dart';

class GameScreen extends StatefulWidget {
  final List<String> playerNames;
  final int cardsToWin;
  final String playlistUrl;
  final bool playUntilAllFinish;

  const GameScreen({
    super.key,
    required this.playerNames,
    required this.cardsToWin,
    required this.playlistUrl,
    required this.playUntilAllFinish,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late GameController _controller;
  late AnimationController _progressController;

  @override
  void initState() {
    try {
      super.initState();
      _progressController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 30),
      );

      _controller = GameController(
        playerNames: widget.playerNames,
        cardsToWin: widget.cardsToWin,
        playlistUrl: widget.playlistUrl,
        playUntilAllFinish: widget.playUntilAllFinish,
      );

      _controller.addListener(_onControllerChanged);

      _controller.initGame(() {
        showDialogMsg(
          "Playlist konnte nicht geladen werden. Nutze Standard-Songs.",
          Colors.orange,
        );
      });
    } catch (e) {
      NotificationHelper.showError("Fehler beim initialisieren der game_screen.dart");
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    try {
      _progressController.dispose();
      _controller.removeListener(_onControllerChanged);
      _controller.stopMusic();
      super.dispose();
    } catch (e) {
      NotificationHelper.showError("Fehler beim beenden");
    }
  }

  void nextTurn() {
    try {
      if (_controller.checkGameEnd()) {
        showVictoryScreen();
        return;
      }

      int nextIndex = _controller.getNextPlayerIndex();
      Player nextPlayer = _controller.players[nextIndex];

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PlayerSwitchDialog(playerName: nextPlayer.name),
      ).then((_) {
        if (mounted) {
          _progressController.reset();
          _controller.advanceToNextTurn(nextIndex);
        }
      });
    } catch (e) {
      NotificationHelper.showError("Fehler beim nächsten Zug machen.");
    }
  }

  void guessPlacement(int index) {
    try {
      Song? guessedSong = _controller.currentGuessSong;
      if (guessedSong == null) return;

      _progressController.stop();
      bool isCorrect = _controller.guessPlacement(index);

      if (isCorrect) {
        showDialogMsg('Richtig! 🎉', Colors.green);
      } else {
        showDialogMsg(
          'Falsch! Es war "${guessedSong.title}" von ${guessedSong.artist} (${guessedSong.year})',
          Colors.red,
        );
      }

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) nextTurn();
      });
    } catch (e) {
      NotificationHelper.showError("Fehler beim Karten platzieren");
    }
  }

  void showVictoryScreen() {
    try {
      List<Player> leaderboard = _controller.getLeaderboard();
      Player winner = leaderboard.first;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
              const SizedBox(height: 10),
              Text(
                '🎉 ${winner.name} GEWINNT! 🎉',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.playUntilAllFinish
                      ? 'Alle Spieler haben ${widget.cardsToWin} Karten gesammelt!\n${winner.name} war am schnellsten.'
                      : '${winner.name} hat als Erstes ${widget.cardsToWin} Karten gesammelt!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Rangliste:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 10),
                ...leaderboard.asMap().entries.map((entry) {
                  int rank = entry.key + 1;
                  Player p = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$rank. ${p.name}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: p.name == winner.name
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          widget.playUntilAllFinish
                              ? '${p.score} Pkt | ${p.turns} Züge'
                              : '${p.score} Pkt (${p.wrongGuesses} F)',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Hauptmenü',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      NotificationHelper.showError("Fehler beim anzeigen des Siegesbildschirms");
    }
  }

  void showDialogMsg(String msg, Color color) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(milliseconds: 2000),
        ),
      );
    } catch (e) {
      NotificationHelper.showError("Fehler beim anzeigen der Snackbar.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isGameLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    Player currentPlayer = _controller.currentPlayer;

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: _buildAppBar(currentPlayer),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GameStatsBanner(
              totalSongs: _controller.totalSongs,
              songsLeft: _controller.songsLeft,
              wrongGuesses: currentPlayer.wrongGuesses,
            ),
          ),
          const SizedBox(height: 16),
          PlayerQueueList(
            players: _controller.players,
            currentPlayerIndex: _controller.currentPlayerIndex,
            cardsToWin: widget.cardsToWin,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildPlayArea(),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildTimeline(currentPlayer)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Player currentPlayer) {
    return AppBar(
      toolbarHeight: 70,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  currentPlayer.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Punkte',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${currentPlayer.score} / ${widget.cardsToWin}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      width: double.infinity,
      child: Column(
        children: [
          const Text(
            "Zieh die Karte an die richtige Stelle!",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          if (_controller.currentGuessSong != null) ...[
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                bool isPlaying = _progressController.isAnimating;

                return Column(
                  children: [
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPlaying
                              ? Colors.green
                              : Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: isPlaying ? 6 : 2,
                        ),
                        onPressed: _controller.isMusicLoading
                            ? null
                            : () async {
                                if (isPlaying) return;

                                bool success = await _controller.playMusic();
                                if (success && mounted) {
                                  _progressController.forward(from: 0.0);
                                }
                              },
                        icon: _controller.isMusicLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isPlaying ? Icons.music_note : Icons.play_arrow,
                              ),
                        label: Text(
                          _controller.isMusicLoading
                              ? "Lade Audio..."
                              : (isPlaying
                                    ? "Song wird abgespielt..."
                                    : "Song abspielen (30s)"),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progressController.value,
                        minHeight: 8,
                        backgroundColor: Colors.deepPurple.shade100,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Draggable<Song>(
              data: _controller.currentGuessSong,
              feedback: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Opacity(
                  opacity: 0.9,
                  child: SongCard(
                    song: _controller.currentGuessSong!,
                    isSecret: true,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.4,
                child: SongCard(
                  song: _controller.currentGuessSong!,
                  isSecret: true,
                ),
              ),
              child: SongCard(
                song: _controller.currentGuessSong!,
                isSecret: true,
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                "Stapel leer! 🎉",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Player currentPlayer) {
    List<YearGroup> groups = [];
    for (var song in currentPlayer.timeline) {
      if (groups.isEmpty || groups.last.year != song.year) {
        groups.add(YearGroup(song.year, [song]));
      } else {
        groups.last.songs.add(song);
      }
    }

    int getFlatIndex(int groupIndex) {
      int flatIndex = 0;
      for (int i = 0; i < groupIndex; i++) {
        flatIndex += groups[i].songs.length;
      }
      return flatIndex;
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 50),
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        return Column(
          children: [
            if (_controller.currentGuessSong != null)
              TimelineSlot(
                onAccept: (_) => guessPlacement(getFlatIndex(index)),
              ),
            if (index < groups.length) YearGroupCard(group: groups[index]),
          ],
        );
      },
    );
  }
}
