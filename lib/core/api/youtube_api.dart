import 'dart:io';
import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:riftwave_music/core/api/exceptions/api_exceptions.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';

class YouTubeApi extends GetxService {
  final YoutubeExplode _yt = YoutubeExplode();

  @override
  void onClose() {
    _yt.close();
    super.onClose();
  }

  Future<List<SongModel>> search(String query) async {
    try {
      final searchList = await _yt.search.search(query);
      final List<SongModel> songs = [];

      for (final video in searchList) {
        songs.add(
          SongModel(
            id: video.id.value,
            title: video.title,
            artist: video.author,
            album: 'YouTube',
            thumbnailUrl: video.thumbnails.highResUrl,
            audioUrl: '',
            durationMs: video.duration?.inMilliseconds ?? 0,
            source: MusicSource.youtube,
            sourceId: video.id.value,
          ),
        );
      }
      return songs;
    } on SocketException {
      throw NoInternetException();
    } on HttpException {
      throw NoInternetException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ParseException('YouTube Search Error: ${e.toString()}');
    }
  }

  Future<String> getStreamUrl(String videoId) async {
    try {
      StreamManifest manifest;
      try {
        manifest = await _yt.videos.streamsClient.getManifest(
          videoId,
          ytClients: [YoutubeApiClient.androidVr],
        );
      } catch (_) {
        manifest = await _yt.videos.streamsClient.getManifest(videoId);
      }

      final mp4Streams = manifest.audioOnly
          .where((stream) => stream.container.name == 'mp4')
          .toList();
      final audioStream = mp4Streams.isNotEmpty
          ? mp4Streams.withHighestBitrate()
          : manifest.audioOnly.withHighestBitrate();
      return audioStream.url.toString();
    } on SocketException {
      throw NoInternetException();
    } on HttpException {
      throw NoInternetException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw SongUnavailableException(
        'Failed to retrieve YouTube audio stream: ${e.toString()}',
      );
    }
  }

  Future<List<SongModel>> getTrending() async {
    try {
      const playlistId = 'PLMC9KNkIncKseYxDN2niHghoYbaaxL1y7';
      final List<SongModel> songs = [];
      try {
        final playlistVideos = await _yt.playlists
            .getVideos(playlistId)
            .take(20)
            .toList();
        for (final video in playlistVideos) {
          songs.add(
            SongModel(
              id: video.id.value,
              title: video.title,
              artist: video.author,
              album: 'Trending Hits',
              thumbnailUrl: video.thumbnails.highResUrl,
              audioUrl: '',
              durationMs: video.duration?.inMilliseconds ?? 0,
              source: MusicSource.youtube,
              sourceId: video.id.value,
            ),
          );
        }
      } catch (_) {
        return await search('trending songs');
      }

      if (songs.isEmpty) {
        return await search('trending songs');
      }
      return songs;
    } on SocketException {
      throw NoInternetException();
    } on HttpException {
      throw NoInternetException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ParseException('YouTube Trending Error: ${e.toString()}');
    }
  }

  Future<List<SongModel>> getPlaylistSongs(String playlistId) async {
    try {
      final List<SongModel> songs = [];
      final playlistVideos = await _yt.playlists
          .getVideos(playlistId)
          .take(30)
          .toList();
      for (final video in playlistVideos) {
        songs.add(
          SongModel(
            id: video.id.value,
            title: video.title,
            artist: video.author,
            album: 'YouTube Playlist',
            thumbnailUrl: video.thumbnails.highResUrl,
            audioUrl: '',
            durationMs: video.duration?.inMilliseconds ?? 0,
            source: MusicSource.youtube,
            sourceId: video.id.value,
          ),
        );
      }
      return songs;
    } on SocketException {
      throw NoInternetException();
    } on HttpException {
      throw NoInternetException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ParseException('YouTube Playlist Error: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getPopularPlaylists(String query) async {
    try {
      final curatedPlaylistIds = [
        'PLDIoUOhQQPlXr63I44jhd6tF8IRSXE7RA',
        'PLFgquLnL59alCl_2TQvOiD5Vgm1hCaGSI',
        'PLJEJ2D6jmY0Y5CxQrFIJ2oI_EAmTJoU5v',
        'PLH6pfBXQXHEC2uDmDy5oi3tHW6X8kogNp',
        'PLGBuKfnErZlANkEf0FmZMcjHOkT9HbhXZ',
        'PLYiHmos7pCPKMbhMzirHF_fI36_Q_lY3Y',
        'PL4fGSI1pDJn6O1LS0XSdF3RyO0Rq_LDeI',
        'PLDcnymzs18LWLKtkDrLEBg-y1jAfkm5Mz',
      ];

      final List<Map<String, dynamic>> playlists = [];

      final futures = curatedPlaylistIds.map((id) async {
        try {
          final playlist = await _yt.playlists.get(id);
          String thumbnailUrl = '';
          try {
            final videos = await _yt.playlists.getVideos(id).take(1).toList();
            if (videos.isNotEmpty) {
              thumbnailUrl = videos.first.thumbnails.highResUrl;
            }
          } catch (_) {}
          if (thumbnailUrl.isEmpty) {
            thumbnailUrl =
                'https://img.youtube.com/vi/${id.hashCode}/hqdefault.jpg';
          }
          return {
            'id': id,
            'title': playlist.title,
            'subtitle': '${playlist.videoCount ?? '?'} tracks • YouTube',
            'thumbnailUrl': thumbnailUrl,
          };
        } catch (_) {
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);
      for (final r in results) {
        if (r != null) playlists.add(r);
      }

      if (playlists.length < curatedPlaylistIds.length) {
        final searchResults = await _yt.search.searchContent(query);
        int idx = 0;
        final fallbackLimit = curatedPlaylistIds.length - playlists.length;
        final existingIds = playlists
            .map((playlist) => playlist['id'] as String? ?? '')
            .toSet();
        for (final pl in searchResults) {
          if (pl is SearchPlaylist &&
              idx < fallbackLimit &&
              !existingIds.contains(pl.id.value)) {
            final imageUrl = pl.thumbnails.isNotEmpty
                ? pl.thumbnails.first.url.toString()
                : 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=400&q=80';
            playlists.add({
              'id': pl.id.value,
              'title': pl.title,
              'subtitle': '${pl.videoCount} tracks • YouTube',
              'thumbnailUrl': imageUrl,
            });
            idx++;
          }
        }
      }

      return playlists;
    } on SocketException {
      throw NoInternetException();
    } on HttpException {
      throw NoInternetException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ParseException('YouTube Playlists Error: ${e.toString()}');
    }
  }
}
