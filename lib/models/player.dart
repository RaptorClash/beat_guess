import 'song.dart';

class Player {
  final String name;
  List<Song> timeline = [];
  int wrongGuesses = 0;
  int turns = 0;

  Player({required this.name});

  int get score => timeline.length;

  Map<String, dynamic> toJson() => {
    'name': name,
    'wrongGuesses': wrongGuesses,
    'turns': turns,
    'timeline': timeline.map((s) => s.toJson()).toList(),
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    var p = Player(name: json['name']);
    p.wrongGuesses = json['wrongGuesses'];
    p.turns = json['turns'];
    if (json['timeline'] != null) {
      p.timeline = (json['timeline'] as List)
          .map((s) => Song.fromJson(s))
          .toList();
    }
    return p;
  }
}
