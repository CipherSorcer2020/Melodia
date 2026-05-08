import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../services/audio_handler.dart';

class AudioProvider with ChangeNotifier {
  final MelodiaAudioHandler _audioHandler;
  SongModel? _currentSong;
  List<SongModel> _playlist = [];

  late final StreamSubscription _playbackSub;
  late final StreamSubscription _mediaItemSub;

  AudioProvider(this._audioHandler) {
    _playbackSub = _audioHandler.playbackState.listen((_) {
      notifyListeners();
    });

    _mediaItemSub = _audioHandler.mediaItem.listen((item) {
      if (item == null || _playlist.isEmpty) return;
      final id = item.extras?['id'];
      if (id == null) return;
      final match = _playlist.where((s) => s.id == id).firstOrNull;
      if (match != null) _currentSong = match;
      notifyListeners();
    });
  }

  SongModel? get currentSong => _currentSong;

  bool get isPlaying => _audioHandler.playbackState.value.playing;

  Duration get duration =>
      _audioHandler.mediaItem.value?.duration ?? Duration.zero;

  Stream<Duration> get positionStream => _audioHandler.positionStream;

  bool get isShuffled =>
      _audioHandler.playbackState.value.shuffleMode ==
      AudioServiceShuffleMode.all;

  AudioServiceRepeatMode get repeatMode =>
      _audioHandler.playbackState.value.repeatMode;

  Future<void> playPlaylist(List<SongModel> songs, int initialIndex) async {
    if (songs.isEmpty) return;
    final valid = songs.where((s) => s.uri != null).toList();
    if (valid.isEmpty) return;
    final safeIndex = initialIndex.clamp(0, valid.length - 1);

    _playlist = valid;
    _currentSong = valid[safeIndex];
    notifyListeners();

    await _audioHandler.setInitialPlaylist(valid, safeIndex);
    await _audioHandler.play();
  }

  Future<void> pause() async {
    try { await _audioHandler.pause(); } catch (e) { debugPrint('pause: $e'); }
  }

  Future<void> resume() async {
    try { await _audioHandler.play(); } catch (e) { debugPrint('resume: $e'); }
  }

  Future<void> skipToNext() async {
    try { await _audioHandler.skipToNext(); } catch (e) { debugPrint('skipNext: $e'); }
  }

  Future<void> skipToPrevious() async {
    try { await _audioHandler.skipToPrevious(); } catch (e) { debugPrint('skipPrev: $e'); }
  }

  Future<void> seek(Duration position) async {
    try { await _audioHandler.seek(position); } catch (e) { debugPrint('seek: $e'); }
  }

  Future<void> toggleShuffle() async {
    final next = isShuffled
        ? AudioServiceShuffleMode.none
        : AudioServiceShuffleMode.all;
    await _audioHandler.setShuffleMode(next);
  }

  Future<void> nextRepeatMode() async {
    final next = switch (repeatMode) {
      AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
      _ => AudioServiceRepeatMode.none,
    };
    await _audioHandler.setRepeatMode(next);
  }

  Future<void> stop() async {
    try { await _audioHandler.stop(); } catch (e) { debugPrint('stop: $e'); }
  }

  @override
  void dispose() {
    _playbackSub.cancel();
    _mediaItemSub.cancel();
    super.dispose();
  }
}
