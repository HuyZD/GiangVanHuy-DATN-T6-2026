import 'package:flutter/material.dart';
import '../models/node.dart';
import '../models/device.dart';
import '../widgets/device_card.dart';
import '../services/thingsboard_service.dart';
class NodeDetailScreen extends StatefulWidget {
  final Node node;

  NodeDetailScreen({required this.node});

  @override
  _NodeDetailScreenState createState() => _NodeDetailScreenState();
}

class _NodeDetailScreenState extends State<NodeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            // 🔥 TÊN NODE
            Text(widget.node.name),

            // 🔥 MODE + SWITCH
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddDeviceDialog(context);
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
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

            if (!widget.node.autoMode && devices[index].type == "actuator") {

              if (devices[index].actuatorType == "relay") {
                // 🔥 ON/OFF
                setState(() {
                  devices[index].value =
                  devices[index].value == "ON" ? "OFF" : "ON";
                });
              }

              else if (devices[index].actuatorType == "ac") {
                // 🔥 mở dialog chỉnh nhiệt độ
                showACControlDialog(devices[index]);
              }
            }
          },

          onDelete: () {
            showDeleteDeviceDialog(devices, index);
          },

          onEdit: () {
            showEditDeviceDialog(devices[index]);
          },

          onThreshold: () {
            if(devices[index].type == "sensor" && widget.node.autoMode == true){
            showThresholdDialog(devices[index]);
            }
          },
        );
      },
    );
  }

  void showThresholdDialog(Device device) {
    final controller =
    TextEditingController(text: device.threshold?.toString() ?? "");

    Device? selectedActuator =
    widget.node.actuators.isNotEmpty ? widget.node.actuators.first : null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Thiết lập ngưỡng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Ngưỡng"),
            ),

            SizedBox(height: 10),

            DropdownButtonFormField<Device>(
              value: selectedActuator,
              items: widget.node.actuators
                  .map((a) => DropdownMenuItem(
                value: a,
                child: Text(a.name),
              ))
                  .toList(),
              onChanged: (value) {
                selectedActuator = value;
              },
              decoration: InputDecoration(labelText: "Chọn actuator"),
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
                device.threshold = double.tryParse(controller.text);
                device.linkedActuatorId = selectedActuator?.id;
              });

              Navigator.pop(context);
            },
            child: Text("Lưu"),
          ),
        ],
      ),
    );
  }
  // ➕ ADD DEVICE
  void showAddDeviceDialog(BuildContext context) {

    final nameController = TextEditingController();
    String selectedType = "sensor";
    String selectedActuatorType = "relay";

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Thêm thiết bị"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Tên"),
                ),

                // 🔥 CHỌN SENSOR / ACTUATOR
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: [
                    DropdownMenuItem(value: "sensor", child: Text("Sensor")),
                    DropdownMenuItem(value: "actuator", child: Text("Actuator")),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedType = value!;
                    });
                  },
                ),

                // 🔥 CHỈ HIỆN KHI LÀ ACTUATOR
                if (selectedType == "actuator")
                  DropdownButtonFormField<String>(
                    value: selectedActuatorType,
                    items: [
                      DropdownMenuItem(
                          value: "relay", child: Text("Relay (ON/OFF)")),
                      DropdownMenuItem(
                          value: "ac", child: Text("Điều hòa (nhiệt độ)")),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedActuatorType = value!;
                      });
                    },
                    decoration:
                    InputDecoration(labelText: "Loại actuator"),
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
                    if (selectedType == "sensor") {
                      widget.node.sensors.add(
                        Device(
                          id: DateTime.now().toString(),
                          name: nameController.text,
                          type: "sensor",
                          value: "--",
                        ),
                      );
                    } else {
                      widget.node.actuators.add(
                        Device(
                          id: DateTime.now().toString(),
                          name: nameController.text,
                          type: "actuator",
                          value: selectedActuatorType == "relay" ? "OFF":"",
                          actuatorType: selectedActuatorType,
                        ),
                      );
                    }
                  });

                  Navigator.pop(context);
                },
                child: Text("Thêm"),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🗑️ DELETE
  void showDeleteDeviceDialog(List<Device> list, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Xóa thiết bị"),
        content: Text("Bạn có chắc muốn xóa không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                list.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text("Xóa"),
          ),
        ],
      ),
    );
  }

  // ✏️ EDIT
  void showEditDeviceDialog(Device device) {
    final controller = TextEditingController(text: device.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Sửa thiết bị"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: "Tên mới"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                device.name = controller.text;
              });
              Navigator.pop(context);
            },
            child: Text("Lưu"),
          ),
        ],
      ),
    );
  }
  void showACControlDialog(Device device) {
    int temp = int.tryParse(device.value) ?? 25;
    String mode = "cool"; // cool / dry / fan
    String fan = "auto"; // auto / low / high
    bool isOn = true;

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
                      onPressed: () {
                        setStateDialog(() {
                          if (temp > 16) temp--;
                        });
                      },
                    ),

                    Text(
                      "$temp°C",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setStateDialog(() {
                          if (temp < 30) temp++;
                        });
                      },
                    ),
                  ],
                ),

                SizedBox(height: 10),

                // ❄️ MODE
                DropdownButtonFormField<String>(
                  value: mode,
                  items: [
                    DropdownMenuItem(value: "cool", child: Text("Cool")),
                    DropdownMenuItem(value: "dry", child: Text("Dry")),
                    DropdownMenuItem(value: "fan", child: Text("Fan")),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      mode = value!;
                    });
                  },
                  decoration: InputDecoration(labelText: "Chế độ"),
                ),

                SizedBox(height: 10),

                // 💨 FAN SPEED
                DropdownButtonFormField<String>(
                  value: fan,
                  items: [
                    DropdownMenuItem(value: "auto", child: Text("Auto")),
                    DropdownMenuItem(value: "low", child: Text("Low")),
                    DropdownMenuItem(value: "high", child: Text("High")),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      fan = value!;
                    });
                  },
                  decoration: InputDecoration(labelText: "Quạt"),
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
                    device.value = "$temp"; // lưu nhiệt độ

                    // 🔥 bạn có thể lưu thêm nếu muốn:
                    // device.mode = mode;
                    // device.fan = fan;
                    // device.isOn = isOn;
                  });

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
