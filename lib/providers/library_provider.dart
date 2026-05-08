import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_model.dart';
import '../services/database_service.dart';
import '../services/library_service.dart';

enum SongSortCriteria { title, dateAdded }

enum SortOrder { ascending, descending }

class LibraryProvider with ChangeNotifier {
  final _libraryService = LibraryService();
  final _dbService = DatabaseService();

  // Nullable until initialize() completes
  SharedPreferences? _prefs;

  List<SongModel> _allSongs = [];
  Set<int> _favorites = {};
  List<CustomPlaylist> _playlists = [];

  bool _isLoading = false;
  bool _hasPermission = false;
  String _searchQuery = '';
  SongSortCriteria _sortCriteria = SongSortCriteria.title;
  SortOrder _sortOrder = SortOrder.ascending;

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String get searchQuery => _searchQuery;
  SongSortCriteria get sortCriteria => _sortCriteria;
  SortOrder get sortOrder => _sortOrder;

  List<SongModel> get songs {
    var list = _searchQuery.isEmpty
        ? _allSongs
        : _allSongs.where((s) {
            final q = _searchQuery.toLowerCase();
            return s.title.toLowerCase().contains(q) ||
                (s.artist?.toLowerCase().contains(q) ?? false);
          }).toList();

    list = List.of(list)..sort((a, b) {
      final cmp = _sortCriteria == SongSortCriteria.title
          ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
          : (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0);
      return _sortOrder == SortOrder.ascending ? cmp : -cmp;
    });

    return list;
  }

  List<SongModel> get favoriteSongs =>
      songs.where((s) => _favorites.contains(s.id)).toList();

  List<CustomPlaylist> get playlists => List.unmodifiable(_playlists);

  bool isFavorite(int songId) => _favorites.contains(songId);

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();
      _loadPreferences();

      _hasPermission = await _libraryService
          .checkAndRequestPermissions()
          .timeout(const Duration(seconds: 8), onTimeout: () => false);
      if (_hasPermission) {
        await refreshSongs();
        await _loadUserData();
      }
    } catch (e) {
      debugPrint('Library init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadPreferences() {
    final p = _prefs;
    if (p == null) return;
    _searchQuery = p.getString('searchQuery') ?? '';
    _sortCriteria = SongSortCriteria.values.firstWhere(
      (e) => e.name == p.getString('sortCriteria'),
      orElse: () => SongSortCriteria.title,
    );
    _sortOrder = SortOrder.values.firstWhere(
      (e) => e.name == p.getString('sortOrder'),
      orElse: () => SortOrder.ascending,
    );
  }

  Future<void> _savePreferences() async {
    final p = _prefs;
    if (p == null) return;
    await Future.wait([
      p.setString('searchQuery', _searchQuery),
      p.setString('sortCriteria', _sortCriteria.name),
      p.setString('sortOrder', _sortOrder.name),
    ]);
  }

  Future<void> refreshSongs() async {
    try {
      _allSongs = await _libraryService.fetchSongs();
      notifyListeners();
    } catch (e) {
      debugPrint('refreshSongs error: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final favList = await _dbService.getFavorites();
      _favorites = favList.toSet();

      final pList = await _dbService.getPlaylists();
      final playlists = <CustomPlaylist>[];
      for (final p in pList) {
        final songIds = await _dbService.getPlaylistSongs(p['id'] as int);
        final pSongs =
            _allSongs.where((s) => songIds.contains(s.id)).toList();
        playlists.add(
          CustomPlaylist(id: p['id'] as int, name: p['name'] as String, songs: pSongs),
        );
      }
      _playlists = playlists;
      notifyListeners();
    } catch (e) {
      debugPrint('loadUserData error: $e');
    }
  }

  // ── Search & Sort ──────────────────────────────────────────────────────────

  Future<void> setSearchQuery(String query) async {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> setSortCriteria(SongSortCriteria criteria) async {
    if (_sortCriteria == criteria) return;
    _sortCriteria = criteria;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> setSortOrder(SortOrder order) async {
    if (_sortOrder == order) return;
    _sortOrder = order;
    notifyListeners();
    await _savePreferences();
  }

  // ── Favorites ──────────────────────────────────────────────────────────────

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

  // ── Playlists ──────────────────────────────────────────────────────────────

  Future<void> createPlaylist(String name) async {
    final id = await _dbService.createPlaylist(name);
    _playlists.add(CustomPlaylist(id: id, name: name));
    notifyListeners();
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    await _dbService.addSongToPlaylist(playlistId, songId);
    await _loadUserData();
  }

  Future<void> deletePlaylist(int id) async {
    await _dbService.deletePlaylist(id);
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ── Song Deletion ──────────────────────────────────────────────────────────

  Future<void> deleteSongFromDevice(SongModel song) async {
    final deleted = await _libraryService.deleteSong(song);
    if (deleted) {
      _allSongs.removeWhere((s) => s.id == song.id);
      _favorites.remove(song.id);
      await _dbService.removeFavorite(song.id);
      notifyListeners();
    }
    // Re-sync with MediaStore to reflect true on-disk state
    await refreshSongs();
  }
}
