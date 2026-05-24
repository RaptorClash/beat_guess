import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/language_service.dart';

class PlayerQueueList extends StatelessWidget {
  final List<Player> players;
  final int currentPlayerIndex;
  final int cardsToWin;

  const PlayerQueueList({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
    required this.cardsToWin,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: players.length,
        itemBuilder: (context, index) {
          int actualIndex = (currentPlayerIndex + index) % players.length;
          Player p = players[actualIndex];
          bool isCurrent = index == 0;

          return Container(
            margin: EdgeInsets.only(left: index == 0 ? 16 : 0, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent ? Colors.amber : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isCurrent
                  ? null
                  : Border.all(color: Colors.deepPurple.shade200, width: 1.5),
              boxShadow: isCurrent
                  ? const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCurrent
                      ? Icons.play_arrow
                      : (p.score >= cardsToWin
                          ? Icons.check_circle
                          : Icons.hourglass_bottom),
                  color: isCurrent
                      ? Colors.black87
                      : (p.score >= cardsToWin
                          ? Colors.green
                          : Colors.deepPurple.shade300),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isCurrent ? "${t('next_move')} ${p.name}" : p.name,
                  style: TextStyle(
                    color: isCurrent
                        ? Colors.black87
                        : Colors.deepPurple.shade400,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}