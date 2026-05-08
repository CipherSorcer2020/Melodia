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

    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.92,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.primaryContainer.withValues(alpha: 0.75),
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor,
          ],
          stops: const [0.0, 0.38, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                ),
                Expanded(
                  child: Text(
                    'NOW PLAYING',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: cs.primary,
                    ),
                  ),
                ),
                Consumer<LibraryProvider>(
                  builder: (context, library, _) {
                    final isFav = library.isFavorite(song.id);
                    return IconButton(
                      icon: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav ? cs.secondary : null,
                        size: 26,
                      ),
                      onPressed: () => library.toggleFavorite(song.id),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Artwork
          const Expanded(child: _PlayerArtwork()),
          const SizedBox(height: 28),
          // Song info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  song.artist ?? 'Unknown Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Progress bar
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: _PlayerProgressBar(),
          ),
          const SizedBox(height: 12),
          // Controls
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _PlayerControls(),
          ),
          const SizedBox(height: 28),
          // Safe area spacing
          SafeArea(top: false, child: const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _PlayerArtwork extends StatelessWidget {
  const _PlayerArtwork();

  @override
  Widget build(BuildContext context) {
    final songId = context.select<AudioProvider, int?>((a) => a.currentSong?.id);
    if (songId == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Hero(
        tag: 'artwork_$songId',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.4),
                blurRadius: 50,
                spreadRadius: -8,
                offset: const Offset(0, 24),
              ),
              BoxShadow(
                color: cs.secondary.withValues(alpha: 0.2),
                blurRadius: 70,
                spreadRadius: -12,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: AspectRatio(
              aspectRatio: 1,
              child: QueryArtworkWidget(
                id: songId,
                type: ArtworkType.AUDIO,
                artworkWidth: double.infinity,
                artworkHeight: double.infinity,
                artworkBorder: BorderRadius.zero,
                nullArtworkWidget: Container(
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
                  child: Icon(
                    LineIcons.music,
                    size: 80,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerProgressBar extends StatelessWidget {
  const _PlayerProgressBar();

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final duration = audio.duration;
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<Duration>(
      stream: audio.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: cs.primary,
                inactiveTrackColor: cs.primary.withValues(alpha: 0.18),
                thumbColor: Colors.white,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 4,
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 18),
              ),
              child: Slider(
                value: position.inSeconds
                    .toDouble()
                    .clamp(0, duration.inSeconds.toDouble()),
                max: duration.inSeconds > 0
                    ? duration.inSeconds.toDouble()
                    : 1,
                onChanged: (v) => audio.seek(Duration(seconds: v.toInt())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(position),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    _fmt(duration),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _fmt(Duration d) {
    String dd(int n) => n.toString().padLeft(2, '0');
    return '${dd(d.inMinutes.remainder(60))}:${dd(d.inSeconds.remainder(60))}';
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls();

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Shuffle
        _ModeButton(
          icon: Icons.shuffle_rounded,
          isActive: audio.isShuffled,
          onTap: audio.toggleShuffle,
        ),
        // Skip previous
        IconButton(
          iconSize: 34,
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: audio.skipToPrevious,
        ),
        // Play / Pause — gradient circle
        GestureDetector(
          onTap: () => audio.isPlaying ? audio.pause() : audio.resume(),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.secondary],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              audio.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
        ),
        // Skip next
        IconButton(
          iconSize: 34,
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: audio.skipToNext,
        ),
        // Repeat
        _ModeButton(
          icon: _repeatIcon(audio.repeatMode),
          isActive: audio.repeatMode != AudioServiceRepeatMode.none,
          onTap: audio.nextRepeatMode,
        ),
      ],
    );
  }

  IconData _repeatIcon(AudioServiceRepeatMode mode) => switch (mode) {
        AudioServiceRepeatMode.one => Icons.repeat_one_rounded,
        _ => Icons.repeat_rounded,
      };
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton(
      {required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      iconSize: 24,
      icon: Icon(
        icon,
        color: isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.35),
      ),
      onPressed: onTap,
    );
  }
}
