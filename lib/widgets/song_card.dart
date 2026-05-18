import 'package:flutter/material.dart';
import '../models/song.dart';

class YearGroup {
  final int year;
  final List<Song> songs;
  YearGroup(this.year, this.songs);
}

class YearGroupCard extends StatelessWidget {
  final YearGroup group;

  const YearGroupCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 80,
              color: Colors.deepPurple,
              alignment: Alignment.center,
              child: Text(
                group.year.toString(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: group.songs.map((song) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.music_note, size: 16, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${song.title} - ${song.artist}",
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SongCard extends StatelessWidget {
  final Song song;
  final bool showYear; 
  final bool isSecret; 

  const SongCard({
    super.key, 
    required this.song, 
    this.showYear = true,
    this.isSecret = false, 
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isSecret ? Colors.deepPurple.shade300 : Colors.white,
      elevation: isSecret ? 8 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (isSecret) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.help_outline, size: 40, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        "In welches Jahr gehört dieser Song?", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                ),
              )
            ] 
            else ...[
              const Icon(Icons.album, color: Colors.deepPurple, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(song.artist, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ),
              if (showYear)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    song.year.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
                  ),
                ),
            ]
          ],
        ),
      ),
    );
  }
}