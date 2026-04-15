import 'package:http/http.dart' as http;
import 'dart:convert';

class ThingsboardService {
  static const String token = "UnZmpfOxDol8TvmVHceR";
  static const String baseUrl = "https://thingsboard.cloud";
  static const String deviceId = "0e99eb10-37e6-11f1-8ebb-d54a2d348b45";
  static Future<void> sendTelemetry(Map<String, dynamic> data) async {
    final url = Uri.parse(
        "https://thingsboard.cloud/api/v1/$token/telemetry");

    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

  }
  // Login


  // 🔥 LOGIN
  static Future<String?> login() async {
  final res = await http.post(
  Uri.parse("$baseUrl/api/auth/login"),
  headers: {"Content-Type": "application/json"},
  body: jsonEncode({
  "username": "giangvanhuy84@gmail.com",
  "password": "Giangvanhuy12@7"
  }),
  );

  final data = jsonDecode(res.body);
  return data["token"];
  }
  static Future<Map<String, dynamic>> getTelemetry(
      String jwt, String deviceId) async {

    final url = Uri.parse(
        "$baseUrl/api/plugins/telemetry/DEVICE/$deviceId/values/timeseries?keys=temperature"
    );

    final res = await http.get(
      url,
      headers: {
        "X-Authorization": "Bearer $jwt"
      },
    );

    return jsonDecode(res.body);
  }
  }
