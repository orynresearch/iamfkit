import 'song.dart';

class Album {
  final String id;
  final String title;
  final String artistName;
  final int? year;
  final String? artworkLocalPath;
  final String? artworkUrl;
  final String? musicBrainzReleaseId;
  final List<Song> tracks;

  Album({
    required this.id,
    required this.title,
    required this.artistName,
    this.year,
    this.artworkLocalPath,
    this.artworkUrl,
    this.musicBrainzReleaseId,
    this.tracks = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artistName': artistName,
      'year': year,
      'artworkLocalPath': artworkLocalPath,
      'artworkUrl': artworkUrl,
      'musicBrainzReleaseId': musicBrainzReleaseId,
    };
  }

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'] as String,
      title: map['title'] as String,
      artistName: map['artistName'] as String,
      year: map['year'] as int?,
      artworkLocalPath: map['artworkLocalPath'] as String?,
      artworkUrl: map['artworkUrl'] as String?,
      musicBrainzReleaseId: map['musicBrainzReleaseId'] as String?,
    );
  }

  Album copyWith({
    String? id,
    String? title,
    String? artistName,
    int? year,
    String? artworkLocalPath,
    String? artworkUrl,
    String? musicBrainzReleaseId,
    List<Song>? tracks,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      year: year ?? this.year,
      artworkLocalPath: artworkLocalPath ?? this.artworkLocalPath,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      musicBrainzReleaseId: musicBrainzReleaseId ?? this.musicBrainzReleaseId,
      tracks: tracks ?? this.tracks,
    );
  }
}
