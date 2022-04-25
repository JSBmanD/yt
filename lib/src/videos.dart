import 'package:dio/dio.dart';
import 'package:universal_io/io.dart';
import 'package:yt/src/help.dart';
import 'package:yt/yt.dart';

import 'provider/data/videos.dart';

///Returns a list of [VideoItem]s that match the API request parameters.
class Videos extends YouTubeHelper {
  final String token;
  final Dio dio;

  final VideoClient _rest;

  final String _authHeader;

  Videos({required this.token, required this.dio})
      : _authHeader = 'Bearer $token',
        _rest = VideoClient(dio);

  ///Uploads a [VideoItem] to YouTube and optionally sets the video's metadata.
  Future<VideoListResponse> list(
      {String part = 'snippet,status,contentDetails',
      List<String> partList = const [],
      String? chart,
      String? id,
      String? myRating,
      bool? hl,
      int? maxHeight,
      int? maxResults,
      int? maxWidth,
      String? onBehalfOfContentOwner,
      String? pageToken,
      String? regionCode,
      String? videoCategoryId}) async {
    return await _rest.list(_authHeader, accept, buildParts(partList, part),
        chart: chart,
        id: id,
        myRating: myRating,
        hl: hl,
        maxHeight: maxHeight,
        maxResults: maxResults,
        maxWidth: maxWidth,
        onBehalfOfContentOwner: onBehalfOfContentOwner,
        pageToken: pageToken,
        regionCode: regionCode,
        videoCategoryId: videoCategoryId);
  }

  ///Uploads a video to YouTube and optionally sets the video's metadata.
  Future<VideoItem> insert({
    required Map<String, dynamic> body,
    required File videoFile,
    String part = 'snippet,status,contentDetails',
    List<String> partList = const [],
    bool? notifySubscribers,
    String? onBehalfOfContentOwner,
    String? onBehalfOfContentOwnerChannel,
  }) async {
    final uploadType = 'resumable';

    final xUploadContentType = 'video/*';

    final parts = buildParts(partList, part);

    final httpResponse = await _rest.location(_authHeader, accept,
        videoFile.lengthSync(), xUploadContentType, body, parts, uploadType,
        notifySubscribers: notifySubscribers,
        onBehalfOfContentOwner: onBehalfOfContentOwner,
        onBehalfOfContentOwnerChannel: onBehalfOfContentOwnerChannel);

    if (!httpResponse.response.headers.map.containsKey('location')) {
      throw Exception('Upload location for the video could not be determined');
    }

    return await _rest.upload(
        _authHeader,
        accept,
        Util.getUploadIdFromUrl(
            httpResponse.response.headers.value('location')!),
        parts,
        videoFile,
        uploadType);
  }

  ///Updates a [VideoItem]'s metadata.
  Future<VideoItem> update(
      {required Map<String, dynamic> body,
      String part = 'snippet,status,contentDetails',
      List<String> partList = const []}) async {
    return await _rest.update(
        _authHeader, accept, buildParts(partList, part), body);
  }

  ///Add a like or dislike rating to a [VideoItem] or remove a rating from a [VideoItem].
  Future<void> rate({required String id, required String rating}) async {
    return await _rest.rate(_authHeader, accept, id, rating);
  }

  ///Retrieves the ratings that the authorized user gave to a list of specified videos.
  Future<VideoGetRatingResponse> getRating(
      {required String id, String? onBehalfOfContentOwner}) async {
    return await _rest.getRating(_authHeader, accept, id,
        onBehalfOfContentOwner: onBehalfOfContentOwner);
  }

  ///Report a video for containing abusive content.
  Future<void> reportAbuse(
      {required ReportAbuse body, String? onBehalfOfContentOwner}) async {
    await _rest.reportAbuse(_authHeader, accept, body,
        onBehalfOfContentOwner: onBehalfOfContentOwner);
  }

  ///Deletes a YouTube video.
  Future<void> delete(
      {required String id, String? onBehalfOfContentOwner}) async {
    await _rest.delete(_authHeader, accept, id,
        onBehalfOfContentOwner: onBehalfOfContentOwner);
  }
}
