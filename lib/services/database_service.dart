import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'melodia.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY
          )
        ''');
        await db.execute('''
          CREATE TABLE playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE playlist_songs (
            playlist_id INTEGER,
            song_id INTEGER,
            PRIMARY KEY (playlist_id, song_id),
            FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // Favorites
  Future<void> addFavorite(int songId) async {
    final db = await database;
    await db.insert('favorites', {'id': songId}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeFavorite(int songId) async {
    final db = await database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [songId]);
  }

  Future<List<int>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return List.generate(maps.length, (i) => maps[i]['id'] as int);
  }

  // Playlists
  Future<int> createPlaylist(String name) async {
    final db = await database;
    return await db.insert('playlists', {'name': name});
  }

  Future<void> deletePlaylist(int id) async {
    final db = await database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final db = await database;
    return await db.query('playlists');
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    final db = await database;
    await db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': songId
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    final db = await database;
    await db.delete('playlist_songs', 
      where: 'playlist_id = ? AND song_id = ?', 
      whereArgs: [playlistId, songId]);
  }

  Future<List<int>> getPlaylistSongs(int playlistId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('playlist_songs', 
      where: 'playlist_id = ?', 
      whereArgs: [playlistId]);
    return List.generate(maps.length, (i) => maps[i]['song_id'] as int);
  }
}
