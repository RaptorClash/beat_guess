import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import 'game_screen.dart';

class ClientWaitingScreen extends StatefulWidget {
  final GameController controller;
  const ClientWaitingScreen({super.key, required this.controller});

  @override
  State<ClientWaitingScreen> createState() => _ClientWaitingScreenState();
}

class _ClientWaitingScreenState extends State<ClientWaitingScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.onConnectionLost = () {
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
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (!widget.controller.isGameLoading &&
            widget.controller.players.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(
                  value: widget.controller,
                  child: const GameScreen(isHost: false),
                ),
              ),
            );
          });
        }

        return Scaffold(
          backgroundColor: Colors.deepPurple,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 30),
                Text(
                  "Du bist drin als: ${widget.controller.localPlayerName} 🎉",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Warten auf den Host...",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 60),
                const Text(
                  "Wer ist noch in der Lobby?",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                ...widget.controller.playerNames.map(
                  (name) => Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}