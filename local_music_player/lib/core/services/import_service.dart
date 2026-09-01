import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import 'database_service.dart';

class ImportResult {
  final int artistsImported;
  final int albumsImported;
  final int songsImported;
  final List<String> errors;

  const ImportResult({
    required this.artistsImported,
    required this.albumsImported,
    required this.songsImported,
    required this.errors,
  });
}

class ImportService {
  final _uuid = const Uuid();

  Future<ImportResult> importZip(String zipFilePath) async {
    final errors = <String>[];

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final libraryPath = p.join(docDir.path, 'library');
      final libraryDir = Directory(libraryPath);
      if (!libraryDir.existsSync()) {
        libraryDir.createSync(recursive: true);
      }

      // Extract zip
      final bytes = await File(zipFilePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      extractArchiveToDisk(archive, libraryPath);

      // artist -> album -> trackTitle -> { format -> absolutePath }
      final songMap = <String, Map<String, Map<String, Map<AudioFormat, String>>>>{};

      await for (final entity in libraryDir.list(recursive: true)) {
        if (entity is! File) continue;

        final relPath = p.relative(entity.path, from: libraryPath);
        final parts = p.split(relPath);

        // Must be: <Format>/<Artist>/<Album>/<track>.<ext>
        if (parts.length < 4) continue;

        final formatStr = parts[0];
        final artist = parts[1];
        final album = parts[2];
        final track = p.basenameWithoutExtension(parts.last);

        AudioFormat? format;
        if (formatStr.toLowerCase() == 'eclipsa') {
          format = AudioFormat.eclipsa;
        } else if (formatStr.toLowerCase() == 'atmos') {
          format = AudioFormat.atmos;
        } else if (formatStr.toLowerCase() == 'standard') {
          format = AudioFormat.standard;
        }

        if (format == null) continue;

        songMap.putIfAbsent(artist, () => {});
        songMap[artist]!.putIfAbsent(album, () => {});
        songMap[artist]![album]!.putIfAbsent(track, () => {});
        songMap[artist]![album]![track]![format] = entity.path;
      }

      // Build model objects
      final artistObjects = <Artist>[];
      final albumObjects = <Album>[];
      final songObjects = <Song>[];

      for (final artistName in songMap.keys) {
        final artistId = _uuid.v5(Uuid.NAMESPACE_URL, 'artist:$artistName');
        final artistAlbums = <Album>[];

        for (final albumTitle in songMap[artistName]!.keys) {
          final albumId = _uuid.v5(
              Uuid.NAMESPACE_URL, 'album:$artistName:$albumTitle');
          final albumTracks = <Song>[];
          var trackNumber = 1;

          // Sort tracks alphabetically for consistent ordering
          final trackTitles =
              songMap[artistName]![albumTitle]!.keys.toList()..sort();

          for (final trackTitle in trackTitles) {
            final formats = songMap[artistName]![albumTitle]![trackTitle]!;
            final songId = _uuid.v5(
                Uuid.NAMESPACE_URL, 'song:$artistName:$albumTitle:$trackTitle');

            final song = Song(
              id: songId,
              title: trackTitle,
              artistName: artistName,
              albumTitle: albumTitle,
              trackNumber: trackNumber++,
              eclipsaPath: formats[AudioFormat.eclipsa],
              atmosPath: formats[AudioFormat.atmos],
              standardPath: formats[AudioFormat.standard],
            );
            albumTracks.add(song);
            songObjects.add(song);
          }

          final album = Album(
            id: albumId,
            title: albumTitle,
            artistName: artistName,
            tracks: albumTracks,
          );
          artistAlbums.add(album);
          albumObjects.add(album);
        }

        final artist = Artist(
          id: artistId,
          name: artistName,
          albums: artistAlbums,
        );
        artistObjects.add(artist);
      }

      final db = DatabaseService.instance;
      try {
        for (final artist in artistObjects) {
          await db.insertArtist(artist);
        }
        for (final album in albumObjects) {
          // Find matching artist id
          final matchingArtist = artistObjects.firstWhere(
            (a) => a.name == album.artistName,
          );
          await db.insertAlbum(album, artistId: matchingArtist.id);
        }
        for (final song in songObjects) {
          // Find matching album id
          final matchingAlbum = albumObjects.firstWhere(
            (a) => a.title == song.albumTitle && a.artistName == song.artistName,
          );
          await db.insertSong(song, albumId: matchingAlbum.id);
        }
      } catch (dbErr) {
        errors.add('DB persist error: $dbErr');
      }

      return ImportResult(
        artistsImported: artistObjects.length,
        albumsImported: albumObjects.length,
        songsImported: songObjects.length,
        errors: errors,
      );
    } catch (e, st) {
      errors.add('Import failed: $e\n$st');
      return ImportResult(
        artistsImported: 0,
        albumsImported: 0,
        songsImported: 0,
        errors: errors,
      );
    }
  }

  Future<void> clearLibrary() async {
    final docDir = await getApplicationDocumentsDirectory();
    final libraryPath = p.join(docDir.path, 'library');
    final dir = Directory(libraryPath);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    await DatabaseService.instance.clearAll();
  }
}
