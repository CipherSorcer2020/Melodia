import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final song = audio.currentSong;

    if (song == null) return const SizedBox.shrink();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 40),
          // Album Art - Extracted to prevent reloads on slider drag
          const PlayerArtwork(),
          const Spacer(),
          // Song Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 48), // Spacer to balance the favorite button
              Expanded(
                child: Column(
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.artist ?? 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Consumer<LibraryProvider>(
                builder: (context, library, child) {
                  final isFav = library.isFavorite(song.id);
                  return IconButton(
                    iconSize: 32,
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? Colors.red : null,
                    ),
                    onPressed: () => library.toggleFavorite(song.id),
                  );
                },
              ),
            ],
          ),
          const Spacer(),
          // Progress Bar - Separated state to prevent full screen rebuild
          const PlayerProgressBar(),
          const Spacer(),
          // Controls
          const PlayerControls(),
          const Spacer(),
        ],
      ),
    );
  }
}

class PlayerArtwork extends StatelessWidget {
  const PlayerArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    // We only select the song ID so this widget only rebuilds when the song changes,
    // NOT when the position/slider changes.
    final songId = context.select<AudioProvider, int?>((a) => a.currentSong?.id);

    if (songId == null) return const SizedBox.shrink();

    return Center(
      child: Hero(
        tag: 'artwork',
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.width * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: QueryArtworkWidget(
              id: songId,
              type: ArtworkType.AUDIO,
              artworkWidth: double.infinity,
              artworkHeight: double.infinity,
              nullArtworkWidget: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  LineIcons.music,
                  size: 100,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerProgressBar extends StatelessWidget {
  const PlayerProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final duration = audio.duration;
    
    return StreamBuilder<Duration>(
      stream: audio.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        
        return Column(
          children: [
            Slider(
              value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
              max: duration.inSeconds.toDouble() == 0 ? 1 : duration.inSeconds.toDouble(),
              onChanged: (value) {
                audio.seek(Duration(seconds: value.toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position)),
                  Text(_formatDuration(duration)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          iconSize: 28,
          icon: Icon(
            Icons.shuffle,
            color: audio.isShuffled 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          onPressed: () => audio.toggleShuffle(),
        ),
        IconButton(
          iconSize: 40,
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: () => audio.skipToPrevious(),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            iconSize: 56,
            color: Theme.of(context).colorScheme.onPrimary,
            icon: Icon(audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            onPressed: () {
              if (audio.isPlaying) {
                audio.pause();
              } else {
                audio.resume();
              }
            },
          ),
        ),
        IconButton(
          iconSize: 40,
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: () => audio.skipToNext(),
        ),
        IconButton(
          iconSize: 28,
          icon: Icon(
            _getRepeatIcon(audio.repeatMode),
            color: audio.repeatMode != AudioServiceRepeatMode.none 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          onPressed: () => audio.nextRepeatMode(),
        ),
      ],
    );
  }

  IconData _getRepeatIcon(AudioServiceRepeatMode mode) {
    return switch (mode) {
      AudioServiceRepeatMode.one => Icons.repeat_one_rounded,
      _ => Icons.repeat_rounded,
    };
  }
}
