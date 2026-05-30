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
        final duration = video.duration?.inMilliseconds ?? 0;
        if (duration < 60000 || duration > 900000) {
          continue;
        }
        songs.add(
          SongModel(
            id: video.id.value,
            title: video.title,
            artist: video.author,
            album: 'YouTube',
            thumbnailUrl: video.thumbnails.highResUrl,
            audioUrl: '',
            durationMs: duration,
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

  Future<Map<String, String>?> getDualStreamManifest(
    String videoId,
    String qualityPreference,
  ) async {
    try {
      StreamManifest manifest;
      try {
        manifest = await _yt.videos.streamsClient.getManifest(
          videoId,
          ytClients: [YoutubeApiClient.ios, YoutubeApiClient.androidVr],
        );
      } catch (_) {
        manifest = await _yt.videos.streamsClient.getManifest(videoId);
      }

      var videoStreams = manifest.videoOnly
          .where((stream) => stream.container.name == 'mp4')
          .toList();
      if (videoStreams.isEmpty) {
        videoStreams = manifest.videoOnly.toList();
      }

      if (videoStreams.isEmpty) return null;

      VideoStreamInfo? selectedVideo;
      if (qualityPreference != 'Auto') {
        final targetRes =
            int.tryParse(qualityPreference.replaceAll('p', '')) ?? 720;
        selectedVideo = videoStreams
            .where((s) => s.videoResolution.height <= targetRes)
            .fold<VideoStreamInfo?>(
              null,
              (prev, elem) =>
                  (prev == null ||
                      elem.videoResolution.height > prev.videoResolution.height)
                  ? elem
                  : prev,
            );
      }

      selectedVideo ??= videoStreams.withHighestBitrate();

      final mp4AudioStreams = manifest.audioOnly
          .where((stream) => stream.container.name == 'mp4')
          .toList();
      final selectedAudio = mp4AudioStreams.isNotEmpty
          ? mp4AudioStreams.withHighestBitrate()
          : manifest.audioOnly.withHighestBitrate();

      return {
        'videoUrl': selectedVideo.url.toString(),
        'audioUrl': selectedAudio.url.toString(),
      };
    } catch (e) {
      print('Dual stream extraction error: $e');
      return null;
    }
  }

  Future<List<SongModel>> getTrending(String query) async {
    try {
      return await search(query);
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
      final List<Map<String, dynamic>> playlists = [];
      final searchResults = await _yt.search.searchContent(query);

      for (final pl in searchResults) {
        if (pl is SearchPlaylist) {
          final imageUrl = pl.thumbnails.isNotEmpty
              ? pl.thumbnails.first.url.toString()
              : 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=400&q=80';
          playlists.add({
            'id': pl.id.value,
            'title': pl.title,
            'subtitle': '${pl.videoCount} tracks • YouTube',
            'thumbnailUrl': imageUrl,
          });
          if (playlists.length >= 10) break;
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

  Future<List<SongModel>> getRelatedSongs(String videoId) async {
    try {
      final video = await _yt.videos.get(VideoId(videoId));
      final related = await _yt.videos.getRelatedVideos(video);
      final List<SongModel> songs = [];

      if (related != null) {
        for (final rVideo in related) {
          final duration = rVideo.duration?.inMilliseconds ?? 0;
          if (duration > 0 && (duration < 60000 || duration > 900000)) {
            continue;
          }
          songs.add(
            SongModel(
              id: rVideo.id.value,
              title: rVideo.title,
              artist: rVideo.author,
              album: 'YouTube',
              thumbnailUrl: rVideo.thumbnails.highResUrl,
              audioUrl: '',
              durationMs: duration,
              source: MusicSource.youtube,
              sourceId: rVideo.id.value,
            ),
          );
        }
      }
      return songs;
    } on SocketException {
      throw NoInternetException();
    } on HttpException {
      throw NoInternetException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ParseException('YouTube Related Error: ${e.toString()}');
    }
  }

  static String getMaxResThumbnail(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  static String getHqThumbnail(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      // Append " song" to force YouTube to return music-related suggestions
      final suggestions = await _yt.search.getQuerySuggestions('$query song');
      
      return suggestions.map((s) {
        // Clean up the " song" suffix if it exists so it looks natural to the user
        if (s.toLowerCase().endsWith(' song')) {
          return s.substring(0, s.length - 5).trim();
        }
        return s;
      }).toSet().toList(); // Remove duplicates
    } catch (e) {
      print('YouTube Suggestions Error: $e');
      return [];
    }
  }
}
