import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/player.dart';
import '../widgets/song_card.dart';
import '../widgets/timeline_slot.dart';
import '../widgets/player_switch_dialog.dart';
import '../widgets/game_stats_banner.dart';
import '../widgets/player_queue_list.dart';
import '../controllers/game_controller.dart';
import '../utils/NotificationHelper.dart';
import '../services/language_service.dart';

class GameScreen extends StatefulWidget {
  final bool isHost;
  const GameScreen({super.key, this.isHost = false});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late GameController _controller;
  late AnimationController _progressController;
  int _lastPlayerIndex = -1;
  bool _wasMusicPlaying = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = Provider.of<GameController>(context);

    if (_controller.currentPlayerIndex != _lastPlayerIndex) {
      _lastPlayerIndex = _controller.currentPlayerIndex;
      _progressController.reset();
    }

    if (_controller.isMusicPlaying && !_wasMusicPlaying) {
      _progressController.forward(from: 0.0);
    } else if (!_controller.isMusicPlaying && _wasMusicPlaying) {
      _progressController.stop();
      _progressController.reset();
    }
    _wasMusicPlaying = _controller.isMusicPlaying;

    _controller.onGuessEvaluated = (isCorrect, song) {
      if (isCorrect) {
        showDialogMsg('Richtig! 🎉', Colors.green);
      } else {
        showDialogMsg(
          'Falsch! Es war "${song.title}" von ${song.artist} (${song.year})',
          Colors.red,
        );
      }

      if (!_controller.networkService.isClient) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) nextTurn();
        });
      }
    };

    _controller.onGameEnd = () {
      if (mounted) showVictoryScreen();
    };

    // NEU: Wenn der Host die App schließt
    _controller.onConnectionLost = () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verbindung zum Host verloren!"),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    };
  }

  @override
  void dispose() {
    _progressController.dispose();
    _controller.stopMusic();
    _controller.dispose();
    super.dispose();
  }

  void nextTurn() {
    if (_controller.checkGameEnd()) {
      if (_controller.isMultiplayer) {
        _controller.networkService.broadcastState({
          'type': 'GAME_END',
          'players': _controller.players.map((p) => p.toJson()).toList(),
        });
      }
      showVictoryScreen();
      return;
    }

    int nextIndex = _controller.getNextPlayerIndex();

    if (_controller.isMultiplayer) {
      _progressController.reset();
      _controller.advanceToNextTurn(nextIndex);
    } else {
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
    }
  }

  void guessPlacement(int index) {
    Song? guessedSong = _controller.currentGuessSong;
    if (guessedSong == null) return;

    _progressController.stop();

    _controller.guessPlacement(index);
  }

  void showVictoryScreen() {
    List<Player> leaderboard = _controller.getLeaderboard();
    Player winner = leaderboard.first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
            const SizedBox(height: 10),
            Text(
              '🎉 ${winner.name} ${t('won')} 🎉',
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
                t('rankings'),
                style: const TextStyle(
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
                        '${p.score} Pkt',
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
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(t('main_menu')),
          ),
        ],
      ),
    );
  }

  void showDialogMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  Future<bool> _showExitWarning() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Spiel verlassen?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Abbrechen"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Verlassen"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _controller.stopMusic();
        if (await _showExitWarning() && context.mounted)
          Navigator.of(context).pop();
      },
      child: _buildGameContent(context),
    );
  }

  Widget _buildGameContent(BuildContext context) {
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
            cardsToWin: _controller.cardsToWin,
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
              Text(
                t('points'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${currentPlayer.score} / ${_controller.cardsToWin}',
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
          if (_controller.currentGuessSong != null) ...[
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                bool isPlaying = _controller.isMusicPlaying;
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
                          disabledBackgroundColor: isPlaying
                              ? Colors.green.shade300
                              : Colors.grey.shade400,
                          disabledForegroundColor: Colors.white,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            (!_controller.isMyTurn ||
                                _controller.isMusicLoading ||
                                isPlaying)
                            ? null
                            : () async {
                                await _controller.playMusic();
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
                              ? t('loading_audio')
                              : (isPlaying
                                    ? (_controller.isMyTurn
                                          ? "Musik läuft..."
                                          : "${_controller.currentPlayer.name} hört Musik...")
                                    : (_controller.isMyTurn
                                          ? t('play_song')
                                          : "Wartet auf ${_controller.currentPlayer.name}...")),
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
                        color: isPlaying ? Colors.green : Colors.deepPurple,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            if (_controller.isMyTurn) ...[
              const Text(
                "Bewege die Karte an die richtige Stelle!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
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
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "👀 Du schaust zu! Es ist der Zug von ${_controller.currentPlayer.name}.",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Opacity(
                opacity: 0.6,
                child: SongCard(
                  song: _controller.currentGuessSong!,
                  isSecret: true,
                ),
              ),
            ],
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
      for (int i = 0; i < groupIndex; i++) flatIndex += groups[i].songs.length;
      return flatIndex;
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 50),
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        return Column(
          children: [
            if (_controller.currentGuessSong != null && _controller.isMyTurn)
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
