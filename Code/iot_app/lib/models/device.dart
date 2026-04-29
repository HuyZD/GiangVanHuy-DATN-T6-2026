class Device {
  String id;
  String name;
  String type;
  String value;
  String? unit;

  double? threshold;
  double? minThreshold;
  double? maxThreshold;
  String? linkedActuatorId;
  String? actuatorType;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.unit,
    this.threshold,
    this.minThreshold,
    this.maxThreshold,
    this.linkedActuatorId,
    this.actuatorType,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "type": type,
      "value": value,
      "unit": unit,
      "threshold": threshold,
      "minThreshold": minThreshold,
      "maxThreshold": maxThreshold,
      "linkedActuatorId": linkedActuatorId,
      "actuatorType": actuatorType,
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      type: json["type"] ?? "",
      value: json["value"] ?? "",
      unit: json["unit"],
      threshold: json["threshold"] == null
          ? null
          : double.tryParse(json["threshold"].toString()),
      minThreshold: json["minThreshold"] == null
          ? null
          : double.tryParse(json["minThreshold"].toString()),
      maxThreshold: json["maxThreshold"] == null
          ? null
          : double.tryParse(json["maxThreshold"].toString()),
      linkedActuatorId: json["linkedActuatorId"],
      actuatorType: json["actuatorType"],
    );
  }
}
