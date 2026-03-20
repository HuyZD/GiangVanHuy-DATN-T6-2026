import 'package:flutter/material.dart';
import '../models/node.dart';
import '../models/device.dart';
import '../widgets/device_card.dart';

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
        title: Text(widget.node.name),
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

          onTap: () {
            if (devices[index].type == "actuator") {
              setState(() {
                devices[index].value =
                devices[index].value == "ON" ? "OFF" : "ON";
              });
            }
          },

          onDelete: () {
            showDeleteDeviceDialog(devices, index);
          },

          onEdit: () {
            showEditDeviceDialog(devices[index]);
          },

          onThreshold: () {
            showThresholdDialog(devices[index]);
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Thêm thiết bị"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Tên"),
            ),
            DropdownButtonFormField<String>(
              value: selectedType,
              items: [
                DropdownMenuItem(value: "sensor", child: Text("Sensor")),
                DropdownMenuItem(value: "actuator", child: Text("Actuator")),
              ],
              onChanged: (value) {
                selectedType = value!;
              },
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
                      value: "OFF",
                    ),
                  );
                }
              });
              Navigator.pop(context);
            },
            child: Text("Thêm"),
          ),
        ],
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
}