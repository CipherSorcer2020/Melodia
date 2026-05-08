import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MelodiaAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  static const _loopToRepeat = {
    LoopMode.off: AudioServiceRepeatMode.none,
    LoopMode.one: AudioServiceRepeatMode.one,
    LoopMode.all: AudioServiceRepeatMode.all,
  };

  static const _processingStateMap = {
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  MelodiaAudioHandler() {
    // Use listen instead of pipe so stream errors don't close the sink
    _player.playbackEventStream.listen(
      (event) {
        try {
          playbackState.add(_transformEvent(event));
        } catch (e) {
          debugPrint('Playback state transform error: $e');
        }
      },
      onError: (e) => debugPrint('Playback stream error: $e'),
    );

    _player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // Auto-advance handled by just_audio in playlist mode
      }
    });
  }

  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() async {
    final index = _player.currentIndex ?? 0;
    if (index > 0) {
      await _player.seek(Duration.zero, index: index - 1);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final loopMode = switch (repeatMode) {
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all => LoopMode.all,
      AudioServiceRepeatMode.group => LoopMode.all,
      _ => LoopMode.off,
    };
    await _player.setLoopMode(loopMode);
    playbackState.add(
      playbackState.value.copyWith(
        repeatMode: _loopToRepeat[_player.loopMode] ?? AudioServiceRepeatMode.none,
      ),
    );
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(
      shuffleMode != AudioServiceShuffleMode.none,
    );
  }

  Future<void> setInitialPlaylist(List<SongModel> songs, int initialIndex) async {
    // Only keep songs with valid URIs
    final valid = songs.where((s) => s.uri != null).toList();
    if (valid.isEmpty) return;
    final safeIndex = initialIndex.clamp(0, valid.length - 1);

    final mediaItems = valid
        .map((s) => MediaItem(
              id: s.uri!,
              title: s.title,
              artist: s.artist,
              album: s.album,
              duration: Duration(milliseconds: s.duration ?? 0),
              extras: {'id': s.id},
            ))
        .toList();

    queue.add(mediaItems);

    try {
      final sources = valid
          .map((s) => AudioSource.uri(Uri.parse(s.uri!)))
          .toList();
      await _player.setAudioSources(sources, initialIndex: safeIndex);
    } catch (e) {
      debugPrint('setAudioSources error: $e');
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {}

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.setShuffleMode,
        MediaAction.setRepeatMode,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: _processingStateMap[_player.processingState] ??
          AudioProcessingState.idle,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
      shuffleMode: _player.shuffleModeEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      repeatMode:
          _loopToRepeat[_player.loopMode] ?? AudioServiceRepeatMode.none,
    );
  }
}
