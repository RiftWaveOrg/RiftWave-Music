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
        songs.add(SongModel(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          album: 'YouTube',
          thumbnailUrl: video.thumbnails.highResUrl,
          audioUrl: '',
          durationMs: video.duration?.inMilliseconds ?? 0,
          source: MusicSource.youtube,
          sourceId: video.id.value,
        ));
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

      final mp4Streams = manifest.audioOnly.where((stream) => stream.container.name == 'mp4').toList();
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
      throw SongUnavailableException('Failed to retrieve YouTube audio stream: ${e.toString()}');
    }
  }

  Future<List<SongModel>> getTrending() async {
    try {
      const playlistId = 'PLMC9KNkIncKseYxDN2niHghoYbaaxL1y7';
      final List<SongModel> songs = [];
      try {
        final playlistVideos = await _yt.playlists.getVideos(playlistId).take(20).toList();
        for (final video in playlistVideos) {
          songs.add(SongModel(
            id: video.id.value,
            title: video.title,
            artist: video.author,
            album: 'Trending Hits',
            thumbnailUrl: video.thumbnails.highResUrl,
            audioUrl: '',
            durationMs: video.duration?.inMilliseconds ?? 0,
            source: MusicSource.youtube,
            sourceId: video.id.value,
          ));
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
}
