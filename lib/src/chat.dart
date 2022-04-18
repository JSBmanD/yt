import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:universal_io/io.dart';
import 'package:yt/src/help.dart';
import 'package:yt/yt.dart';

import 'provider/live/chat.dart';

///A liveChatMessage resource represents a chat message in a YouTube live chat. The resource can contain details about several types of messages, including a newly posted text message or fan funding event.
///
///The live chat feature is enabled by default for live broadcasts and is available while the live event is active. (After the event ends, live chat is no longer available for that event.)
class Chat extends YouTubeHelper {
  final String token;
  final Dio dio;

  final ChatClient _rest;

  final String _authHeader;

  Chat(this.token, this.dio)
      : _authHeader = 'Bearer $token',
        _rest = ChatClient(dio);

  ///Lists live chat messages for a specific chat.
  Future<LiveChatMessageListResponse> list(
      {required String liveChatId,
      String part = 'snippet,status,contentDetails',
      List<String> partList = const [],
      String? hl,
      int? maxResults,
      String? pageToken,
      int? profileImageSize}) async {
    final String part = 'snippet,authorDetails';

    return await _rest.list(
        _authHeader, accept, buildParts(partList, part), liveChatId,
        hl: hl,
        maxResults: maxResults,
        pageToken: pageToken,
        profileImageSize: profileImageSize);
  }

  ///Adds a message to a live chat.
  Future<LiveChatMessage> insert(
      {required Map<String, dynamic> body,
      String part = 'snippet,status,contentDetails',
      List<String> partList = const []}) async {
    String part = 'snippet';

    if (body['snippet']['textMessageDetails']['messageText'] == '') {
      throw Exception();
    }

    return await _rest.insert(
        _authHeader, accept, contentType, buildParts(partList, part), body);
  }

  ///Deletes a chat message. The API request must be authorized by the channel owner or a moderator of the live chat.
  Future<void> delete({required String id}) async {
    return _rest.delete(_authHeader, accept, id);
  }

  Future<void> send(
      {required String message,
      String? chatId,
      LiveBroadcastItem? liveBroadcastItem}) async {
    chatId ?? liveBroadcastItem?.snippet?.liveChatId ?? Exception();

    // if (chatId == null) {
    //   final liveBroadcastItem = await getActiveBroadcast();

    //   chatId = liveBroadcastItem.snippet?.liveChatId;
    // }

    final chatMessage = <String, dynamic>{
      'snippet': {
        'type': 'textMessageEvent',
        'liveChatId': chatId,
        'textMessageDetails': {'messageText': EmojiFormatter.format(message)}
      }
    };

    await insert(body: chatMessage);
  }

  Future<void> downloadHistory(
      {required LiveBroadcastItem liveBroadcastItem,
      File? file,
      TimeStore? timeStore}) async {
    await _download(
        liveBroadcastItem: liveBroadcastItem,
        timeStore: timeStore,
        onDownload: (List<LiveChatMessage> liveChatMessageList,
            LiveBroadcastItem liveBroadcastItem) {
          if (file == null) {
            for (LiveChatMessage liveChatMessage in liveChatMessageList) {
              stdout.writeln(
                  '${liveChatMessage.snippet.publishedAt!.toLocal()} | ${liveChatMessage.authorDetails?.displayName}: ' +
                      liveChatMessage.snippet.textMessageDetails!.messageText);
            }
          } else {
            file.writeAsStringSync(
                ListToCsvConverter().convert(liveChatMessageList
                    .map((liveChatMessage) => [
                          liveChatMessage.snippet.publishedAt!.toLocal(),
                          liveChatMessage.authorDetails?.displayName,
                          liveChatMessage
                              .snippet.textMessageDetails!.messageText
                        ])
                    .toList()),
                mode: FileMode.append);
          }
        });
  }

  Future<void> _download(
      {required LiveBroadcastItem liveBroadcastItem,
      required Function onDownload,
      TimeStore? timeStore}) async {
    LiveChatMessageListResponse liveChatMessageListResponse;

    List<LiveChatMessage> liveChatMessageList;

    String? nextPageToken;

    do {
      liveChatMessageListResponse = await list(
          pageToken: nextPageToken,
          liveChatId: liveBroadcastItem.snippet!.liveChatId!);

      if (liveChatMessageListResponse.items.isEmpty) break;

      nextPageToken = liveChatMessageListResponse.nextPageToken;

      liveChatMessageList = liveChatMessageListResponse.items;

      if (timeStore != null) {
        liveChatMessageList = liveChatMessageList
            .where((liveChatMessage) => liveChatMessage.snippet.publishedAt!
                .isAfter(timeStore.timeStamp))
            .toList();
      }

      if (liveChatMessageList.isNotEmpty) {
        await onDownload(liveChatMessageList, liveBroadcastItem);

        if (timeStore != null) {
          timeStore.timeStamp = liveChatMessageList.last.snippet.publishedAt!
              .add(Duration(milliseconds: 1))
              .toUtc();

          timeStore.persist();
        }
      }
    } while (liveChatMessageListResponse.nextPageToken != null);
  }

  Future<void> bot(
      {required LiveBroadcastItem liveBroadcastItem,
      required Chatbot chatbot,
      TimeStore? timeStore}) async {
    await _download(
        liveBroadcastItem: liveBroadcastItem,
        onDownload: (List<LiveChatMessage> liveChatMessageList,
            LiveBroadcastItem liveBroadcastItem) {
          liveChatMessageList
              .where((liveChatMessage) =>
                  liveChatMessage.authorDetails!.channelId !=
                  liveBroadcastItem.snippet?.channelId)
              .forEach((liveChatMessage) {
            chatbot.checkDialog(
                liveChatMessage: liveChatMessage,
                onFound: (dialog, recipient) async => await send(
                    message:
                        '${chatbot.nameFormatted}: @$recipient - ${dialog.answer}',
                    chatId: liveChatMessage.snippet.liveChatId));
          });
        });
  }
}
