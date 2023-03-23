import 'package:dio/dio.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

import 'package:loggy/loggy.dart';
import 'package:universal_io/io.dart';
import 'package:yt/oauth.dart';

import 'package:yt/src/util/util.dart';
import 'package:yt/yt.dart';

class Yt with UiLoggy {
  static final dio = Dio();
  static final httpClient = HttpClient();
  static final tokenExpiry = DateTime(2000, 0, 0);
  static final _interceptors = <Interceptor>[];

  static RefreshTokenGenerator? refreshTokenGenerator;

  Broadcast? _broadcast;
  Channels? _channels;
  Chat? _chat;
  Comments? _comments;
  CommentThreads? _commentThreads;
  LiveStream? _liveStream;
  Playlists? _playlists;
  PlaylistItems? _playlistItems;
  Search? _search;
  Subscriptions? _subscriptions;
  Thumbnails? _thumbnails;
  Videos? _videos;
  VideoCategories? _videoCategories;
  Watermarks? _watermarks;

  Broadcast get broadcast => _broadcast!;
  Channels get channels => _channels!;
  Chat get chat => _chat!;
  Comments get comments => _comments!;
  CommentThreads get commentThreads => _commentThreads!;
  LiveStream get liveStream => _liveStream!;
  Playlists get playlists => _playlists!;
  PlaylistItems get playlistItems => _playlistItems!;
  Search get search => _search!;
  Subscriptions get subscriptions => _subscriptions!;
  Thumbnails get thumbnails => _thumbnails!;
  Videos get videos => _videos!;
  VideoCategories get videoCategories => _videoCategories!;
  Watermarks get watermarks => _watermarks!;

  Yt(
      {LogOptions logOptions = const LogOptions(
        LogLevel.error,
        stackTraceLevel: LogLevel.off,
      ),
      LoggyPrinter printer = const PrettyPrinter(
        showColors: false,
      )}) {
    Loggy.initLoggy(logPrinter: printer, logOptions: logOptions);

    addInterceptor(
      LoggingInterceptors(),
      position: ListPosition.end,
    );
  }

  static Yt withKey(String apiKey) {
    final yt = Yt();

    yt.setModules(apiKey: apiKey);

    dio.interceptors.addAll(_interceptors);

    return yt;
  }

  static Yt withOAuth(
      {ClientId? oAuthClientId,
      LogOptions logOptions = const LogOptions(
        LogLevel.error,
        stackTraceLevel: LogLevel.off,
      )}) {
    oAuthClientId ??= Util.defaultClientId();

    final oauthAccessControl = OAuthAccessControl(oAuthClientId);

    final yt = Yt(
        logOptions: logOptions,
        printer: const PrettyPrinter(
          showColors: false,
        ));

    addInterceptor(InterceptorsWrapper(onRequest: (options, handler) async {
      await oauthAccessControl.checkAccessToken();

      options.headers['Authorization'] = 'Bearer ${oauthAccessControl.token}';

      return handler.next(options);
    }));

    yt.setModules(useToken: true);

    dio.interceptors.addAll(_interceptors);

    return yt;
  }

  static Future<Yt> withGenerator(RefreshTokenGenerator refreshTokenGenerator,
      {LogOptions logOptions = const LogOptions(
        LogLevel.error,
        stackTraceLevel: LogLevel.off,
      )}) async {
    final yt = Yt(logOptions: logOptions);

    Token token = await refreshTokenGenerator.generate();

    addInterceptor(InterceptorsWrapper(onRequest: (options, handler) async {
      options.headers['Authorization'] = 'Bearer ${token.accessToken}';

      return handler.next(options);
    }));

    yt.setModules(useToken: true);

    dio.interceptors.addAll(_interceptors);

    return yt;
  }

  static void addInterceptor(Interceptor interceptor,
      {ListPosition position = ListPosition.start}) {
    switch (position) {
      case ListPosition.start:
        _interceptors.insert(0, interceptor);

        break;
      case ListPosition.end:
        _interceptors.add(interceptor);

        break;
    }
  }

  /// Close the http connection to the API server
  void close() => Yt.httpClient.close();

  void setModules({bool? useToken, String? apiKey}) {
    if (useToken != null && useToken) {
      /// A liveBroadcast resource represents an event that will be streamed, via live video, on YouTube.
      _broadcast = Broadcast(dio);

      /// A liveChatMessage resource represents a chat message in a YouTube live chat. The resource can contain details about several types of messages, including a newly posted text message or fan funding event.
      ///
      /// The live chat feature is enabled by default for live broadcasts and is available while the live event is active. (After the event ends, live chat is no longer available for that event.)
      _chat = Chat(dio);

      ///A liveStream resource contains information about the video stream that you are transmitting to YouTube. The stream provides the content that will be broadcast to YouTube users. Once created, a [LiveStreamItem] resource can be bound to one or more [LiveBroadcastItem] resources.
      _liveStream = LiveStream(dio);

      /// A subscription resource contains information about a YouTube user subscription. A subscription notifies a user when new videos are added to a channel or when another user takes one of several actions on YouTube, such as uploading a video, rating a video, or commenting on a video.
      _subscriptions = Subscriptions(dio);

      /// A [Thumbnail] resource identifies different thumbnail image sizes associated with a resource. Please note the following characteristics of thumbnail images:
      ///
      /// - A resource's Snippet.thumbnails property is an object that identifies the thumbnail images available for that resource.
      /// - A thumbnail resource contains a series of objects. The name of each object (default, medium, high, etc.) refers to the thumbnail image size.
      /// - Different types of resources may support different thumbnail image sizes.
      /// - Different types of resources may define different sizes for thumbnail images with the same name. For example, the default thumbnail image for a video resource is typically 120px by 90px, and the default thumbnail image for a channel resource is typically 88px by 88px.
      /// - Resources of the same type may still have different thumbnail image sizes for certain images depending on the resolution of the original image or content uploaded to YouTube. For example, an HD video may support higher resolution thumbnails than non-HD videos.
      /// - Each object that contains information about a thumbnail image size has a width property and a height property. However, the width and height properties may not be returned for that image.
      /// - If an uploaded thumbnail image does not match the required dimensions, the image is resized to match the correct size without changing its aspect ratio. The image is not cropped, but may include black bars so that the size is correct.
      _thumbnails = Thumbnails(dio);

      /// A video resource represents a YouTube video.
      _videos = Videos(dio);

      /// A videoCategory resource identifies a category that has been or could be associated with uploaded videos.
      _videoCategories = VideoCategories(dio);

      /// A [Watermark] resource identifies an image that displays during playbacks of
      /// a specified channel's videos. You can also specify a target channel to which
      /// the image will link as well as timing details that determine when the
      /// watermark appears during video playbacks and the length of time it is
      /// visible.
      _watermarks = Watermarks(dio);
    }

    /// A channel resource contains information about a YouTube channel.
    _channels = Channels(apiKey: apiKey, dio: dio);

    /// A comment resource contains information about a single YouTube comment. A comment resource can represent a comment about either a video or a channel. In addition, the comment could be a top-level comment or a reply to a top-level comment.
    _comments = Comments(apiKey: apiKey, dio: dio);

    /// A commentThread resource contains information about a YouTube comment thread, which comprises a top-level comment and replies, if any exist, to that comment. A commentThread resource can represent comments about either a video or a channel.
    _commentThreads = CommentThreads(apiKey: apiKey, dio: dio);

    /// A playlist resource represents a YouTube playlist. A playlist is a collection of videos that can be viewed sequentially and shared with other users. By default, playlists are publicly visible to other users, but playlists can be public or private.
    ///
    /// YouTube also uses playlists to identify special collections of videos for a channel, such as:
    ///
    /// - uploaded videos
    /// - positively rated (liked) videos
    /// To be more specific, these lists are associated with a channel, which is a collection of a person, group, or company's videos, playlists, and other YouTube information. You can retrieve the playlist IDs for each of these lists from the channel resource for a given channel.
    ///
    /// You can then use the playlistItems.list method to retrieve any of those lists. You can also add or remove items from those lists by calling the playlistItems.insert and playlistItems.delete methods.
    _playlists = Playlists(apiKey: apiKey, dio: dio);

    /// A playlistItem resource identifies another resource, such as a video, that is included in a playlist. In addition, the playlistItem resource contains details about the included resource that pertain specifically to how that resource is used in that playlist.
    ///
    /// YouTube also uses a playlist to identify a channel's list of uploaded videos, with each playlistItem in that list representing one uploaded video. You can retrieve the playlist ID for that list from the channel resource for a given channel. You can then use the playlistItems.list method to the list.
    _playlistItems = PlaylistItems(apiKey: apiKey, dio: dio);

    /// A search result contains information about a YouTube video, channel, or playlist that matches the search parameters specified in an API request. While a search result points to a uniquely identifiable resource, like a video, it does not have its own persistent data.
    _search = Search(apiKey: apiKey, dio: dio);
  }
}
