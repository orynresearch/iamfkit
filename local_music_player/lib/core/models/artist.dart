import 'album.dart';

class Artist {
  final String id;
  final String name;
  final String? musicBrainzArtistId;
  final List<Album> albums;

  Artist({
    required this.id,
    required this.name,
    this.musicBrainzArtistId,
    this.albums = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'musicBrainzArtistId': musicBrainzArtistId,
    };
  }

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] as String,
      name: map['name'] as String,
      musicBrainzArtistId: map['musicBrainzArtistId'] as String?,
    );
  }

  Artist copyWith({
    String? id,
    String? name,
    String? musicBrainzArtistId,
    List<Album>? albums,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      musicBrainzArtistId: musicBrainzArtistId ?? this.musicBrainzArtistId,
      albums: albums ?? this.albums,
    );
  }
}
