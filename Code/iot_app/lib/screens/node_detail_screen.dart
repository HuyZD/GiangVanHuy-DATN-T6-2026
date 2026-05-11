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

  late TabController _tabController;

  StreamSubscription<ThingsboardRealtimeUpdate>? realtimeSubscription;
  final Map<String, dynamic> sharedAttributeSnapshot = {};

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
                  onChanged: (value) async {
                    setState(() {
                      widget.node.autoMode = value;
                    });
                    await sendSharedAttributeUpdates({"autoMode": value});
                  },
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
        if (!widget.node.autoMode) ...[
          SizedBox(height: 16),
          buildThresholdPanel(),
        ],
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

  List<String> get sharedAttributeKeys => [
    "autoMode",
    airConditionerPowerKey,
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

      if (widget.node.autoMode) {
        for (var device in widget.node.actuators) {
          final value = update.telemetry[device.id];
          if (value != null) {
            device.value = value.toString();
          }
        }
      }
    });
  }

  num? parseThresholdValue(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
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
              onChanged: (newValues) {
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
              },
              onChangeEnd: (_) => sendSharedAttributeUpdates({
                minKey: widget.node.thresholds[minKey],
                maxKey: widget.node.thresholds[maxKey],
              }),
            ),
          ],
        ),
      ),
    );
  }

  void showACControlDialog(Device device) {
    // final savedTemp = int.tryParse(device.value);
    // int temp = savedTemp != null && savedTemp >= 16 && savedTemp <= 30
    //     ? savedTemp
    //     : 25;
    bool isOn = device.value != "0";

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

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Điều khiển điều hòa"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔥 ON/OFF
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Trạng thái"),
                    Switch(
                      value: isOn,
                      onChanged: (value) {
                        setStateDialog(() {
                          isOn = value;
                        });
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
                      onPressed: () async {
                        //  var shouldSendRpc = false;
                        //setStateDialog(() {
                        // if (temp > 16) {
                        //   temp--;
                        //   shouldSendRpc = true;
                        // }
                        // });
                        //  if (shouldSendRpc) {
                        await sendACRpc("decreaseAirConditionerTemp", true);
                        // }
                      },
                    ),

                    SizedBox(width: 20),

                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        // var shouldSendRpc = false;
                        // setStateDialog(() {
                        //   if (temp < 30) {
                        //     temp++;
                        //     shouldSendRpc = true;
                        //   }
                        // });
                        // if (shouldSendRpc) {
                        await sendACRpc("increaseAirConditionerTemp", true);
                        //}
                      },
                    ),
                  ],
                ),

                SizedBox(height: 10),

                Text(
                  isOn ? "Điều hòa đang bật" : "Điều hòa đang tắt",
                  style: TextStyle(
                    color: isOn ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Hủy"),
              ),

              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    device.value = isOn ? "1" : "0";
                  });
                  await sendSharedAttributeUpdates({
                    airConditionerPowerKey: isOn ? 1 : 0,
                  });
                  await sendACRpc("setAirConditionerPower", isOn ? 1 : 0);

                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text("Lưu"),
              ),
            ],
          );
        },
      ),
    );
  }
}
