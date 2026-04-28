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

class _HomeScreenState extends State<HomeScreen> {
  bool _searchBarVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<LibraryProvider>().searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: _searchBarVisible
              ? TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search songs...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<LibraryProvider>().setSearchQuery('');
                      },
                    ),
                  ),
                  autofocus: true,
                  onChanged: (query) => context.read<LibraryProvider>().setSearchQuery(query),
                )
              : const Text('Melodia', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(_searchBarVisible ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _searchBarVisible = !_searchBarVisible;
                  if (!_searchBarVisible) {
                    _searchController.clear();
                    context.read<LibraryProvider>().setSearchQuery('');
                  }
                });
              },
            ),
            IconButton(
              onPressed: () => context.read<LibraryProvider>().refreshSongs(),
              icon: const Icon(Icons.refresh_rounded),
            ),
            Consumer<LibraryProvider>(
              builder: (context, library, child) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  onSelected: (value) {
                    if (value == 'title_asc') {
                      library.setSortCriteria(SongSortCriteria.title);
                      library.setSortOrder(SortOrder.ascending);
                    } else if (value == 'title_desc') {
                      library.setSortCriteria(SongSortCriteria.title);
                      library.setSortOrder(SortOrder.descending);
                    } else if (value == 'date_added_asc') {
                      library.setSortCriteria(SongSortCriteria.dateAdded);
                      library.setSortOrder(SortOrder.ascending);
                    } else if (value == 'date_added_desc') {
                      library.setSortCriteria(SongSortCriteria.dateAdded);
                      library.setSortOrder(SortOrder.descending);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'title_asc',
                      child: Text('Title (A-Z)'),
                      textStyle: TextStyle(
                        fontWeight: library.sortCriteria == SongSortCriteria.title && library.sortOrder == SortOrder.ascending
                            ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'title_desc',
                      child: Text('Title (Z-A)'),
                      textStyle: TextStyle(
                        fontWeight: library.sortCriteria == SongSortCriteria.title && library.sortOrder == SortOrder.descending
                            ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'date_added_asc',
                      child: Text('Date Added (Oldest first)'),
                      textStyle: TextStyle(
                        fontWeight: library.sortCriteria == SongSortCriteria.dateAdded && library.sortOrder == SortOrder.ascending
                            ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'date_added_desc',
                      child: Text('Date Added (Newest first)'),
                      textStyle: TextStyle(
                        fontWeight: library.sortCriteria == SongSortCriteria.dateAdded && library.sortOrder == SortOrder.descending
                            ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                child: Consumer<LibraryProvider>(
                  builder: (context, library, child) => Text('Songs (${library.songs.length})'),
                ),
              ),
              Tab(
                child: Consumer<LibraryProvider>(
                  builder: (context, library, child) => Text('Favorites (${library.favoriteSongs.length})'),
                ),
              ),
              const Tab(text: 'Playlists'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SongsTab(),
            FavoritesTab(),
            PlaylistsTab(),
          ],
        ),
        bottomNavigationBar: const MiniPlayer(),
      ),
    );
  }
}

class SongsTab extends StatelessWidget {
  const SongsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        if (library.isLoading) return const Center(child: CircularProgressIndicator());
        if (library.songs.isEmpty) return const Center(child: Text('No songs found'));

        return ListView.builder(
          itemCount: library.songs.length,
          itemBuilder: (context, index) {
            final song = library.songs[index];
            return SongTile(song: song, playlist: library.songs, index: index);
          },
        );
      },
    );
  }
}

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        final favorites = library.favoriteSongs;
        if (favorites.isEmpty) return const Center(child: Text('No favorites yet'));

        return ListView.builder(
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final song = favorites[index];
            return SongTile(song: song, playlist: favorites, index: index);
          },
        );
      },
    );
  }
}

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        final playlists = library.playlists;
        
        return ListView.builder(
          itemCount: playlists.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                leading: const Icon(Icons.add_box_rounded, size: 40),
                title: const Text('Create New Playlist'),
                onTap: () => _showCreatePlaylistDialog(context, library),
              );
            }
            
            final playlist = playlists[index - 1];
            return ListTile(
              leading: const Icon(Icons.playlist_play_rounded, size: 40),
              title: Text(playlist.name),
              subtitle: Text('${playlist.songs.length} songs'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => library.deletePlaylist(playlist.id),
              ),
              onTap: () => _showPlaylistDetail(context, playlist),
            );
          },
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, LibraryProvider library) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Playlist Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                library.createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistDetail(BuildContext context, CustomPlaylist playlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(playlist.name)),
        body: playlist.songs.isEmpty 
          ? const Center(child: Text('No songs in this playlist'))
          : ListView.builder(
              itemCount: playlist.songs.length,
              itemBuilder: (context, index) {
                return SongTile(song: playlist.songs[index], playlist: playlist.songs, index: index);
              },
            ),
      ),
    );
  }
}

class SongTile extends StatelessWidget {
  final SongModel song;
  final List<SongModel> playlist;
  final int index;

  const SongTile({super.key, required this.song, required this.playlist, required this.index});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_note_rounded),
        ),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: _SongOptionsButton(song: song),
      onTap: () {
        context.read<AudioProvider>().playPlaylist(playlist, index);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const PlayerScreen(),
        );
      },
    );
  }
}

class _SongOptionsButton extends StatelessWidget {
  final SongModel song;
  const _SongOptionsButton({required this.song});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        final isFav = library.isFavorite(song.id);
        
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) async {
            switch (value) {
              case 'play':
                context.read<AudioProvider>().playPlaylist([song], 0);
                break;
              case 'fav':
                library.toggleFavorite(song.id);
                break;
              case 'add_playlist':
                _showAddToPlaylistDialog(context, library);
                break;
              case 'delete':
                _showDeleteDialog(context, library);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'play', child: Text('Play')),
            PopupMenuItem(value: 'fav', child: Text(isFav ? 'Remove Favorite' : 'Mark as Favorite')),
            const PopupMenuItem(value: 'add_playlist', child: Text('Add to Playlist')),
            const PopupMenuItem(value: 'delete', child: Text('Delete from Device')),
          ],
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, LibraryProvider library) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: library.playlists.map((p) => ListTile(
              title: Text(p.name),
              onTap: () {
                library.addSongToPlaylist(p.id, song.id);
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, LibraryProvider library) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('Remove this song from device?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            library.deleteSongFromDevice(song);
            Navigator.pop(context);
          }, child: const Text('Delete')),
        ],
      ),
    );
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, child) {
        if (audio.currentSong == null) return const SizedBox.shrink();

        return Container(
          height: 70,
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const PlayerScreen(),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: QueryArtworkWidget(
                    id: audio.currentSong!.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: Container(width: 45, height: 45, color: Colors.grey, child: const Icon(Icons.music_note)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(audio.currentSong!.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  icon: Icon(audio.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () => audio.isPlaying ? audio.pause() : audio.resume(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
