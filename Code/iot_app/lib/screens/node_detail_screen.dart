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
  late TabController _tabController;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initThingsboardData();

    timer = Timer.periodic(Duration(seconds: 5), (t) {
      fetchDataFromThingsboard();
    });
  }

  @override
  void dispose() {
    timer?.cancel(); // 🔥 cực quan trọng
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
                    widget.onDataChanged();
                    final currentJwt = await ensureJwt();
                    if (currentJwt != null) {
                      await ThingsboardService.sendSharedAttributes(
                        jwt: currentJwt,
                        deviceId: ThingsboardService.deviceId,
                        data: {"autoMode": value},
                      );
                    }
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
        children: [
          buildGrid(widget.node.sensors),
          buildGrid(widget.node.actuators),
        ],
      ),
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
          autoMode: widget.node.autoMode,
          onTap: () async {
            if (widget.node.autoMode && devices[index].type == "sensor") {
              showThresholdDialog(devices[index]);
              return;
            }

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
      case "RL3":
        return "setRelay3Status";
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
  }

  Future<String?> ensureJwt() async {
    jwt ??= await ThingsboardService.login();
    return jwt;
  }

  List<String> get sharedAttributeKeys {
    final thresholdKeys = widget.node.sensors.expand(
      (device) => ["threshold_${device.id}_min", "threshold_${device.id}_max"],
    );

    return ["autoMode", ...thresholdKeys];
  }

  double? parseAttributeDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

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

      for (final device in widget.node.sensors) {
        device.minThreshold = parseAttributeDouble(
          attributes["threshold_${device.id}_min"],
        );
        device.maxThreshold = parseAttributeDouble(
          attributes["threshold_${device.id}_max"],
        );
      }
    });
  }

  Future<void> fetchDataFromThingsboard() async {
    if (jwt == null) return;

    var data = await ThingsboardService.getTelemetry(
      jwt!,
      ThingsboardService.deviceId,
    );

    setState(() {
      for (var device in widget.node.sensors) {
        String key = device.id.toUpperCase();

        device.value = data[key]?[0]?["value"] ?? "--";
      }
      if (widget.node.autoMode) {
        for (var device in widget.node.actuators) {
          String key = device.id;

          device.value = data[key]?[0]?["value"] ?? "--";
        }
      }
    });
  }

  void showThresholdDialog(Device device) {
    final unit = device.unit == null ? "" : " (${device.unit})";
    final minController = TextEditingController(
      text: device.minThreshold?.toString() ?? "",
    );
    final maxController = TextEditingController(
      text: device.maxThreshold?.toString() ?? "",
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Set ngưỡng ${device.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Min$unit"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: maxController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Max$unit"),
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
              final minValue = double.tryParse(minController.text);
              final maxValue = double.tryParse(maxController.text);

              if (minValue == null ||
                  maxValue == null ||
                  minValue >= maxValue) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Ngưỡng không hợp lệ")));
                return;
              }

              setState(() {
                device.minThreshold = minValue;
                device.maxThreshold = maxValue;
              });
              widget.onDataChanged();

              final currentJwt = await ensureJwt();
              if (currentJwt != null) {
                await ThingsboardService.sendSharedAttributes(
                  jwt: currentJwt,
                  deviceId: ThingsboardService.deviceId,
                  data: {
                    "threshold_${device.id}_min": minValue,
                    "threshold_${device.id}_max": maxValue,
                  },
                );
              }

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text("Lưu"),
          ),
        ],
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
                      onChanged: (value) async {
                        setStateDialog(() {
                          isOn = value;
                        });
                        await sendACRpc("setACStatus", value ? 1 : 0);
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
                          await sendACRpc("decreaseAC", true);
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
                          await sendACRpc("increaseAC", true);
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
                onPressed: () {
                  setState(() {
                   // device.value = isOn ? "$temp" : "0";
                  });
                  widget.onDataChanged();

                  Navigator.pop(context);
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
