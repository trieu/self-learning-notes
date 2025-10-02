import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

/// A service class to handle sending tracking events.
class TrackingService {
  final String _baseUrl;
  final http.Client _client;
  final String _tokenKey;
  final String _tokenValue;

  /// Constructor loads the token values at runtime.
  /// Requires dotenv.load() to be called in main() before using this.
  TrackingService({
    http.Client? client,
    String baseUrl = "https://datahub4dcdp.bigdatavietnam.org/",
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl,
        _tokenKey = dotenv.env['LEO_TOKEN_KEY'] ?? '',
        _tokenValue = dotenv.env['LEO_TOKEN_VALUE'] ?? '';

  /// Sends a tracking event to the server.
  ///
  /// Takes an [eventName] and returns a [TrackingResult]
  /// indicating success or failure.
  Future<TrackingResult> sendEvent(String eventName) async {
    final url = Uri.parse(_baseUrl);
    final body = {
      "event_name": eventName,
      "timestamp": DateTime.now().toIso8601String(),
      "device": "Flutter-Android12"
    };

    try {
      final response = await _client.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
          "tokenkey": _tokenKey,
          "tokenvalue": _tokenValue,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return TrackingResult(
            isSuccess: true, message: "✅ Event sent: $eventName");
      } else {
        return TrackingResult(
            isSuccess: false,
            message: "⚠️ Failed (${response.statusCode})");
      }
    } catch (e) {
      return TrackingResult(isSuccess: false, message: "❌ Error: $e");
    }
  }
}

/// A simple class to hold the result of the tracking call.
@immutable
class TrackingResult {
  final bool isSuccess;
  final String message;

  const TrackingResult({required this.isSuccess, required this.message});
}
