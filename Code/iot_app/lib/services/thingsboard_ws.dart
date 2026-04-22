import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

class ThingsBoardService {
  static final ThingsBoardService instance = ThingsBoardService._internal();

  ThingsBoardService._internal();
  IOWebSocketChannel? _channel;

  Function(Map<String, dynamic>)? _onTelemetry;
  // CLOUD URL
  final String baseUrl = "https://thingsboard.cloud";
  // final String mqttHost = "mqtt.thingsboard.cloud";
  // final int mqttPort = 1883; // SSL

  String? jwtToken;
  // MqttServerClient? mqttClient;

  // -------------------------------------------------------------
  // LOGIN (email/password) → JWT token
  // -------------------------------------------------------------
  Future<bool> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/api/auth/login");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": email, "password": password}),
    );

    if (res.statusCode == 200) {
      jwtToken = jsonDecode(res.body)["token"];
      return true;
    }
    return false;
  }

  Map<String, String> _headers() => {
    "Content-Type": "application/json",
    "X-Authorization": "Bearer $jwtToken",
  };

  // -------------------------------------------------------------
  // GET ALL DEVICES IN TENANT (Gateway + Node + Farm)
  // -------------------------------------------------------------
  Future<List<dynamic>> getAllDevices() async {
    int page = 0;
    List devices = [];

    while (true) {
      final url = Uri.parse(
        "$baseUrl/api/tenant/devices?page=$page&pageSize=100",
      );

      final res = await http.get(url, headers: _headers());
      final data = jsonDecode(res.body);

      devices.addAll(data["data"]);

      if (data["hasNext"] == false) break;

      page++;
    }

    return devices;
  }

  // -------------------------------------------------------------
  // GET TELEMETRY OF A DEVICE
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> getTelemetry(String deviceId) async {
    final url = Uri.parse(
      "$baseUrl/api/plugins/telemetry/DEVICE/$deviceId/values/timeseries",
    );

    final res = await http.get(url, headers: _headers());
    return jsonDecode(res.body);
  }

  // -------------------------------------------------------------
  // GET ATTRIBUTES OF A DEVICE
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> getAttributes(String deviceId) async {
    final url = Uri.parse(
      "$baseUrl/api/plugins/telemetry/DEVICE/$deviceId/values/attributes",
    );

    final res = await http.get(url, headers: _headers());
    return jsonDecode(res.body);
  }

  // -------------------------------------------------------------
  // GET DEVICE ACCESS TOKEN (MUST FOR MQTT)
  // -------------------------------------------------------------
  Future<String> getDeviceAccessToken(String deviceId) async {
    final url = Uri.parse("$baseUrl/api/device/$deviceId/credentials");

    final res = await http.get(url, headers: _headers());
    return jsonDecode(res.body)["credentialsId"];
  }

  Future<bool> connect(String jwtToken) async {
    try {
      final url =
          "wss://thingsboard.cloud/api/ws/plugins/telemetry?token=$jwtToken";

      print("🌐 Connecting to WebSocket: $url");

      _channel = IOWebSocketChannel.connect(url);

      _channel!.stream.listen(
            (event) {
          final data = jsonDecode(event);
          // print("📥 WS EVENT: $data");

          // Extract realtime telemetry
          if (_onTelemetry != null &&
              data is Map &&
              data.containsKey("data")) {
            _onTelemetry!(data["data"]);
          }
        },
        onError: (e) {
          print("❌ WebSocket error: $e");
        },
        onDone: () {
          print("⚠️ WebSocket closed");
        },
      );

      return true;
    } catch (e) {
      print("❌ WS connect error: $e");
      return false;
    }
  }

  // ------------------------------------------------------------
  // SUBSCRIBE TO DEVICE TELEMETRY
  // ------------------------------------------------------------
  void subscribeDevice(String deviceId,
      Function(Map<String, dynamic>) callback) {
    _onTelemetry = callback;

    if (_channel == null) {
      print("❌ WebSocket not connected!");
      return;
    }

    final subMsg = {
      "tsSubCmds": [
        {
          "entityType": "DEVICE",
          "entityId": deviceId,
          "scope": "LATEST_TELEMETRY",
          "cmdId": 1
        }
      ],
      "historyCmds": [],
      "attrSubCmds": []
    };

    _channel!.sink.add(jsonEncode(subMsg));
    print("🔔 Subscribed to telemetry of device: $deviceId");
  }

  // ------------------------------------------------------------
  // DISCONNECT
  // ------------------------------------------------------------
  void disconnect() {
    _channel?.sink.close(ws_status.normalClosure);
    _channel = null;
  }
  // -------------------------------------------------------------
  // CONNECT MQTT (SSL) with DEVICE ACCESS TOKEN
  // -------------------------------------------------------------
  // Future<bool> connectMQTT(String accessToken) async {
  //   mqttClient = MqttServerClient.withPort(mqttHost, "", mqttPort);
  //
  //   mqttClient!.secure = false;
  //   mqttClient!.logging(on: false);
  //   mqttClient!.keepAlivePeriod = 30;
  //   // mqttClient!.securityContext = SecurityContext.defaultContext;
  //   mqttClient!.setProtocolV311();
  //
  //   final connMsg = MqttConnectMessage()
  //       .authenticateAs(accessToken, "")
  //       .startClean()
  //       .withWillQos(MqttQos.atLeastOnce);
  //
  //   mqttClient!.connectionMessage = connMsg;
  //
  //   try {
  //     await mqttClient!.connect();
  //     if (mqttClient!.connectionStatus?.state ==
  //         MqttConnectionState.connected) {
  //       print("✅ MQTT CONNECTED!");
  //       return true;
  //     } else {
  //       print(
  //         "❌ MQTT not connected. State = ${mqttClient!.connectionStatus?.state}",
  //       );
  //       return false;
  //     }
  //   } catch (e) {
  //     print('🔴 MQTT connect error: $e');
  //     mqttClient!.disconnect();
  //     return false;
  //   }
  // }

  // -------------------------------------------------------------
  // SUBSCRIBE REALTIME TELEMETRY
  // -------------------------------------------------------------
  // void subscribeTelemetry(Function(Map<String, dynamic>) callback) {
  //   if (mqttClient!.connectionStatus?.state != MqttConnectionState.connected) {
  //     print(
  //       '🔴 MQTT not connected. State: ${mqttClient!.connectionStatus?.state}',
  //     );
  //     mqttClient!.disconnect();
  //   }
  //
  //   // mqttClient!.subscribe("v1/devices/me/telemetry", MqttQos.atLeastOnce);
  //   print("📡 Subscribing telemetry...");
  //   mqttClient!.subscribe("v1/devices/me/telemetry", MqttQos.atLeastOnce);
  //   print("📡 Subscribed.");
  //
  //   mqttClient!.updates!.listen((events) {
  //     final payload = MqttPublishPayload.bytesToStringAsString(
  //       events[0].payload as Uint8Buffer,
  //     );
  //     try {
  //       final data = jsonDecode(payload) as Map<String, dynamic>;
  //       print("📡 data: $data");
  //
  //       callback(data);
  //     } catch (e) {
  //       print('🔴 Lỗi parse telemetry: $e');
  //     }
  //     // callback(jsonDecode(payload));
  //   });
  // }

  // -------------------------------------------------------------
  // SEND RPC COMMAND
  // -------------------------------------------------------------
  // Future<bool> sendRpc(String deviceId, Map body) async {
  //   final url = Uri.parse("$baseUrl/api/rpc/oneway/DEVICE/$deviceId");
  //
  //   final res = await http.post(
  //     url,
  //     headers: _headers(),
  //     body: jsonEncode(body),
  //   );
  //
  //   return res.statusCode == 200;
  // }

  // Future<bool> sendRpc(String deviceToken, Map<String, dynamic> body) async {
  //   final url = Uri.parse("$baseUrl/api/v1/$deviceToken/rpc?timeout=0");
  //
  //   try {
  //     final res = await http.post(
  //       url,
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode(body),
  //     );
  //
  //     print("📤 RPC SENT → $body");
  //     print("📥 RPC RESPONSE → ${res.statusCode}: ${res.body}");
  //
  //     return res.statusCode == 200;
  //   } catch (e) {
  //     print("❌ RPC ERROR: $e");
  //     return false;
  //   }
  // }
  Future<bool> sendRpc(String deviceId, Map<String, dynamic> body) async {
    // KHÔNG dùng /api/v1, KHÔNG có /DEVICE/
    final url = Uri.parse("$baseUrl/api/rpc/oneway/$deviceId");

    try {
      final res = await http.post(
        url,
        headers: _headers(),         // chứa JWT Bearer
        body: jsonEncode(body),
      );

      print("📤 RPC SENT → $body");
      print("📥 RPC RESPONSE → ${res.statusCode}: ${res.body}");

      // Server-side oneway RPC: chỉ cần 200 là OK
      return res.statusCode == 200;
    } catch (e) {
      print("❌ RPC ERROR: $e");
      return false;
    }
  }




  Future<Map<String, dynamic>> getTelemetryHistory(
      String deviceId,
      List<String> keys, {
        int lastHours = 1,
      }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final startTs = now - lastHours * 60 * 60 * 1000;

    final keysStr = keys.join(',');

    final url = Uri.parse(
      "$baseUrl/api/plugins/telemetry/DEVICE/$deviceId/values/timeseries"
          "?keys=$keysStr&startTs=$startTs&endTs=$now&limit=100&agg=NONE",
    );

    final res = await http.get(url, headers: _headers());

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      print("🔴 Lỗi getTelemetryHistory: ${res.statusCode} - ${res.body}");
      return {};
    }
  }
}