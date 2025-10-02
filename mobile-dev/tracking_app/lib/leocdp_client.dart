// mobile-dev/tracking_app/lib/leocdp_client.dart

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Represents a single item within a shopping cart or transaction.
@immutable
class TradingItem {
  final String tickerSymbol;

  const TradingItem({required this.tickerSymbol});


  /// Converts this object into a JSON-encodable map.
  Map<String, dynamic> toJson() {
    return {
      'tickerSymbol': tickerSymbol,
     
    };
  }
}

/// Represents the complete tracking event payload to be sent to the LEO CDP API.
@immutable
class TrackingEvent {
  // Required fields
  final String metric;
  final String targetUpdateEmail; // Or another primary identifier

  // Touchpoint Information
  final String? tpName;
  final String? tpUrl;
  final String? tpRefUrl;

  // Transaction Information
  final num? tsVal;
  final String? tsCur;
  final String? tsStatus;
  final num? tsTax;
  final num? tsShippingValue;
  final Map<String, dynamic>? tsShippingInfo;
  final String? tsId; // Transaction ID
  final List<TradingItem>? tditems; // TRADING_ITEMS

  // Other contextual information
  final String? eventTime; // ISO 8601 format e.g. 2024-10-28T16:57:25+07:00
  final Map<String, dynamic>? eventData; // Custom event data
  final String? message;
  final String? locationName;
  final String? sourceIp;
  final String? userAgent;

  TrackingEvent({
    required this.metric,
    required this.targetUpdateEmail,
    this.tpName,
    this.tpUrl,
    this.tpRefUrl,
    this.tsVal,
    this.tsCur,
    this.tsStatus,
    this.tsTax,
    this.tsShippingValue,
    this.tsShippingInfo,
    this.tsId,
    this.tditems,
    this.eventTime,
    this.eventData,
    this.message,
    this.locationName,
    this.sourceIp,
    this.userAgent,
  }) {
    // For purchase/checkout events, transaction ID and items are highly recommended.
    if (metric == 'purchase' || metric == 'order-checkout') {
      assert(tsId != null, 'tsId is required for purchase/order-checkout events.');
      assert(tditems != null, 'tditems are required for purchase/order-checkout events.');
    }
  }

  /// Converts this object into a JSON-encodable map, matching the API's expected keys.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'metric': metric,
      'targetUpdateEmail': targetUpdateEmail,
      'eventtime': eventTime ?? DateTime.now().toIso8601String(),
    };

    if (tpName != null) data['tpname'] = tpName;
    if (tpUrl != null) data['tpurl'] = tpUrl;
    if (tpRefUrl != null) data['tprefurl'] = tpRefUrl;
    if (tsVal != null) data['tsval'] = tsVal;
    if (tsCur != null) data['tscur'] = tsCur;
    if (tsStatus != null) data['tsstatus'] = tsStatus;
    if (tsTax != null) data['tstax'] = tsTax;
    if (tsShippingValue != null) data['tsshippingvalue'] = tsShippingValue;
    if (tsShippingInfo != null) data['tsshippinginfo'] = tsShippingInfo;
    if (tsId != null) data['tsid'] = tsId;
    if (tditems != null) {
      data['tditems'] = tditems.map((item) => item.toJson()).toList();
    }
    if (eventData != null) data['eventdata'] = eventData;
    if (message != null) data['message'] = message;
    if (locationName != null) data['locationName'] = locationName;
    if (sourceIp != null) data['sourceip'] = sourceIp;
    if (userAgent != null) data['useragent'] = userAgent;

    return data;
  }
}

/// A client class to handle sending tracking events to the LEO CDP.
class LeoCdpClient {
  final String _baseUrl;
  final http.Client _client;
  final String _tokenKey;
  final String _tokenValue;
  static const String _eventPath = '/api/event/save';

  /// Constructor loads the token values from .env.
  /// Requires dotenv.load() to be called in main() before using this.
  LeoCdpClient({
    http.Client? client,
    String baseUrl = "https://datahub4dcdp.bigdatavietnam.org", // Note: No trailing slash
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl,
        _tokenKey = dotenv.env['LEO_TOKEN_KEY'] ?? '',
        _tokenValue = dotenv.env['LEO_TOKEN_VALUE'] ?? '' {
    if (_tokenKey.isEmpty || _tokenValue.isEmpty) {
      debugPrint('Warning: LEO_TOKEN_KEY or LEO_TOKEN_VALUE is not set in .env file.');
    }
  }

  /// Sends a structured tracking event to the LEO CDP server.
  ///
  /// Takes a [TrackingEvent] object and returns a [TrackingResult]
  /// indicating success or failure.
  Future<TrackingResult> trackEvent(TrackingEvent event) async {
    final url = Uri.parse('$_baseUrl$_eventPath');
    
    try {
      final response = await _client.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
          "tokenkey": _tokenKey,
          "tokenvalue": _tokenValue,
        },
        body: jsonEncode(event.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return TrackingResult(
            isSuccess: true, message: "✅ Event sent: ${event.metric}");
      } else {
        return TrackingResult(
            isSuccess: false,
            message: "⚠️ Failed to send ${event.metric} (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      return TrackingResult(isSuccess: false, message: "❌ Error sending ${event.metric}: $e");
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