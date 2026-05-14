import 'device.dart';

class Node {
  String id;
  String name;
  List<Device> sensors;
  List<Device> actuators;

  bool autoMode;
  Map<String, num> thresholds;
  int airConditionerTemperature;

  static const Map<String, num> defaultThresholds = {
    "light_min": 1000,
    "light_max": 1500,
    "co2_max": 1000,
    "co2_safe": 800,
    "temp_max": 30,
    "temp_safe": 28,
    "humidity_max": 75,
    "humidity_safe": 70,
    "tds_min": 400,
    "tds_max": 800,
    "ph_min": 5.8,
    "ph_max": 6.5,
  };

  Node({
    required this.id,
    required this.name,
    required this.sensors,
    required this.actuators,
    this.autoMode = true,
    this.airConditionerTemperature = 20,
    Map<String, num>? thresholds,
  }) : thresholds = {
         ...defaultThresholds,
         if (thresholds != null) ...thresholds,
       };

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "sensors": sensors.map((device) => device.toJson()).toList(),
      "actuators": actuators.map((device) => device.toJson()).toList(),
      "autoMode": autoMode,
      "airConditionerTemperature": airConditionerTemperature,
      "thresholds": thresholds,
    };
  }

  factory Node.fromJson(Map<String, dynamic> json) {
    final rawThresholds = json["thresholds"] as Map?;
    final rawTemperature = json["airConditionerTemperature"];

    return Node(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      sensors: (json["sensors"] as List? ?? [])
          .map((device) => Device.fromJson(Map<String, dynamic>.from(device)))
          .toList(),
      actuators: (json["actuators"] as List? ?? [])
          .map((device) => Device.fromJson(Map<String, dynamic>.from(device)))
          .toList(),
      autoMode: json["autoMode"] ?? true,
      airConditionerTemperature: rawTemperature is num
          ? rawTemperature.round()
          : int.tryParse(rawTemperature.toString()) ?? 20,
      thresholds: rawThresholds?.map(
        (key, value) => MapEntry(
          key.toString(),
          value is num ? value : num.tryParse(value.toString()) ?? 0,
        ),
      ),
    );
  }
}
