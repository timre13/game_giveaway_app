import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;

const String apiUrl = "https://www.gamerpower.com/api";

String buildUrl(
    {required String endpoint, required Map<String, dynamic> arguments}) {
  String url = apiUrl + (endpoint.startsWith("/") ? "" : "/") + endpoint;

  arguments.removeWhere((key, value) => (value == null));
  if (arguments.isNotEmpty) {
    url += "?";
    url += arguments.entries.map((e) => "${e.key}=${e.value}").join("&");
  }

  return url;
}

abstract class ApiException implements Exception {
  final String message;

  ApiException({required this.message});
}

class NoGiveawaysException extends ApiException {
  NoGiveawaysException({required String message}) : super(message: message);

  @override
  String toString() => "NoGiveawaysException($message)";
}

class ObjectNotFoundException extends ApiException {
  ObjectNotFoundException({required String message}) : super(message: message);

  @override
  String toString() => "ObjectNotFoundException($message)";
}

class ServerErrorException extends ApiException {
  ServerErrorException({required String message}) : super(message: message);

  @override
  String toString() => "ServerErrorException($message)";
}

String getExceptionMessage(Exception e) {
  if (e is ApiException) {
    return e.message;
  }
  if (e is SocketException) {
    return e.message + (e.osError != null ? " (${e.osError!.message})" : "");
  }
  if (e is http.ClientException) {
    return e.message;
  }
  return e.toString();
}

http.Response checkStatusCode(http.Response response) {
  switch (response.statusCode) {
    case 200:
      return response;
    case 201:
      throw NoGiveawaysException(
          message: jsonDecode(response.body)["status_message"] ??
              "No active giveaways available at the moment, please try again later.");
    case 404:
      throw ObjectNotFoundException(
          message: jsonDecode(response.body)["status_message"] ??
              "Object not found.");
    case 500:
    default:
      throw ServerErrorException(
          message: jsonDecode(response.body)["status_message"] ??
              "Unexpected server error.");
  }
}

enum Platform {
  android,
  battlenet,
  drmFree,
  epicGamesStore,
  gog,
  ios,
  itchio,
  origin,
  pc,
  ps4,
  ps5,
  steam,
  switch_,
  ubisoft,
  vr,
  xbox360,
  xboxOne,
  xboxSeriesXS;

  @override
  String toString() {
    // Epic Map trickery
    return {
          drmFree: "drm-free",
          epicGamesStore: "epic-games-store",
          switch_: "switch",
          xbox360: "xbox-360",
          xboxOne: "xbox-one",
          xboxSeriesXS: "xbox-series-xs",
        }[this] ??
        name;
  }

  String getDisplayName() {
    return {
          android: "Android",
          battlenet: "Battle.net",
          drmFree: "DRM-Free",
          epicGamesStore: "Epic Games Store",
          gog: "GOG",
          ios: "iOS",
          itchio: "itch.io",
          origin: "Origin",
          pc: "PC",
          ps4: "PS4",
          ps5: "PS5",
          steam: "Steam",
          switch_: "Switch",
          ubisoft: "Ubisoft",
          vr: "VR",
          xbox360: "Xbox 360",
          xboxOne: "Xbox One",
          xboxSeriesXS: "Xbox Series X/S",
        }[this] ??
        "";
  }
}

enum GiveawayType {
  game,
  loot,
  beta;

  @override
  String toString() => name;

  String getDisplayName() {
    return {game: "Game", loot: "Loot", beta: "Beta"}[this] ?? "";
  }
}

class GiveawaySummary {
  final int activeGiveawaysNumber;
  final String worthEstimationUsd;

  GiveawaySummary(
      {required this.activeGiveawaysNumber, required this.worthEstimationUsd});

  factory GiveawaySummary.fromJson(Map<String, dynamic> json) {
    return GiveawaySummary(
        activeGiveawaysNumber: json["active_giveaways_number"],
        worthEstimationUsd: json["worth_estimation_usd"]);
  }

  @override
  String toString() =>
      "GiveawaySummary(activeGiveawaysNumber=$activeGiveawaysNumber, worthEstimationUsd=$worthEstimationUsd)";
}

Future<GiveawaySummary> getGiveawaySummary(
    {Platform? platform, GiveawayType? type}) async {
  if (kDebugMode) {
    print("Getting giveaway summary");
  }

  final url = buildUrl(
      endpoint: "worth", arguments: {"platform": platform, "type": type});

  final response = await http.get(Uri.parse(url));
  return GiveawaySummary.fromJson(jsonDecode(checkStatusCode(response).body));
}

class Giveaway {
  final int id;
  final String title;
  final String worth;
  final String thumbnail;
  final String image;
  final String description;
  final String instructions;
  final String openGiveawayUrl;
  final DateTime publishedDate;
  final String type; // TODO: Parse?
  final String platforms; // TODO: Parse?
  final DateTime? endDate; // TODO: Parse
  final int users;
  final String
      status; // TODO: Parse? (Possible values (probably): Active, Expired)
  final String gamerpowerUrl;

  Duration? get remainingTime => endDate?.difference(DateTime.now());

  Giveaway({
    required this.id,
    required this.title,
    required this.worth,
    required this.thumbnail,
    required this.image,
    required this.description,
    required this.instructions,
    required this.openGiveawayUrl,
    required this.publishedDate,
    required this.type,
    required this.platforms,
    required this.endDate,
    required this.users,
    required this.status,
    required this.gamerpowerUrl,
  });

  factory Giveaway.fromJson(Map<String, dynamic> json) {
    var unescape = HtmlUnescape();

    return Giveaway(
      id: json["id"],
      title: unescape.convert(json["title"]),
      worth: json["worth"],
      thumbnail: json["thumbnail"],
      image: json["image"],
      description: unescape.convert(json["description"]),
      instructions: unescape.convert(json["instructions"]),
      openGiveawayUrl: json["open_giveaway_url"],
      publishedDate: DateTime.parse(json["published_date"]),
      type: json["type"],
      platforms: json["platforms"],
      endDate: DateTime.tryParse(json["end_date"]),
      users: json["users"],
      status: json["status"],
      gamerpowerUrl: json["gamerpower_url"],
    );
  }
}

enum SortBy {
  date,
  value,
  popularity;

  @override
  String toString() => name;
}

Future<List<Giveaway>> getGiveaways(
    {Platform? platform, GiveawayType? type, SortBy? sortBy}) async {
  if (kDebugMode) {
    print("Getting giveaway list");
  }

  final url = buildUrl(
      endpoint: "giveaways",
      arguments: {"platform": platform, "type": type, "sort-by": sortBy});

  final response = await http.get(Uri.parse(url));
  return (jsonDecode(checkStatusCode(response).body) as List<dynamic>)
      .map((e) => Giveaway.fromJson(e))
      .toList(growable: false);
}

Future<Giveaway> getGiveawayDetails(int id) async {
  final url = buildUrl(endpoint: "giveaways", arguments: {"id": id});

  final response = await http.get(Uri.parse(url));
  return Giveaway.fromJson(jsonDecode(checkStatusCode(response).body));
}
