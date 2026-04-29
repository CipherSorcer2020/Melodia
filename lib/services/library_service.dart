import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/services.dart'; // Add this import

class LibraryService {
  static const MethodChannel _channel = MethodChannel('com.melodia.app/media_store'); // Define MethodChannel
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

  Future<bool> deleteSong(SongModel song) async {
    if (song.uri == null) {
      debugPrint('Song URI is null, cannot perform MediaStore deletion.');
      return false;
    }
    try {
      final bool? result = await _channel.invokeMethod(
        'deleteMediaStoreFile',
        {'uri': song.uri!},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to delete media using MediaStore: '${e.message}'.");
      return false;
    }
  }
}
