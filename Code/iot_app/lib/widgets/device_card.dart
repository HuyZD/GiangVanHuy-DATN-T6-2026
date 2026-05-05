import 'package:flutter/material.dart';
import '../models/device.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  IconData get deviceIcon {
    if (device.type != "sensor") {
      return device.actuatorType == "relay"
          ? Icons.power
          : Icons.settings_remote;
    }

    switch (device.id.toLowerCase()) {
      case "tds":
        return Icons.water_drop;
      case "ph":
        return Icons.science;
      case "as":
      case "light":
        return Icons.wb_sunny;
      case "co2":
        return Icons.cloud;
      case "temperature":
        return Icons.thermostat;
      case "humidity":
        return Icons.water;
      default:
        return Icons.sensors;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showMenu = onEdit != null || onDelete != null;
    final unit = device.unit ?? "";
    final sensorValue = unit.isEmpty || device.value == "--"
        ? device.value
        : "${device.value} $unit";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // nội dung chính
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(deviceIcon, size: 40, color: Colors.green),
                  SizedBox(height: 10),
                  Text(device.name),
                  SizedBox(height: 5),
                  Text(
                    device.type == "sensor"
                        ? sensorValue
                        : device.actuatorType == "ac"
                        ? (device.value == "0"
                              ? "OFF"
                              : (device.value.isEmpty ? "--" : "ON"))
                        : (device.value == "1" ? "ON" : "OFF"),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            if (showMenu)
              Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == "edit") {
                      onEdit?.call();
                    } else if (value == "delete") {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) {
                    List<PopupMenuEntry<String>> items = [];

                    if (onEdit != null) {
                      items.add(
                        PopupMenuItem(value: "edit", child: Text("Sửa")),
                      );
                    }

                    if (onDelete != null) {
                      items.add(
                        PopupMenuItem(value: "delete", child: Text("Xóa")),
                      );
                    }

                    return items;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
