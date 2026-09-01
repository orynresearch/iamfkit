import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';

class DatabaseService {
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'local_music_player.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE artists(
        id TEXT PRIMARY KEY,
        name TEXT,
        musicBrainzArtistId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE albums(
        id TEXT PRIMARY KEY,
        artistId TEXT,
        title TEXT,
        artistName TEXT,
        year INTEGER,
        artworkLocalPath TEXT,
        artworkUrl TEXT,
        musicBrainzReleaseId TEXT,
        FOREIGN KEY(artistId) REFERENCES artists(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE songs(
        id TEXT PRIMARY KEY,
        albumId TEXT,
        title TEXT,
        artistName TEXT,
        albumTitle TEXT,
        trackNumber INTEGER,
        discNumber INTEGER,
        durationMs INTEGER,
        eclipsaPath TEXT,
        atmosPath TEXT,
        standardPath TEXT,
        musicBrainzRecordingId TEXT,
        artworkLocalPath TEXT,
        artworkUrl TEXT,
        FOREIGN KEY(albumId) REFERENCES albums(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> clearAll() async {
    Database db = await database;
    await db.execute('DROP TABLE IF EXISTS songs');
    await db.execute('DROP TABLE IF EXISTS albums');
    await db.execute('DROP TABLE IF EXISTS artists');
    await _onCreate(db, 1);
  }

  // Artist CRUD
  Future<void> insertArtist(Artist artist) async {
    Database db = await database;
    await db.insert(
      'artists',
      artist.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Artist>> getArtists() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('artists');
    return List.generate(maps.length, (i) {
      return Artist.fromMap(maps[i]);
    });
  }

  Future<void> updateArtist(Artist artist) async {
    Database db = await database;
    await db.update(
      'artists',
      artist.toMap(),
      where: 'id = ?',
      whereArgs: [artist.id],
    );
  }

  // Album CRUD
  Future<void> insertAlbum(Album album, {required String artistId}) async {
    Database db = await database;
    Map<String, dynamic> map = album.toMap();
    map['artistId'] = artistId;
    await db.insert(
      'albums',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Album>> getAlbumsForArtist(String artistId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'albums',
      where: 'artistId = ?',
      whereArgs: [artistId],
    );
    return List.generate(maps.length, (i) {
      return Album.fromMap(maps[i]);
    });
  }

  Future<void> updateAlbum(Album album) async {
    Database db = await database;
    await db.update(
      'albums',
      album.toMap(),
      where: 'id = ?',
      whereArgs: [album.id],
    );
  }

  // Song CRUD
  Future<void> insertSong(Song song, {required String albumId}) async {
    Database db = await database;
    Map<String, dynamic> map = song.toMap();
    map['albumId'] = albumId;
    await db.insert(
      'songs',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Song>> getSongsForAlbum(String albumId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      where: 'albumId = ?',
      whereArgs: [albumId],
    );
    return List.generate(maps.length, (i) {
      return Song.fromMap(maps[i]);
    });
  }

  Future<List<Song>> getAllSongs() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('songs');
    return List.generate(maps.length, (i) {
      return Song.fromMap(maps[i]);
    });
  }

  Future<void> updateSong(Song song) async {
    Database db = await database;
    await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }
}
