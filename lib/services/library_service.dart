import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class LibraryService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<bool> checkAndRequestPermissions() async {
    // on_audio_query has its own permission check
    bool status = await _audioQuery.permissionsStatus();
    if (!status) {
      status = await _audioQuery.permissionsRequest();
    }
    
    // As a fallback or for more control, use permission_handler
    if (!status) {
      if (await Permission.audio.request().isGranted || 
          await Permission.storage.request().isGranted) {
        return true;
      }
    }
    
    return status;
  }

  Future<List<SongModel>> fetchSongs() async {
    return await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }

  Future<List<AlbumModel>> fetchAlbums() async {
    return await _audioQuery.queryAlbums(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }

  Future<bool> deleteSong(int id) async {
    // Note: On Android 10+, this will throw an exception or return false 
    // because scoped storage requires a specific Intent for deletion.
    // For now we try via on_audio_query.
    // However, on_audio_query 2.x doesn't directly delete from storage easily.
    // Most apps use File(path).delete() but that requires extra permissions.
    // We'll return false for now to indicate it's complex on modern Android
    // without a custom implementation.
    return false;
  }
}
