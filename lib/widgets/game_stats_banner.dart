import 'package:flutter/material.dart';

class GameStatsBanner extends StatelessWidget {
  final int totalSongs;
  final int songsLeft;
  final int wrongGuesses;

  const GameStatsBanner({
    super.key,
    required this.totalSongs,
    required this.songsLeft,
    required this.wrongGuesses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade800,
            Colors.deepPurple.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.music_note, 'Gesamt', '$totalSongs', Colors.white),
          _buildStatItem(Icons.layers, 'Übrig', '$songsLeft', Colors.white),
          _buildStatItem(Icons.close, 'Fehler', '$wrongGuesses', Colors.redAccent.shade100),
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
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}