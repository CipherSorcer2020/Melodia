import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../models/playlist_model.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _searchBarVisible = false;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.text = context.read<LibraryProvider>().searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: _buildAppBar(cs),
      body: Column(
        children: [
          _buildTabBar(cs),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [SongsTab(), FavoritesTab(), PlaylistsTab()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme cs) {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primary.withValues(alpha: 0.12), cs.surface],
          ),
        ),
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _searchBarVisible
            ? TextField(
                key: const ValueKey('search'),
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search songs…',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: Colors.white.withValues(alpha: 0.6)),
                    onPressed: () {
                      _searchController.clear();
                      context.read<LibraryProvider>().setSearchQuery('');
                    },
                  ),
                ),
                autofocus: true,
                onChanged: (q) =>
                    context.read<LibraryProvider>().setSearchQuery(q),
              )
            : Row(
                key: const ValueKey('title'),
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.music_note_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [cs.primary, cs.secondary],
                    ).createShader(bounds),
                    child: const Text(
                      'Melodia',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        IconButton(
          icon: Icon(
              _searchBarVisible ? Icons.close_rounded : Icons.search_rounded),
          onPressed: () => setState(() {
            _searchBarVisible = !_searchBarVisible;
            if (!_searchBarVisible) {
              _searchController.clear();
              context.read<LibraryProvider>().setSearchQuery('');
            }
          }),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<LibraryProvider>().refreshSongs(),
        ),
        Consumer<LibraryProvider>(
          builder: (context, library, child) {
            return PopupMenuButton<String>(
              icon: const Icon(Icons.sort_rounded),
              onSelected: (value) {
                switch (value) {
                  case 'title_asc':
                    library.setSortCriteria(SongSortCriteria.title);
                    library.setSortOrder(SortOrder.ascending);
                  case 'title_desc':
                    library.setSortCriteria(SongSortCriteria.title);
                    library.setSortOrder(SortOrder.descending);
                  case 'date_asc':
                    library.setSortCriteria(SongSortCriteria.dateAdded);
                    library.setSortOrder(SortOrder.ascending);
                  case 'date_desc':
                    library.setSortCriteria(SongSortCriteria.dateAdded);
                    library.setSortOrder(SortOrder.descending);
                }
              },
              itemBuilder: (_) => [
                _sortItem('title_asc', 'Title (A–Z)', library),
                _sortItem('title_desc', 'Title (Z–A)', library),
                _sortItem('date_asc', 'Oldest First', library),
                _sortItem('date_desc', 'Newest First', library),
              ],
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  PopupMenuItem<String> _sortItem(
      String value, String label, LibraryProvider library) {
    final active = switch (value) {
      'title_asc' => library.sortCriteria == SongSortCriteria.title &&
          library.sortOrder == SortOrder.ascending,
      'title_desc' => library.sortCriteria == SongSortCriteria.title &&
          library.sortOrder == SortOrder.descending,
      'date_asc' => library.sortCriteria == SongSortCriteria.dateAdded &&
          library.sortOrder == SortOrder.ascending,
      'date_desc' => library.sortCriteria == SongSortCriteria.dateAdded &&
          library.sortOrder == SortOrder.descending,
      _ => false,
    };
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            active ? Icons.check_rounded : Icons.sort_rounded,
            size: 16,
            color: active
                ? Theme.of(context).colorScheme.primary
                : Colors.white30,
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs) {
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            dividerHeight: 0,
            indicator: BoxDecoration(
              gradient:
                  LinearGradient(colors: [cs.primary, cs.secondary]),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: cs.onSurface.withValues(alpha: 0.45),
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12.5),
            unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 12.5),
            tabs: [
              Tab(text: 'Songs (${library.songs.length})'),
              Tab(text: 'Favorites (${library.favoriteSongs.length})'),
              const Tab(text: 'Playlists'),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Tabs  (StatefulWidget + AutomaticKeepAliveClientMixin → no re-render on switch)
// ──────────────────────────────────────────────────────────────────────────────

class SongsTab extends StatefulWidget {
  const SongsTab({super.key});
  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        if (library.isLoading) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2.5,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading your music…',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }
        if (library.songs.isEmpty) {
          return _EmptyState(
            icon: Icons.music_note_rounded,
            message: library.searchQuery.isEmpty
                ? 'No songs found on your device'
                : 'No results for "${library.searchQuery}"',
          );
        }
        final songs = library.songs;
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 8),
          itemCount: songs.length,
          itemBuilder: (context, index) => RepaintBoundary(
            child: SongTile(
              song: songs[index],
              playlist: songs,
              index: index,
            ),
          ),
        );
      },
    );
  }
}

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});
  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        final favorites = library.favoriteSongs;
        if (favorites.isEmpty) {
          return const _EmptyState(
            icon: Icons.favorite_rounded,
            message: 'No favorites yet\nTap ♡ on any song to save it here',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 8),
          itemCount: favorites.length,
          itemBuilder: (context, index) => RepaintBoundary(
            child: SongTile(
              song: favorites[index],
              playlist: favorites,
              index: index,
            ),
          ),
        );
      },
    );
  }
}

class PlaylistsTab extends StatefulWidget {
  const PlaylistsTab({super.key});
  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        final playlists = library.playlists;
        final cs = Theme.of(context).colorScheme;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: playlists.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _showCreateDialog(context, library),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        cs.primary.withValues(alpha: 0.18),
                        cs.secondary.withValues(alpha: 0.1),
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: cs.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [cs.primary, cs.secondary]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Create New Playlist',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final playlist = playlists[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(Icons.queue_music_rounded, color: cs.primary),
                  ),
                  title: Text(playlist.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${playlist.songs.length} songs',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.45),
                        fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: cs.error.withValues(alpha: 0.75)),
                    onPressed: () =>
                        _confirmDelete(context, library, playlist),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  onTap: () => _showDetail(context, playlist),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, LibraryProvider library,
      CustomPlaylist playlist) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Playlist?'),
        content: Text('Delete "${playlist.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              library.deletePlaylist(playlist.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, LibraryProvider library) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            prefixIcon: Icon(Icons.playlist_play_rounded),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                library.createPlaylist(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, CustomPlaylist playlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(playlist.name)),
        body: playlist.songs.isEmpty
            ? const _EmptyState(
                icon: Icons.playlist_play_rounded,
                message: 'No songs in this playlist yet',
              )
            : ListView.builder(
                itemCount: playlist.songs.length,
                itemBuilder: (context, index) => RepaintBoundary(
                  child: SongTile(
                    song: playlist.songs[index],
                    playlist: playlist.songs,
                    index: index,
                  ),
                ),
              ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Song Tile
// ──────────────────────────────────────────────────────────────────────────────

class SongTile extends StatelessWidget {
  final SongModel song;
  final List<SongModel> playlist;
  final int index;

  const SongTile({
    super.key,
    required this.song,
    required this.playlist,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPlaying = context.select<AudioProvider, bool>(
      (a) => a.currentSong?.id == song.id,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: isPlaying
            ? cs.primary.withValues(alpha: 0.13)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            context.read<AudioProvider>().playPlaylist(playlist, index);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const PlayerScreen(),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                // Artwork
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          artworkWidth: 50,
                          artworkHeight: 50,
                          nullArtworkWidget: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cs.primaryContainer,
                                  cs.secondaryContainer,
                                ],
                              ),
                            ),
                            child: Icon(Icons.music_note_rounded,
                                color: cs.onPrimaryContainer, size: 24),
                          ),
                        ),
                      ),
                    ),
                    if (isPlaying)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            color: cs.primary.withValues(alpha: 0.55),
                            child: const Icon(Icons.graphic_eq_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isPlaying ? cs.primary : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        song.artist ?? 'Unknown Artist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                _SongOptionsButton(song: song),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Song Options Menu
// ──────────────────────────────────────────────────────────────────────────────

class _SongOptionsButton extends StatelessWidget {
  final SongModel song;
  const _SongOptionsButton({required this.song});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        final isFav = library.isFavorite(song.id);
        final cs = Theme.of(context).colorScheme;

        return PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded,
              color: cs.onSurface.withValues(alpha: 0.4), size: 20),
          onSelected: (value) {
            switch (value) {
              case 'play':
                context.read<AudioProvider>().playPlaylist([song], 0);
              case 'fav':
                library.toggleFavorite(song.id);
              case 'add_playlist':
                _showAddToPlaylist(context, library);
              case 'delete':
                _showDeleteDialog(context, library);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'play',
              child: Row(children: [
                Icon(Icons.play_arrow_rounded),
                SizedBox(width: 10),
                Text('Play'),
              ]),
            ),
            PopupMenuItem(
              value: 'fav',
              child: Row(children: [
                Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? Colors.pinkAccent : null,
                ),
                const SizedBox(width: 10),
                Text(isFav ? 'Remove Favorite' : 'Add to Favorites'),
              ]),
            ),
            const PopupMenuItem(
              value: 'add_playlist',
              child: Row(children: [
                Icon(Icons.playlist_add_rounded),
                SizedBox(width: 10),
                Text('Add to Playlist'),
              ]),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 10),
                Text('Delete from Device',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ]),
            ),
          ],
        );
      },
    );
  }

  void _showAddToPlaylist(BuildContext context, LibraryProvider library) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: library.playlists.isEmpty
            ? const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('No playlists yet. Create one first.'),
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: library.playlists
                      .map((p) => ListTile(
                            leading:
                                const Icon(Icons.queue_music_rounded),
                            title: Text(p.name),
                            onTap: () {
                              library.addSongToPlaylist(p.id, song.id);
                              Navigator.pop(context);
                            },
                          ))
                      .toList(),
                ),
              ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, LibraryProvider library) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Song?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${song.title}"',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'This will permanently delete the file from your device.',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Navigator.pop(context);
              library.deleteSongFromDevice(song);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
            ),
            child:
                Icon(icon, size: 38, color: cs.primary.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 18),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.45),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Mini Player
// ──────────────────────────────────────────────────────────────────────────────

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, child) {
        final song = audio.currentSong;
        if (song == null) return const SizedBox.shrink();

        final cs = Theme.of(context).colorScheme;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withValues(alpha: 0.28),
                    cs.secondary.withValues(alpha: 0.18),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: cs.primary.withValues(alpha: 0.22)),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Progress strip
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: StreamBuilder<Duration>(
                      stream: audio.positionStream,
                      builder: (context, snapshot) {
                        final pos = snapshot.data ?? Duration.zero;
                        final dur = audio.duration;
                        final progress = dur.inMilliseconds > 0
                            ? (pos.inMilliseconds / dur.inMilliseconds)
                                .clamp(0.0, 1.0)
                            : 0.0;
                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: Stack(children: [
                            Container(
                                height: 3,
                                color: cs.primary.withValues(alpha: 0.12)),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [cs.primary, cs.secondary]),
                                ),
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
                  // Row
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const PlayerScreen(),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: QueryArtworkWidget(
                              id: song.id,
                              type: ArtworkType.AUDIO,
                              artworkWidth: 48,
                              artworkHeight: 48,
                              nullArtworkWidget: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [cs.primary, cs.secondary]),
                                ),
                                child: const Icon(Icons.music_note_rounded,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist ?? 'Unknown Artist',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface
                                        .withValues(alpha: 0.55)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded),
                          onPressed: audio.skipToPrevious,
                          iconSize: 22,
                        ),
                        IconButton(
                          icon: Icon(audio.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                          onPressed: () => audio.isPlaying
                              ? audio.pause()
                              : audio.resume(),
                          iconSize: 26,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          onPressed: audio.skipToNext,
                          iconSize: 22,
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
