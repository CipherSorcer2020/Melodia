import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/playlist_model.dart';
import '../services/library_service.dart';
import '../services/database_service.dart';

class LibraryProvider with ChangeNotifier {
  final LibraryService _libraryService = LibraryService();
  final DatabaseService _dbService = DatabaseService();
  
  List<SongModel> _songs = [];
  Set<int> _favorites = {};
  List<CustomPlaylist> _playlists = [];
  
  bool _isLoading = false;
  bool _hasPermission = false;

  List<SongModel> get songs => _songs;
  List<SongModel> get favoriteSongs => _songs.where((s) => _favorites.contains(s.id)).toList();
  List<CustomPlaylist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _hasPermission = await _libraryService.checkAndRequestPermissions();
      if (_hasPermission) {
        await refreshSongs();
        await _loadUserData();
      }
    } catch (e) {
      debugPrint('Error during library initialization: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSongs() async {
    _songs = await _libraryService.fetchSongs();
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    final favList = await _dbService.getFavorites();
    _favorites = favList.toSet();
    
    final pList = await _dbService.getPlaylists();
    _playlists = [];
    for (var p in pList) {
      final songIds = await _dbService.getPlaylistSongs(p['id']);
      final pSongs = _songs.where((s) => songIds.contains(s.id)).toList();
      _playlists.add(CustomPlaylist(
        id: p['id'],
        name: p['name'],
        songs: pSongs,
      ));
    }
    notifyListeners();
  }

  // Favorites
  bool isFavorite(int songId) => _favorites.contains(songId);

  Future<void> toggleFavorite(int songId) async {
    if (_favorites.contains(songId)) {
      _favorites.remove(songId);
      await _dbService.removeFavorite(songId);
    } else {
      _favorites.add(songId);
      await _dbService.addFavorite(songId);
    }
    notifyListeners();
  }

  // Playlists
  Future<void> createPlaylist(String name) async {
    final id = await _dbService.createPlaylist(name);
    _playlists.add(CustomPlaylist(id: id, name: name));
    notifyListeners();
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    await _dbService.addSongToPlaylist(playlistId, songId);
    await _loadUserData(); // Reload to sync songs in objects
  }

  Future<void> deletePlaylist(int id) async {
    await _dbService.deletePlaylist(id);
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> deleteSongFromDevice(SongModel song) async {
    // Note: LibraryService.deleteSong returns false for now as it's complex on Android 11+
    // We can remove it from our list to simulate deletion for the UI session
    _songs.removeWhere((s) => s.id == song.id);
    _favorites.remove(song.id);
    await _dbService.removeFavorite(song.id);
    notifyListeners();
  }
}
