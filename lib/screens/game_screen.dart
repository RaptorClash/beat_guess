import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/player.dart';
import '../widgets/song_card.dart';
import '../widgets/timeline_slot.dart';
import '../services/music_service.dart';
import '../services/playlist_service.dart';

class GameScreen extends StatefulWidget {
  final List<String> playerNames;
  final int cardsToWin;
  final String playlistUrl;

  const GameScreen({
    super.key, 
    required this.playerNames, 
    required this.cardsToWin,
    required this.playlistUrl,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  final PlaylistService _playlistService = PlaylistService();
  bool _isMusicLoading = false;
  bool _isGameLoading = true; 

  late AnimationController _progressController;

  int _totalSongs = 0;

  List<Song> unplayedSongs = [
    Song("Take On Me", "a-ha", 1984, "spotify:track:2WfaOiMkCvy7F5fcp2zZ8L", 120000),
    Song("Smells Like Teen Spirit", "Nirvana", 1991, "spotify:track:1f3yAtsJtY87CTmM8RLnxf", 120000),
    Song("Macarena", "Los del Río", 1993, "spotify:track:1hlM2XzHn0GzXW2H36x5sK", 120000),
    Song("Rolling in the Deep", "Adele", 2010, "spotify:track:4OSBTYWVwsQhGLF9NHvIbR", 120000),
    Song("Blinding Lights", "The Weeknd", 2019, "spotify:track:0VjIjW4GlUZAMYd2vXMi3b", 120000),
    Song("As It Was", "Harry Styles", 2022, "spotify:track:4LRPiXqCikLlN15c3yImP7", 120000),
  ];
  
  List<Player> players = [];
  int currentPlayerIndex = 0;
  Song? currentGuessSong;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 30)
    );
    _initGame();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _musicService.stopMusic();
    super.dispose();
  }

  Future<void> _initGame() async {
    players = widget.playerNames.map((name) => Player(name: name)).toList();

    if (widget.playlistUrl.isNotEmpty) {
      List<Song> fetchedSongs = await _playlistService.fetchSpotifyPlaylist(widget.playlistUrl);
      if (fetchedSongs.isNotEmpty) {
        unplayedSongs = fetchedSongs;
      } else {
        showDialogMsg("Playlist konnte nicht geladen werden. Nutze Standard-Songs.", Colors.orange);
      }
    }

    _totalSongs = unplayedSongs.length;
    unplayedSongs.shuffle();

    for (var player in players) {
      if (unplayedSongs.isNotEmpty) player.timeline.add(unplayedSongs.removeLast());
    }

    setState(() {
      _isGameLoading = false;
      drawNextSong();
    });
  }

  void drawNextSong() {
    _progressController.reset(); 

    if (unplayedSongs.isNotEmpty) {
      setState(() => currentGuessSong = unplayedSongs.removeLast());
    } else {
      setState(() => currentGuessSong = null);
    }
  }

  void nextTurn() {
    Player current = players[currentPlayerIndex];

    if (current.score >= widget.cardsToWin) {
      showVictoryScreen(current);
      return;
    }

    int nextIndex = (currentPlayerIndex + 1) % players.length;
    Player nextPlayer = players[nextIndex];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PlayerSwitchDialog(playerName: nextPlayer.name),
    ).then((_) {
      setState(() {
        currentPlayerIndex = nextIndex; 
      });
      drawNextSong(); 
    });
  }
  void guessPlacement(int index) {
    if (currentGuessSong == null) return;
    
    _musicService.stopMusic();
    _progressController.stop();

    Player currentPlayer = players[currentPlayerIndex];
    bool isCorrect = true;
    int songYear = currentGuessSong!.year;

    if (index > 0 && currentPlayer.timeline[index - 1].year > songYear) isCorrect = false;
    if (index < currentPlayer.timeline.length && currentPlayer.timeline[index].year < songYear) isCorrect = false;

    if (isCorrect) {
      showDialogMsg('Richtig! 🎉', Colors.green);
      setState(() => currentPlayer.timeline.insert(index, currentGuessSong!));
    } else {
      showDialogMsg('Falsch! Es war "${currentGuessSong!.title}" von ${currentGuessSong!.artist} (${currentGuessSong!.year})', Colors.red);
      
      setState(() {
        currentPlayer.wrongGuesses++;
        unplayedSongs.insert(0, currentGuessSong!);
      });
    }
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) nextTurn();
    });
  }

  void showDialogMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
        backgroundColor: color, 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 2000)
      ),
    );
  }

  void showVictoryScreen(Player winner) {
    List<Player> leaderboard = List.from(players);
    leaderboard.sort((a, b) {
      int scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) return scoreComparison;
      return a.wrongGuesses.compareTo(b.wrongGuesses);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
            const SizedBox(height: 10),
            Text('🎉 ${winner.name} GEWINNT! 🎉', textAlign: TextAlign.center),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${winner.name} hat als Erstes ${widget.cardsToWin} Karten gesammelt!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text('Rangliste:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
              const SizedBox(height: 10),
              ...leaderboard.asMap().entries.map((entry) {
                int rank = entry.key + 1;
                Player p = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$rank. ${p.name}', style: TextStyle(fontSize: 16, fontWeight: p.name == winner.name ? FontWeight.bold : FontWeight.normal)),
                      Text('${p.score} Pkt (${p.wrongGuesses} Fehler)', style: const TextStyle(fontSize: 16, color: Colors.black54)),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(context).pop(); 
              Navigator.of(context).pop(); 
            },
            child: const Text('Hauptmenü', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isGameLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.deepPurple)));
    }

    Player currentPlayer = players[currentPlayerIndex];
    int songsLeft = unplayedSongs.length + (currentGuessSong != null ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
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
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    currentPlayer.name, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Punkte', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
                Text(
                  '${currentPlayer.score} / ${widget.cardsToWin}', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.deepPurple)
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade600]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.music_note, 'Gesamt', '$_totalSongs', Colors.white),
                  _buildStatItem(Icons.layers, 'Übrig', '$songsLeft', Colors.white),
_buildStatItem(Icons.close, 'Fehler', '${currentPlayer.wrongGuesses}', Colors.redAccent.shade100),                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              width: double.infinity,
              child: Column(
                children: [
                  const Text("Zieh die Karte an die richtige Stelle!", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 12),
                  
                  if (currentGuessSong != null) ...[
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
                                  backgroundColor: isPlaying ? Colors.green : Colors.deepPurple, 
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: isPlaying ? 6 : 2,
                                ),
                                onPressed: _isMusicLoading ? null : () async {
                                  if (isPlaying) return;

                                  setState(() => _isMusicLoading = true);
                                  await _musicService.playSongSnippet(currentGuessSong!);
                                  
                                  setState(() => _isMusicLoading = false);
                                  _progressController.forward(from: 0.0);
                                },
                                icon: _isMusicLoading 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Icon(isPlaying ? Icons.music_note : Icons.play_arrow), 
                                label: Text(
                                  _isMusicLoading 
                                      ? "Lade Audio..." 
                                      : (isPlaying ? "Song wird abgespielt..." : "Song abspielen (30s)"),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                color: Colors.deepPurple
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 20),
                    
                    Draggable<Song>(
                      data: currentGuessSong,
                      feedback: SizedBox(width: MediaQuery.of(context).size.width * 0.85, child: Opacity(opacity: 0.9, child: SongCard(song: currentGuessSong!, isSecret: true))),
                      childWhenDragging: Opacity(opacity: 0.4, child: SongCard(song: currentGuessSong!, isSecret: true)),
                      child: SongCard(song: currentGuessSong!, isSecret: true),
                    )
                  ] else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text("Stapel leer! 🎉", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: Builder( 
              builder: (context) {
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
                        if (currentGuessSong != null) 
                          TimelineSlot(onAccept: (_) => guessPlacement(getFlatIndex(index))),
                        
                      if (index < groups.length) 
                        YearGroupCard(group: groups[index]),
                      ],
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class PlayerSwitchDialog extends StatefulWidget {
  final String playerName;
  
  const PlayerSwitchDialog({super.key, required this.playerName});

  @override
  State<PlayerSwitchDialog> createState() => _PlayerSwitchDialogState();
}

class _PlayerSwitchDialogState extends State<PlayerSwitchDialog> with SingleTickerProviderStateMixin {
  bool _isReady = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isReady = true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.transparent, 
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween(begin: 0.85, end: 1.1).animate(
                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
              ),
              child: const Icon(Icons.screen_rotation, color: Colors.white, size: 80),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gerät weitergeben an:',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.playerName,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _isReady
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Bin bereit!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    )
                  : const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 12),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}