// import 'package:uuid/uuid.dart';

enum AudioFormat { eclipsa, atmos, standard }

class Song {
  final String id;
  final String title;
  final String artistName;
  final String albumTitle;
  final int trackNumber;
  final int discNumber;
  final int? durationMs;
  final String? eclipsaPath;
  final String? atmosPath;
  final String? standardPath;
  final String? musicBrainzRecordingId;
  final String? artworkLocalPath;
  final String? artworkUrl;

  Song({
    required this.id,
    required this.title,
    required this.artistName,
    required this.albumTitle,
    required this.trackNumber,
    this.discNumber = 1,
    this.durationMs,
    this.eclipsaPath,
    this.atmosPath,
    this.standardPath,
    this.musicBrainzRecordingId,
    this.artworkLocalPath,
    this.artworkUrl,
  });

  AudioFormat? get bestAvailableFormat {
    if (eclipsaPath != null) return AudioFormat.eclipsa;
    if (atmosPath != null) return AudioFormat.atmos;
    if (standardPath != null) return AudioFormat.standard;
    return null;
  }

  String? pathForFormat(AudioFormat format) {
    switch (format) {
      case AudioFormat.eclipsa:
        return eclipsaPath;
      case AudioFormat.atmos:
        return atmosPath;
      case AudioFormat.standard:
        return standardPath;
    }
  }

  bool hasFormat(AudioFormat format) {
    return pathForFormat(format) != null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artistName': artistName,
      'albumTitle': albumTitle,
      'trackNumber': trackNumber,
      'discNumber': discNumber,
      'durationMs': durationMs,
      'eclipsaPath': eclipsaPath,
      'atmosPath': atmosPath,
      'standardPath': standardPath,
      'musicBrainzRecordingId': musicBrainzRecordingId,
      'artworkLocalPath': artworkLocalPath,
      'artworkUrl': artworkUrl,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artistName: map['artistName'] as String,
      albumTitle: map['albumTitle'] as String,
      trackNumber: map['trackNumber'] as int,
      discNumber: map['discNumber'] as int,
      durationMs: map['durationMs'] as int?,
      eclipsaPath: map['eclipsaPath'] as String?,
      atmosPath: map['atmosPath'] as String?,
      standardPath: map['standardPath'] as String?,
      musicBrainzRecordingId: map['musicBrainzRecordingId'] as String?,
      artworkLocalPath: map['artworkLocalPath'] as String?,
      artworkUrl: map['artworkUrl'] as String?,
    );
  }

  Song copyWith({
    String? id,
    String? title,
    String? artistName,
    String? albumTitle,
    int? trackNumber,
    int? discNumber,
    int? durationMs,
    String? eclipsaPath,
    String? atmosPath,
    String? standardPath,
    String? musicBrainzRecordingId,
    String? artworkLocalPath,
    String? artworkUrl,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      albumTitle: albumTitle ?? this.albumTitle,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      durationMs: durationMs ?? this.durationMs,
      eclipsaPath: eclipsaPath ?? this.eclipsaPath,
      atmosPath: atmosPath ?? this.atmosPath,
      standardPath: standardPath ?? this.standardPath,
      musicBrainzRecordingId: musicBrainzRecordingId ?? this.musicBrainzRecordingId,
      artworkLocalPath: artworkLocalPath ?? this.artworkLocalPath,
      artworkUrl: artworkUrl ?? this.artworkUrl,
    );
  }
}
