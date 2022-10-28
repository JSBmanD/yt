import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:universal_io/io.dart';
import 'package:yt/src/util/util.dart';
import 'package:yt/yt.dart';

///A liveChatMessage resource represents a chat message in a YouTube live chat.
///The resource can contain details about several types of messages, including a
///newly posted text message or fan funding event.
///
///The live chat feature is enabled by default for live broadcasts and is
///available while the live event is active. (After the event ends, live chat is
///no longer available for that event.)
class YoutubeChatCommand extends Command {
  @override
  String get description =>
      '''A liveChatMessage resource represents a chat message in a YouTube live chat. The resource can contain details about several types of messages, including a newly posted text message or fan funding event.

The live chat feature is enabled by default for live broadcasts and is available while the live event is active. (After the event ends, live chat is no longer available for that event.)''';

  @override
  String get name => 'chat';

  YoutubeChatCommand() {
    addSubcommand(YoutubeListChatCommand());
    addSubcommand(YoutubeInsertChatCommand());
    addSubcommand(YoutubeDeleteChatCommand());
    addSubcommand(YoutubeAnswerChatCommand());
  }
}

///Lists live chat messages for a specific chat.
class YoutubeListChatCommand extends YtHelperCommand {
  @override
  String get description => 'Lists live chat messages for a specific chat.';

  @override
  String get name => 'list';

  YoutubeListChatCommand() {
    argParser
      ..addOption('liveChatId',
          mandatory: true,
          valueHelp: 'liveChatId',
          help:
              'The liveChatId parameter specifies the ID of the chat whose messages will be returned. The live chat ID associated with a broadcast is returned in the liveBroadcast resource\'s snippet.liveChatId property.')
      ..addOption('part',
          defaultsTo: 'id,snippet,authorDetails',
          help:
              'The part parameter specifies the liveChatMessage resource parts that the API response will include. Supported values are id, snippet, and authorDetails.')
      ..addOption('max-results',
          defaultsTo: '500',
          valueHelp: 'number',
          help:
              'The maxResults parameter specifies the maximum number of messages that should be returned in the result set. Acceptable values are 200 to 2000, inclusive. The default value is 500.')
      ..addOption('page-token',
          valueHelp: 'token',
          help:
              'The pageToken parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken property identify other pages that could be retrieved.')
      ..addOption('profile-image-size',
          defaultsTo: '88',
          valueHelp: 'number',
          help:
              'The profileImageSize parameter specifies the size of the user profile pictures that should be returned in the result set. The images are square. The default value is 88, meaning pictures will be 88px by 88px. Acceptable values are in the range 16 to 720, inclusive.');
  }

  @override
  void run() async {
    await initializeYt();

    try {
      final liveChatMessageListResponse = await chat.list(
          liveChatId: argResults!['liveChatId'],
          part: argResults!['part'],
          maxResults: int.parse(argResults!['max-results']),
          pageToken: argResults?['page-token'],
          profileImageSize: int.parse(argResults!['profile-image-size']));

      print(liveChatMessageListResponse);
    } on DioError catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

///Adds a message to a live chat. The API currently supports the ability to
///insert text messages only.
class YoutubeInsertChatCommand extends YtHelperCommand {
  @override
  String get description =>
      'Adds a message to a live chat. The API currently supports the ability to insert text messages only.';

  @override
  String get name => 'insert';

  YoutubeInsertChatCommand() {
    argParser
      ..addOption('part',
          defaultsTo: 'snippet',
          help:
              'The part parameter serves two purposes. It identifies the properties that the write operation will set as well as the properties that the API response will include. Set the parameter value to snippet.')
      ..addOption('body',
          mandatory: true,
          help:
              'Provide a liveChatMessage resource [https://developers.google.com/youtube/v3/live/docs/liveChatMessages#resource] in the request body.');
  }

  @override
  void run() async {
    await initializeYt();

    try {
      final liveChatMessage = await chat.insert(
          body: json.decode(argResults!['body']), part: argResults!['part']);

      print(liveChatMessage);
    } on DioError catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

///Deletes a chat message. The API request must be authorized by the channel
///owner or a moderator of the live chat associated with the ban.
class YoutubeDeleteChatCommand extends YtHelperCommand {
  @override
  String get description =>
      'Deletes a chat message. The API request must be authorized by the channel owner or a moderator of the live chat associated with the ban.';

  @override
  String get name => 'delete';

  YoutubeDeleteChatCommand() {
    argParser.addOption('id',
        mandatory: true,
        valueHelp: 'id',
        help:
            'The id parameter specifies the YouTube chat message ID of the resource that is being deleted.');
  }

  @override
  void run() async {
    await initializeYt();

    try {
      await chat.delete(id: argResults!['id']);
    } on DioError catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

class YoutubeAnswerChatCommand extends YtHelperCommand {
  @override
  String get description =>
      'Process chat messages and provided canned answers to set questions (not part of the documented API).';

  @override
  String get name => 'answer';

  YoutubeAnswerChatCommand() {
    argParser.addOption('chatbot-config',
        valueHelp: 'path',
        help: 'The path to a "yaml" file with the Chatbot configuration.',
        defaultsTo: '${Util.userHome}/.yt/chatbot.yaml');
  }

  @override
  void run() async {
    var configFile = File(argResults?['chatbot-config']);

    if (!configFile.existsSync()) {
      throw Exception(
          'File: ${configFile.path} could not be found.  This is a required file.');
    }

    await initializeYt();

    var chatbot = Chatbot.fromYaml(configFile);

    var liveBroadcastItem = await broadcast.getActiveBroadcast();

    await chat.answerBot(
        liveBroadcastItem: liveBroadcastItem, chatbot: chatbot);
  }
}
