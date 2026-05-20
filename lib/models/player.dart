import 'song.dart';

class Player {
  final String name;
  List<Song> timeline = [];
  int wrongGuesses = 0;
  int turns = 0;

  Player({required this.name});

  int get score => timeline.length;
}
