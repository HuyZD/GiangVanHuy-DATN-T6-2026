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
}