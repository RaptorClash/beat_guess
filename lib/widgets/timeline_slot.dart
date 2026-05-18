import 'package:flutter/material.dart';
import '../models/song.dart';

class TimelineSlot extends StatelessWidget {
  final Function(Song) onAccept;

  const TimelineSlot({super.key, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return DragTarget<Song>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        bool isHovering = candidateData.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(vertical: isHovering ? 24.0 : 12.0),
            decoration: BoxDecoration(
              color: isHovering ? Colors.deepPurple.shade200 : Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHovering ? Colors.deepPurple : Colors.deepPurple.shade200, 
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Text(
                isHovering ? "HIER LOSLASSEN" : "+ Hier einfügen +", 
                style: TextStyle(
                  color: isHovering ? Colors.white : Colors.deepPurple, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}