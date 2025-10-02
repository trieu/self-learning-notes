import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// ----------------------
/// LEO CDP Client
/// ----------------------
class LeoCdpClient {
  final String baseUrl;
  final String tokenKey;
  final String tokenValue;
  final http.Client _client;

  LeoCdpClient({
    String? baseUrl,
    String? tokenKey,
    String? tokenValue,
    http.Client? client,
  }) : baseUrl =
           baseUrl ??
           dotenv.env['LEO_BASE_URL'] ??
           'https://datahub4dcdp.bigdatavietnam.org/',
       tokenKey = tokenKey ?? dotenv.env['LEO_TOKEN_KEY'] ?? '',
       tokenValue = tokenValue ?? dotenv.env['LEO_TOKEN_VALUE'] ?? '',
       _client = client ?? http.Client();

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "tokenkey": tokenKey,
    "tokenvalue": tokenValue,
  };

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final body = jsonEncode(payload);

    final response = await _client.post(uri, headers: _headers, body: body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {"status": "success"}; // fallback
      }
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }

  /// Track an event
  Future<Map<String, dynamic>> trackEvent(Event event) async {
    return await post('/api/event/save', event.toJson());
  }
}

/// ----------------------
/// Event Model
/// ----------------------
class Event {
  final String eventName;
  final String device;
  final String timestamp;

  Event({required this.eventName, String? device, String? timestamp})
    : device = device ?? "Flutter-Android12",
      timestamp = timestamp ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
    "event_name": eventName,
    "device": device,
    "timestamp": timestamp,
  };
}
