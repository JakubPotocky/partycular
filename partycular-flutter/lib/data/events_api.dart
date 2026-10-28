import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';

/// Thrown when the events endpoint cannot be reached or answers badly.
class EventsApiException implements Exception {
  const EventsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'EventsApiException($statusCode): $message';
}

/// Thin client for the public, unauthenticated part of the PARTYCULAR API.
class EventsApi {
  EventsApi({required this._client, Uri? baseUri}) : baseUri = baseUri ?? AppConfig.apiBaseUri;

  final http.Client _client;
  final Uri baseUri;

  /// Returns the raw JSON body of `GET /api/events` (published events only).
  /// The body is validated to be a JSON array before it is returned.
  Future<String> fetchEventsJson() async {
    final http.Response response;
    try {
      response = await _client
          .get(baseUri.resolve('/api/events'), headers: const {'Accept': 'application/json'})
          .timeout(AppConfig.requestTimeout);
    } on Exception catch (error) {
      throw EventsApiException('Network error: $error');
    }
    if (response.statusCode != 200) {
      throw EventsApiException('Unexpected response', statusCode: response.statusCode);
    }
    final body = utf8.decode(response.bodyBytes);
    try {
      if (jsonDecode(body) is! List<Object?>) throw const FormatException('Not a list');
    } on FormatException catch (error) {
      throw EventsApiException('Malformed body: ${error.message}', statusCode: 200);
    }
    return body;
  }
}
