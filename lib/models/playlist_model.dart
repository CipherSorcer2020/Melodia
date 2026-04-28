import 'package:on_audio_query/on_audio_query.dart';

class CustomPlaylist {
  final int id;
  final String name;
  final List<SongModel> songs;

  CustomPlaylist({
    required this.id,
    required this.name,
    this.songs = const [],
  });

  CustomPlaylist copyWith({
    int? id,
    String? name,
    List<SongModel>? songs,
  }) {
    return CustomPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      songs: songs ?? this.songs,
    );
  }
}
