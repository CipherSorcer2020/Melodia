import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_model.dart';
import '../services/library_service.dart';
import '../services/database_service.dart';

enum SongSortCriteria {
  title,
  dateAdded,
}

enum SortOrder {
  ascending,
  descending,
}

class LibraryProvider with ChangeNotifier {
  final LibraryService _libraryService = LibraryService();
  final DatabaseService _dbService = DatabaseService();
  late SharedPreferences _prefs;
  
  List<SongModel> _allSongs = [];
  Set<int> _favorites = {};
  List<CustomPlaylist> _playlists = [];
  
  bool _isLoading = false;
  bool _hasPermission = false;

  String _searchQuery = '';
  SongSortCriteria _sortCriteria = SongSortCriteria.title;
  SortOrder _sortOrder = SortOrder.ascending;

  // Exposed getters for UI
  List<SongModel> get songs {
    List<SongModel> filteredSongs = _allSongs.where((song) {
      if (_searchQuery.isEmpty) return true;
      return song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (song.artist?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    filteredSongs.sort((a, b) {
      int compareResult;
      switch (_sortCriteria) {
        case SongSortCriteria.title:
          compareResult = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case SongSortCriteria.dateAdded:
          compareResult = (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0);
          break;
      }
      return _sortOrder == SortOrder.ascending ? compareResult : -compareResult;
    });

    return filteredSongs;
  }
  List<SongModel> get favoriteSongs => songs.where((s) => _favorites.contains(s.id)).toList();
  List<CustomPlaylist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String get searchQuery => _searchQuery;
  SongSortCriteria get sortCriteria => _sortCriteria;
  SortOrder get sortOrder => _sortOrder;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _prefs = await SharedPreferences.getInstance();
    _loadPreferences();

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

  void _loadPreferences() {
    _searchQuery = _prefs.getString('searchQuery') ?? '';
    _sortCriteria = SongSortCriteria.values.byName(_prefs.getString('sortCriteria') ?? SongSortCriteria.title.name);
    _sortOrder = SortOrder.values.byName(_prefs.getString('sortOrder') ?? SortOrder.ascending.name);
  }

  Future<void> _savePreferences() async {
    await _prefs.setString('searchQuery', _searchQuery);
    await _prefs.setString('sortCriteria', _sortCriteria.name);
    await _prefs.setString('sortOrder', _sortOrder.name);
  }

  Future<void> refreshSongs() async {
    _allSongs = await _libraryService.fetchSongs();
    notifyListeners();
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setSortCriteria(SongSortCriteria criteria) async {
    _sortCriteria = criteria;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setSortOrder(SortOrder order) async {
    _sortOrder = order;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    final favList = await _dbService.getFavorites();
    _favorites = favList.toSet();
    
    final pList = await _dbService.getPlaylists();
    _playlists = [];
    for (var p in pList) {
      final songIds = await _dbService.getPlaylistSongs(p['id']);
      final pSongs = _allSongs.where((s) => songIds.contains(s.id)).toList();
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
    _allSongs.removeWhere((s) => s.id == song.id);
    _favorites.remove(song.id);
    await _dbService.removeFavorite(song.id);
    notifyListeners();
  }
}
