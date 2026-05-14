import 'dart:async';

import 'package:flutter/material.dart';
import '../models/node.dart';
import '../models/device.dart';
import '../widgets/device_card.dart';
import '../services/thingsboard_service.dart';

String? jwt;

class NodeDetailScreen extends StatefulWidget {
  final Node node;
  final Future<void> Function() onDataChanged;

  NodeDetailScreen({
    super.key,
    required this.node,
    Future<void> Function()? onDataChanged,
  }) : onDataChanged = onDataChanged ?? (() async {});

  @override
  State<NodeDetailScreen> createState() => _NodeDetailScreenState();
}

class _NodeDetailScreenState extends State<NodeDetailScreen>
    with SingleTickerProviderStateMixin {
  static const String airConditionerPowerKey = "airConditionerPower";
  static const String airConditionerTemperatureKey = "airConditionerTemp";
  static const int minAirConditionerTemperature = 16;
  static const int maxAirConditionerTemperature = 30;

  late TabController _tabController;

  StreamSubscription<ThingsboardRealtimeUpdate>? realtimeSubscription;
  final Map<String, dynamic> sharedAttributeSnapshot = {};
  final Set<String> activeTelegramAlerts = {};
  bool isUpdatingMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initThingsboardData();
  }

  @override
  void dispose() {
    realtimeSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.node.name),
            Row(
              children: [
                Text(
                  widget.node.autoMode ? "Auto" : "Manual",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.node.autoMode ? Colors.green : Colors.black,
                  ),
                ),
                SizedBox(width: 10),
                Switch(
                  value: widget.node.autoMode,
                  onChanged: isUpdatingMode ? null : handleAutoModeChanged,
                ),
              ],
            ),
          ],
        ),

        // 🔥 TABBAR VẪN GIỮ
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Sensor"),
            Tab(text: "Actuator"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [buildSensorTab(), buildGrid(widget.node.actuators)],
      ),
    );
  }

  Widget buildSensorTab() {
    return ListView(
      padding: EdgeInsets.all(12),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: widget.node.sensors.length,
          itemBuilder: (context, index) {
            return DeviceCard(device: widget.node.sensors[index]);
          },
        ),
        SizedBox(height: 16),
        buildThresholdPanel(),
      ],
    );
  }

  // 📊 GRID HIỂN THỊ DEVICE
  Widget buildGrid(List<Device> devices) {
    return GridView.builder(
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        return DeviceCard(
          device: devices[index],
          onTap: () async {
            if (!widget.node.autoMode && devices[index].type == "actuator") {
              if (devices[index].actuatorType == "relay") {
                // 🔥 ON/OFF
                setState(() {
                  devices[index].value = devices[index].value == "1"
                      ? "0"
                      : "1";
                });
                widget.onDataChanged();
                if (jwt != null) {
                  await ThingsboardService.sendRPC(
                    jwt: jwt!,
                    deviceId: ThingsboardService.deviceId,
                    method: getRelayMethod(devices[index]),
                    params: devices[index].value == "1" ? 1 : 0,
                  );
                }
              } else if (devices[index].actuatorType == "ac") {
                // 🔥 mở dialog chỉnh nhiệt độ
                showACControlDialog(devices[index]);
              }
            }
          },
        );
      },
    );
  }

  String getRelayMethod(Device device) {
    switch (device.id) {
      case "RL1":
        return "setRelay1Status";
      case "RL2":
        return "setRelay2Status";
      default:
        return "setRelay1Status";
    }
  }

  // Future<void> initThingsBoard() async {
  //   bool ok = await ThingsBoardService.instance.login(
  //     "giangvanhuy84@gmail.com",
  //     "Giangvanhuy12@7",
  //   );
  //
  //   if (!ok) {
  //     print("login fail ! ");
  //   }
  //   else {
  //     print("login success ");
  //   }
  //
  //
  // }
  Future<void> initThingsboardData() async {
    jwt = await ThingsboardService.login();
    await loadSharedAttributes();
    startRealtimeUpdates();
  }

  Future<String?> ensureJwt() async {
    jwt ??= await ThingsboardService.login();
    return jwt;
  }

  Future<void> handleAutoModeChanged(bool value) async {
    setState(() {
      isUpdatingMode = true;
    });

    try {
      if (!value) {
        try {
          await refreshRelayStateFromTelemetry();
        } catch (error) {
          debugPrint("Failed to refresh relay telemetry before manual: $error");
        }
      }

      if (!mounted) return;

      setState(() {
        widget.node.autoMode = value;
      });
      await sendSharedAttributeUpdates({"autoMode": value});
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingMode = false;
        });
      }
    }
  }

  List<String> get sharedAttributeKeys => [
    "autoMode",
    airConditionerPowerKey,
    airConditionerTemperatureKey,
    ...Node.defaultThresholds.keys,
  ];

  Future<void> loadSharedAttributes() async {
    final currentJwt = jwt;
    if (currentJwt == null) return;

    final attributes = await ThingsboardService.getSharedAttributes(
      jwt: currentJwt,
      deviceId: ThingsboardService.deviceId,
      keys: sharedAttributeKeys,
    );

    if (!mounted) return;

    setState(() {
      final autoMode = attributes["autoMode"];
      if (autoMode != null) {
        widget.node.autoMode = autoMode == true || autoMode == "true";
      }

      applyAirConditionerPower(attributes[airConditionerPowerKey]);
      applyAirConditionerTemperature(attributes[airConditionerTemperatureKey]);

      for (final key in Node.defaultThresholds.keys) {
        final parsedValue = parseThresholdValue(attributes[key]);
        if (parsedValue != null) {
          widget.node.thresholds[key] = parsedValue;
        }
      }
    });
    sharedAttributeSnapshot
      ..clear()
      ..addAll(currentSharedAttributes());
  }

  void startRealtimeUpdates() {
    final currentJwt = jwt;
    if (currentJwt == null) return;

    realtimeSubscription?.cancel();
    realtimeSubscription =
        ThingsboardService.subscribeDeviceData(
          jwt: currentJwt,
          deviceId: ThingsboardService.deviceId,
        ).listen(
          applyRealtimeUpdate,
          onError: (error) {
            debugPrint("ThingsBoard realtime error: $error");
          },
          onDone: () {
            debugPrint("ThingsBoard realtime connection closed");
          },
        );
  }

  void applyRealtimeUpdate(ThingsboardRealtimeUpdate update) {
    if (!mounted) return;

    setState(() {
      final autoMode = update.attributes["autoMode"];
      if (autoMode != null) {
        widget.node.autoMode = autoMode == true || autoMode == "true";
      }

      applyAirConditionerPower(update.attributes[airConditionerPowerKey]);
      applyAirConditionerTemperature(
        update.attributes[airConditionerTemperatureKey],
      );

      for (final key in Node.defaultThresholds.keys) {
        final parsedValue = parseThresholdValue(update.attributes[key]);
        if (parsedValue != null) {
          widget.node.thresholds[key] = parsedValue;
        }
      }

      if (update.attributes.isNotEmpty) {
        sharedAttributeSnapshot.addAll(update.attributes);
      }

      for (var device in widget.node.sensors) {
        final value = update.telemetry[device.id.toUpperCase()];
        if (value != null) {
          device.value = value.toString();
        }
      }

      for (var device in widget.node.actuators) {
        if (device.id != "RL1" && device.id != "RL2") continue;

        final value = update.telemetry[device.id];
        if (value != null) {
          device.value = normalizeRelayValue(value) ?? value.toString();
        }
      }
    });

    if (update.telemetry.isNotEmpty) {
      unawaited(checkSensorAlerts());
    }
  }

  Future<void> refreshRelayStateFromTelemetry() async {
    final currentJwt = await ensureJwt();
    if (currentJwt == null) return;

    final telemetry = await ThingsboardService.getTelemetry(
      currentJwt,
      ThingsboardService.deviceId,
    );

    if (!mounted) return;

    setState(() {
      for (final device in widget.node.actuators) {
        if (device.id != "RL1" && device.id != "RL2") continue;

        final value = latestTelemetryValue(telemetry[device.id]);
        final relayValue = normalizeRelayValue(value);
        if (relayValue != null) {
          device.value = relayValue;
        }
      }
    });
  }

  dynamic latestTelemetryValue(dynamic telemetryValue) {
    if (telemetryValue is List && telemetryValue.isNotEmpty) {
      final latest = telemetryValue.first;
      if (latest is Map && latest.containsKey("value")) {
        return latest["value"];
      }
      return latest;
    }

    if (telemetryValue is Map && telemetryValue.containsKey("value")) {
      return telemetryValue["value"];
    }

    return telemetryValue;
  }

  String? normalizeRelayValue(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value ? "1" : "0";
    if (value is num) return value != 0 ? "1" : "0";
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == "1" || normalized == "true" || normalized == "on") {
        return "1";
      }
      if (normalized == "0" || normalized == "false" || normalized == "off") {
        return "0";
      }
    }
    return null;
  }

  num? parseThresholdValue(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  num? sensorValue(String sensorId) {
    for (final device in widget.node.sensors) {
      if (device.id.toLowerCase() != sensorId.toLowerCase()) continue;
      return num.tryParse(device.value);
    }
    return null;
  }

  String formatNumber(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  Future<void> checkSensorAlerts() async {
    await checkRangeAlert(
      sensorId: "tds",
      sensorName: "TDS",
      minKey: "tds_min",
      maxKey: "tds_max",
      unit: "ppm",
    );
    await checkRangeAlert(
      sensorId: "ph",
      sensorName: "PH",
      minKey: "ph_min",
      maxKey: "ph_max",
    );
    await checkRangeAlert(
      sensorId: "light",
      sensorName: "Ánh sáng",
      minKey: "light_min",
      maxKey: "light_max",
      unit: "lux",
    );
    await checkMaxAlert(
      sensorId: "co2",
      sensorName: "CO2",
      maxKey: "co2_max",
      unit: "ppm",
    );
    await checkMaxAlert(
      sensorId: "temperature",
      sensorName: "Nhiệt độ",
      maxKey: "temp_max",
      unit: "°C",
    );
    await checkMaxAlert(
      sensorId: "humidity",
      sensorName: "Độ ẩm",
      maxKey: "humidity_max",
      unit: "%",
    );
  }

  Future<void> checkRangeAlert({
    required String sensorId,
    required String sensorName,
    required String minKey,
    required String maxKey,
    String unit = "",
  }) async {
    final value = sensorValue(sensorId);
    final minValue = widget.node.thresholds[minKey];
    final maxValue = widget.node.thresholds[maxKey];

    if (value == null || minValue == null || maxValue == null) return;

    final alertPrefix = "$sensorId:";
    String? alertKey;
    String? message;
    final unitText = unit.isEmpty ? "" : " $unit";

    if (value < minValue) {
      alertKey = "$alertPrefix<";
      message =
          "CẢNH BÁO: $sensorName thấp hơn ngưỡng min\n"
          "Giá trị cảm biến: ${formatNumber(value)}$unitText\n"
          "Ngưỡng min: ${formatNumber(minValue)}$unitText";
    } else if (value > maxValue) {
      alertKey = "$alertPrefix>";
      message =
          "CẢNH BÁO: $sensorName lớn hơn ngưỡng max\n"
          "Giá trị cảm biến: ${formatNumber(value)}$unitText\n"
          "Ngưỡng max: ${formatNumber(maxValue)}$unitText";
    }

    if (alertKey == null || message == null) {
      activeTelegramAlerts.removeWhere((key) => key.startsWith(alertPrefix));
      return;
    }

    if (activeTelegramAlerts.contains(alertKey)) return;

    activeTelegramAlerts
      ..removeWhere((key) => key.startsWith(alertPrefix))
      ..add(alertKey);

    try {
      await ThingsboardService.sendTelegramMessage(message);
    } catch (error) {
      activeTelegramAlerts.remove(alertKey);
      debugPrint("Failed to send Telegram alert: $error");
    }
  }

  Future<void> checkMaxAlert({
    required String sensorId,
    required String sensorName,
    required String maxKey,
    String unit = "",
  }) async {
    final value = sensorValue(sensorId);
    final maxValue = widget.node.thresholds[maxKey];

    if (value == null || maxValue == null) return;

    final alertPrefix = "$sensorId:";
    final alertKey = "$alertPrefix>";
    final unitText = unit.isEmpty ? "" : " $unit";

    if (value <= maxValue) {
      activeTelegramAlerts.removeWhere((key) => key.startsWith(alertPrefix));
      return;
    }

    if (activeTelegramAlerts.contains(alertKey)) return;

    activeTelegramAlerts
      ..removeWhere((key) => key.startsWith(alertPrefix))
      ..add(alertKey);

    final message =
        "CẢNH BÁO: $sensorName lớn hơn ngưỡng max\n"
        "Giá trị cảm biến: ${formatNumber(value)}$unitText\n"
        "Ngưỡng max: ${formatNumber(maxValue)}$unitText";

    try {
      await ThingsboardService.sendTelegramMessage(message);
    } catch (error) {
      activeTelegramAlerts.remove(alertKey);
      debugPrint("Failed to send Telegram alert: $error");
    }
  }

  int? parseTemperatureValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool? parsePowerValue(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == "1" || normalized == "true" || normalized == "on") {
        return true;
      }
      if (normalized == "0" || normalized == "false" || normalized == "off") {
        return false;
      }
    }
    return null;
  }

  Device? findAirConditioner() {
    for (final device in widget.node.actuators) {
      if (device.actuatorType == "ac") {
        return device;
      }
    }
    return null;
  }

  void applyAirConditionerPower(dynamic value) {
    final isOn = parsePowerValue(value);
    if (isOn == null) return;

    final airConditioner = findAirConditioner();
    if (airConditioner != null) {
      airConditioner.value = isOn ? "1" : "0";
    }
  }

  void applyAirConditionerTemperature(dynamic value) {
    final temperature = parseTemperatureValue(value);
    if (temperature == null || temperature < minAirConditionerTemperature) {
      return;
    }

    widget.node.airConditionerTemperature = temperature.clamp(
      minAirConditionerTemperature,
      maxAirConditionerTemperature,
    );
  }

  double thresholdValue(String key) {
    return (widget.node.thresholds[key] ?? Node.defaultThresholds[key]!)
        .toDouble();
  }

  Map<String, dynamic> currentSharedAttributes() {
    final airConditioner = findAirConditioner();

    return {
      "autoMode": widget.node.autoMode,
      if (airConditioner != null)
        airConditionerPowerKey: airConditioner.value == "1" ? 1 : 0,
      airConditionerTemperatureKey: widget.node.airConditionerTemperature,
      ...widget.node.thresholds,
    };
  }

  bool isSameSharedAttributeValue(dynamic currentValue, dynamic nextValue) {
    if (currentValue is num && nextValue is num) {
      return currentValue == nextValue;
    }
    final currentPower = parsePowerValue(currentValue);
    final nextPower = parsePowerValue(nextValue);
    if (currentPower != null && nextPower != null) {
      return currentPower == nextPower;
    }
    final currentNumber = parseThresholdValue(currentValue);
    final nextNumber = parseThresholdValue(nextValue);
    if (currentNumber != null && nextNumber != null) {
      return currentNumber == nextNumber;
    }
    return currentValue == nextValue;
  }

  Future<void> sendSharedAttributeUpdates(
    Map<String, dynamic> requestedUpdates,
  ) async {
    final changedUpdates = <String, dynamic>{};

    for (final entry in requestedUpdates.entries) {
      if (!isSameSharedAttributeValue(
        sharedAttributeSnapshot[entry.key],
        entry.value,
      )) {
        changedUpdates[entry.key] = entry.value;
      }
    }

    if (changedUpdates.isEmpty) return;

    widget.onDataChanged();

    final currentJwt = await ensureJwt();
    if (currentJwt == null) return;

    await ThingsboardService.sendSharedAttributes(
      jwt: currentJwt,
      deviceId: ThingsboardService.deviceId,
      data: changedUpdates,
    );

    sharedAttributeSnapshot.addAll(changedUpdates);
  }

  Widget buildThresholdPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Sensor Threshold",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        buildRangeThresholdControl(
          title: "Light",
          minKey: "light_min",
          maxKey: "light_max",
          min: 0,
          max: 5000,
          divisions: 100,
          unit: "lux",
        ),
        buildRangeThresholdControl(
          title: "CO2",
          minKey: "co2_safe",
          maxKey: "co2_max",
          minLabel: "Safe",
          maxLabel: "Max",
          min: 0,
          max: 3000,
          divisions: 60,
          unit: "ppm",
        ),
        buildRangeThresholdControl(
          title: "Temperature",
          minKey: "temp_safe",
          maxKey: "temp_max",
          minLabel: "Safe",
          maxLabel: "Max",
          min: 0,
          max: 50,
          divisions: 50,
          unit: "C",
        ),
        buildRangeThresholdControl(
          title: "Humidity",
          minKey: "humidity_safe",
          maxKey: "humidity_max",
          minLabel: "Safe",
          maxLabel: "Max",
          min: 0,
          max: 100,
          divisions: 100,
          unit: "%",
        ),
        buildRangeThresholdControl(
          title: "TDS",
          minKey: "tds_min",
          maxKey: "tds_max",
          min: 0,
          max: 2000,
          divisions: 100,
          unit: "ppm",
        ),
        buildRangeThresholdControl(
          title: "pH",
          minKey: "ph_min",
          maxKey: "ph_max",
          min: 0,
          max: 14,
          divisions: 140,
          fractionDigits: 1,
        ),
      ],
    );
  }

  Widget buildRangeThresholdControl({
    required String title,
    required String minKey,
    required String maxKey,
    required double min,
    required double max,
    required int divisions,
    String minLabel = "Min",
    String maxLabel = "Max",
    String unit = "",
    int fractionDigits = 0,
  }) {
    final start = thresholdValue(minKey).clamp(min, max).toDouble();
    final end = thresholdValue(maxKey).clamp(min, max).toDouble();
    final values = RangeValues(
      start <= end ? start : end,
      end >= start ? end : start,
    );

    String formatValue(double value) {
      final text = value.toStringAsFixed(fractionDigits);
      return unit.isEmpty ? text : "$text $unit";
    }

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Flexible(
                  child: Text(
                    "$minLabel ${formatValue(values.start)} - "
                    "$maxLabel ${formatValue(values.end)}",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: values,
              min: min,
              max: max,
              divisions: divisions,
              labels: RangeLabels(
                formatValue(values.start),
                formatValue(values.end),
              ),
              onChanged: widget.node.autoMode
                  ? (newValues) {
                      setState(() {
                        widget.node.thresholds[minKey] = fractionDigits == 0
                            ? newValues.start.round()
                            : double.parse(
                                newValues.start.toStringAsFixed(fractionDigits),
                              );
                        widget.node.thresholds[maxKey] = fractionDigits == 0
                            ? newValues.end.round()
                            : double.parse(
                                newValues.end.toStringAsFixed(fractionDigits),
                              );
                      });
                    }
                  : null,
              onChangeEnd: widget.node.autoMode
                  ? (_) => sendSharedAttributeUpdates({
                      minKey: widget.node.thresholds[minKey],
                      maxKey: widget.node.thresholds[maxKey],
                    })
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void showACControlDialog(Device device) {
    bool isOn = device.value != "0";
    int temperature = widget.node.airConditionerTemperature.clamp(
      minAirConditionerTemperature,
      maxAirConditionerTemperature,
    );

    Future<void> sendACRpc(String method, dynamic params) async {
      final currentJwt = await ensureJwt();
      if (currentJwt == null) return;

      await ThingsboardService.sendRPC(
        jwt: currentJwt,
        deviceId: ThingsboardService.deviceId,
        method: method,
        params: params,
      );
    }

    Future<void> saveAirConditionerTemperature(int value) async {
      setState(() {
        widget.node.airConditionerTemperature = value;
      });
      await sendSharedAttributeUpdates({airConditionerTemperatureKey: value});
    }

    Future<void> saveAirConditionerPower(bool value) async {
      final temperatureToSend = value ? temperature : -1;

      setState(() {
        device.value = value ? "1" : "0";
        if (value) {
          widget.node.airConditionerTemperature = temperature;
        }
      });

      await sendSharedAttributeUpdates({
        airConditionerPowerKey: value ? 1 : 0,
        airConditionerTemperatureKey: temperatureToSend,
      });
      await sendACRpc("setAirConditionerPower", value ? 1 : 0);
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Điều khiển điều hòa"),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔥 ON/OFF
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Switch(
                      value: isOn,
                      onChanged: (value) async {
                        setStateDialog(() {
                          isOn = value;
                        });
                        await saveAirConditionerPower(value);
                      },
                    ),
                  ],
                ),

                SizedBox(height: 10),

                // 🌡️ NHIỆT ĐỘ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed:
                          !isOn || temperature <= minAirConditionerTemperature
                          ? null
                          : () async {
                              final nextTemperature = temperature - 1;
                              setStateDialog(() {
                                temperature = nextTemperature;
                              });
                              await saveAirConditionerTemperature(
                                nextTemperature,
                              );
                              await sendACRpc(
                                "decreaseAirConditionerTemp",
                                true,
                              );
                            },
                    ),

                    SizedBox(
                      width: 72,
                      child: Text(
                        "$temperature°C",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isOn ? Colors.green.shade700 : Colors.grey,
                        ),
                      ),
                    ),

                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed:
                          !isOn || temperature >= maxAirConditionerTemperature
                          ? null
                          : () async {
                              final nextTemperature = temperature + 1;
                              setStateDialog(() {
                                temperature = nextTemperature;
                              });
                              await saveAirConditionerTemperature(
                                nextTemperature,
                              );
                              await sendACRpc(
                                "increaseAirConditionerTemp",
                                true,
                              );
                            },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
