import 'song.dart';

class Player {
  final String name;
  List<Song> timeline = [];

  Player({required this.name});

  int get score => timeline.length;
}
