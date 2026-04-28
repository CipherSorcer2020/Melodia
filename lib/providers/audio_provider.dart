import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../services/audio_handler.dart';

class AudioProvider with ChangeNotifier {
  final MelodiaAudioHandler _audioHandler;
  SongModel? _currentSong;
  List<SongModel> _playlist = [];
  
  AudioProvider(this._audioHandler) {
    _audioHandler.playbackState.listen((state) {
      notifyListeners();
    });
    
    _audioHandler.mediaItem.listen((item) {
      if (item != null && _playlist.isNotEmpty) {
        final id = item.extras?['id'];
        if (id != null) {
          try {
            _currentSong = _playlist.firstWhere((s) => s.id == id);
          } catch (e) {
            // Song might not be in current playlist
          }
        }
      }
      notifyListeners();
    });
  }

  SongModel? get currentSong => _currentSong;
  bool get isPlaying => _audioHandler.playbackState.value.playing;
  Duration get duration => _audioHandler.mediaItem.value?.duration ?? Duration.zero;
  
  Stream<Duration> get positionStream => _audioHandler.positionStream;
  
  bool get isShuffled => _audioHandler.playbackState.value.shuffleMode == AudioServiceShuffleMode.all;
  AudioServiceRepeatMode get repeatMode => _audioHandler.playbackState.value.repeatMode;

  Future<void> playPlaylist(List<SongModel> songs, int initialIndex) async {
    _playlist = songs;
    _currentSong = songs[initialIndex];
    await _audioHandler.setInitialPlaylist(songs, initialIndex);
    await _audioHandler.play();
    notifyListeners();
  }

  Future<void> pause() => _audioHandler.pause();
  Future<void> resume() => _audioHandler.play();
  Future<void> skipToNext() => _audioHandler.skipToNext();
  Future<void> skipToPrevious() => _audioHandler.skipToPrevious();
  
  Future<void> toggleShuffle() async {
    final newMode = isShuffled ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all;
    await _audioHandler.setShuffleMode(newMode);
  }

  Future<void> nextRepeatMode() async {
    final nextMode = switch (repeatMode) {
      AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
      _ => AudioServiceRepeatMode.none,
    };
    await _audioHandler.setRepeatMode(nextMode);
  }

  Future<void> stop() => _audioHandler.stop();
  Future<void> seek(Duration position) => _audioHandler.seek(position);
}
