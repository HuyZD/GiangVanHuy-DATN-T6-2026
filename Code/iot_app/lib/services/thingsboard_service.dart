import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ThingsboardService {
  static const String token = "UnZmpfOxDol8TvmVHceR";
  static const String baseUrl = "https://thingsboard.cloud";
  static const String deviceId = "0e99eb10-37e6-11f1-8ebb-d54a2d348b45";
  static Future<void> sendTelemetry(Map<String, dynamic> data) async {
    final url = Uri.parse("https://thingsboard.cloud/api/v1/$token/telemetry");

    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
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
