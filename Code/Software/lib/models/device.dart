class Device {
  String id;
  String name;
  String type;
  String value;
  String? unit;

  String? linkedActuatorId;
  String? actuatorType;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.unit,
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
      linkedActuatorId: json["linkedActuatorId"],
      actuatorType: json["actuatorType"],
    );
  }
}
