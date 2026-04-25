class Device {
  String id;
  String name;
  String type;
  String value;

  double? threshold;
  String? linkedActuatorId;
  String? actuatorType;
  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.threshold,
    this.linkedActuatorId,
    this.actuatorType,
  });
}