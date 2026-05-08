import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class LibraryService {
  static const _channel = MethodChannel('com.melodia.app/media_store');
  final _audioQuery = OnAudioQuery();

  Future<bool> checkAndRequestPermissions() async {
    try {
      bool granted = await _audioQuery.permissionsStatus();
      if (!granted) granted = await _audioQuery.permissionsRequest();
      if (!granted) {
        granted = await Permission.audio.request().isGranted ||
            await Permission.storage.request().isGranted;
      }
      return granted;
    } catch (e) {
      debugPrint('Permission check error: $e');
      return false;
    }
  }

  Future<List<SongModel>> fetchSongs() async {
    try {
      final all = await _audioQuery
          .querySongs(
            sortType: null,
            orderType: OrderType.ASC_OR_SMALLER,
            uriType: UriType.EXTERNAL,
            ignoreCase: true,
          )
          .timeout(const Duration(seconds: 12), onTimeout: () => []);
      // Keep only playable songs: valid URI, at least 10 s (filters ringtones/notifications)
      return all
          .where((s) => s.uri != null && (s.duration ?? 0) >= 10000)
          .toList();
    } catch (e) {
      debugPrint('fetchSongs error: $e');
      return [];
    }
  }

  Future<bool> deleteSong(SongModel song) async {
    final uri = song.uri;
    if (uri == null) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('deleteMediaStoreFile', {'uri': uri});
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('MediaStore delete error: ${e.message}');
      return false;
    }
  }
}
