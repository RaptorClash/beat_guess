class Song {
  final String title;
  final String artist;
  final int year;
  final String spotifyUri;
  final int durationMs;

  Song(this.title, this.artist, this.year, this.spotifyUri, this.durationMs);

  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'year': year,
    'spotifyUri': spotifyUri,
    'durationMs': durationMs,
  };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
    json['title'],
    json['artist'],
    json['year'],
    json['spotifyUri'],
    json['durationMs'],
  );
}
