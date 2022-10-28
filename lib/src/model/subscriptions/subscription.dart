import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'snippet.dart';
import 'content_details.dart';
import 'subscriber_snippet.dart';

part 'subscription.g.dart';

/// A [Subscription] resource contains information about a YouTube user
/// subscription. A subscription notifies a user when new videos are added to a
/// channel or when another user takes one of several actions on YouTube, such
/// as uploading a video, rating a video, or commenting on a video.
@JsonSerializable(explicitToJson: true)
class Subscription {
  /// Identifies the API resource's type. The value will be youtube#Subscription.
  final String kind;

  /// The Etag of this resource.
  final String etag;

  /// The ID that YouTube uses to uniquely identify the Subscription.
  final String id;

  /// The [Snippet] object contains basic details about the subscription, including its title and the channel that the user subscribed to.
  final Snippet? snippet;

  /// The [ContentDetails] object contains basic statistics about the subscription.
  final ContentDetails? contentDetails;

  /// The [SubscriberSnippet] object contains basic details about the subscriber.
  final SubscriberSnippet? subscriberSnippet;

  Subscription(
      {required this.kind,
      required this.etag,
      required this.id,
      this.snippet,
      this.contentDetails,
      this.subscriberSnippet});

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}
