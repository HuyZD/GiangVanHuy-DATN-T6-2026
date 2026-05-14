import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ThingsboardRealtimeUpdate {
  final Map<String, dynamic> telemetry;
  final Map<String, dynamic> attributes;

  const ThingsboardRealtimeUpdate({
    this.telemetry = const {},
    this.attributes = const {},
  });
}

class ThingsboardService {
  static const String token = "UnZmpfOxDol8TvmVHceR";
  static const String baseUrl = "https://thingsboard.cloud";
  static const String deviceId = "0e99eb10-37e6-11f1-8ebb-d54a2d348b45";
  static const String telegramBotToken =
      "8554643284:AAFxOXk8XP1yVc1RkAJLhFzrIpDn-a7lQho";
  static const String telegramChatId = "8506078712";

  static Future<void> sendTelemetry(Map<String, dynamic> data) async {
    final url = Uri.parse("https://thingsboard.cloud/api/v1/$token/telemetry");

    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
  }

  static Future<void> sendTelegramMessage(String text) async {
    final url = Uri.https(
      "api.telegram.org",
      "/bot$telegramBotToken/sendMessage",
      {"chat_id": telegramChatId, "text": text},
    );

    final response = await http.get(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint("Telegram alert failed: ${response.statusCode}");
      debugPrint("Telegram alert body: ${response.body}");
      throw HttpException(
        "Telegram alert failed with status ${response.statusCode}",
        uri: url,
      );
    }
  }

  // Login

  static Future<String?> login() async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": "giangvanhuy84@gmail.com",
        "password": "Giangvanhuy12@7",
      }),
    );

    debugPrint("LOGIN STATUS: ${res.statusCode}");
    debugPrint("LOGIN BODY: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["token"];
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getTelemetry(
    String jwt,
    String deviceId,
  ) async {
    final url = Uri.parse(
      "$baseUrl/api/plugins/telemetry/DEVICE/$deviceId/values/timeseries",
    );

    final res = await http.get(
      url,
      headers: {"X-Authorization": "Bearer $jwt"},
    );

    return jsonDecode(res.body);
  }

  static Stream<ThingsboardRealtimeUpdate> subscribeDeviceData({
    required String jwt,
    required String deviceId,
  }) async* {
    final uri = Uri.parse(
      "$baseUrl/api/ws/plugins/telemetry?token=$jwt",
    ).replace(scheme: baseUrl.startsWith("https") ? "wss" : "ws");

    final socket = await WebSocket.connect(uri.toString());

    socket.add(
      jsonEncode({
        "tsSubCmds": [
          {
            "entityType": "DEVICE",
            "entityId": deviceId,
            "scope": "LATEST_TELEMETRY",
            "cmdId": 1,
          },
        ],
        "historyCmds": [],
        "attrSubCmds": [
          {
            "entityType": "DEVICE",
            "entityId": deviceId,
            "scope": "SHARED_SCOPE",
            "cmdId": 2,
          },
        ],
      }),
    );

    try {
      await for (final message in socket) {
        if (message is! String) continue;

        final decoded = jsonDecode(message);
        if (decoded is! Map<String, dynamic>) continue;

        final rawData = decoded["data"];
        if (rawData is! Map<String, dynamic>) continue;

        final values = _extractRealtimeValues(rawData);
        final subscriptionId = decoded["subscriptionId"];

        if (subscriptionId == 2) {
          yield ThingsboardRealtimeUpdate(attributes: values);
        } else {
          yield ThingsboardRealtimeUpdate(telemetry: values);
        }
      }
    } finally {
      await socket.close();
    }
  }

  static Map<String, dynamic> _extractRealtimeValues(
    Map<String, dynamic> rawData,
  ) {
    return rawData.map(
      (key, value) => MapEntry(key, _extractRealtimeValue(value)),
    );
  }

  static dynamic _extractRealtimeValue(dynamic value) {
    if (value is List && value.isNotEmpty) {
      final first = value.first;

      if (first is List && first.length > 1) {
        return first[1];
      }

      if (first is Map && first.containsKey("value")) {
        return first["value"];
      }

      return first;
    }

    if (value is Map && value.containsKey("value")) {
      return value["value"];
    }

    return value;
  }

  static Future<void> sendSharedAttributes({
    required String jwt,
    required String deviceId,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse(
      "$baseUrl/api/plugins/telemetry/DEVICE/$deviceId/SHARED_SCOPE",
    );

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-Authorization": "Bearer $jwt",
      },
      body: jsonEncode(data),
    );

    debugPrint("Shared attributes response: ${response.statusCode}");
    debugPrint("Shared attributes body: ${response.body}");
  }

  static Future<Map<String, dynamic>> getSharedAttributes({
    required String jwt,
    required String deviceId,
    required List<String> keys,
  }) async {
    final url = Uri.parse(
      "$baseUrl/api/plugins/telemetry/DEVICE/$deviceId/values/attributes/SHARED_SCOPE?keys=${keys.join(",")}",
    );

    final response = await http.get(
      url,
      headers: {"X-Authorization": "Bearer $jwt"},
    );

    final List data = jsonDecode(response.body);
    return {for (final item in data) item["key"].toString(): item["value"]};
  }

  static Future<void> sendRPC({
    required String jwt,
    required String deviceId,
    required String method,
    dynamic params,
  }) async {
    final url = Uri.parse(
      "https://thingsboard.cloud/api/plugins/rpc/twoway/$deviceId",
    );

    final body = {"method": method, "params": params};

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-Authorization": "Bearer $jwt",
      },
      body: jsonEncode(body),
    );

    debugPrint("RPC response: ${response.body}");
  }
}
