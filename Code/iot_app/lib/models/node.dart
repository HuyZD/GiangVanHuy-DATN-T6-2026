import 'device.dart';

class Node {
  String id;
  String name;
  List<Device> sensors;
  List<Device> actuators;

  bool autoMode;

  Node({
    required this.id,
    required this.name,
    required this.sensors,
    required this.actuators,
    this.autoMode = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "sensors": sensors.map((device) => device.toJson()).toList(),
      "actuators": actuators.map((device) => device.toJson()).toList(),
      "autoMode": autoMode,
    };
  }

  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      sensors: (json["sensors"] as List? ?? [])
          .map((device) => Device.fromJson(Map<String, dynamic>.from(device)))
          .toList(),
      actuators: (json["actuators"] as List? ?? [])
          .map((device) => Device.fromJson(Map<String, dynamic>.from(device)))
          .toList(),
      autoMode: json["autoMode"] ?? false,
    );
  }
}
