import 'package:args/command_runner.dart';
import 'package:yt/src/util/util.dart';
import 'package:yt/yt.dart';

abstract class YtHelperCommand extends Command {
  late final Yt _yt;

  Broadcast get broadcast => _yt.broadcast;

  Chat get chat => _yt.chat;

  LiveStream get liveStream => _yt.liveStream;

  Channels get channels => _yt.channels;

  Comments get comments => _yt.comments;

  CommentThreads get commentThreads => _yt.commentThreads;

  Playlists get playlists => _yt.playlists;

  Search get search => _yt.search;

  Subscriptions get subscriptions => _yt.subscriptions;

  Thumbnails get thumbnails => _yt.thumbnails;

  Videos get videos => _yt.videos;

  VideoCategories get videoCategories => _yt.videoCategories;

  Watermarks get watermarks => _yt.watermarks;

  Future<void> initializeYt() async {
    _yt = Yt.withOAuth(
      logOptions: Util.convertToLogOptions(globalResults!['log-level']),
    );
  }
}
