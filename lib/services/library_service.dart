import 'dart:io'; // Add this import

import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart'; // Add this import

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

  Future<bool> deleteSong(SongModel song) async {
    try {
      if (song.data != null) {
        final file = File(song.data!);
        if (await file.exists()) {
          await file.delete();
          // Optionally, you might also want to try removing from MediaStore
          // _audioQuery.queryRemoveMedia(song.id); // This method usually removes from DB not actual file
          return true; // Physical file deleted
        }
      }
      return false; // File path not available or file doesn't exist
    } catch (e) {
      debugPrint('Error deleting file: ${song.data} - $e');
      // On Android 10+, this will often fail due to scoped storage.
      // A more robust solution would involve MediaStore.createDeleteRequest()
      return false;
    }
  }
}
