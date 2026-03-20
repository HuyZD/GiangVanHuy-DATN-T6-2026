import 'package:flutter/material.dart';
import '../models/device.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onThreshold;
  const DeviceCard({
    Key? key,
    required this.device,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.onThreshold, // 🔥 thêm
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  Icon(
                    device.type == "sensor"
                        ? Icons.sensors
                        : Icons.power,
                    size: 40,
                    color: Colors.green,
                  ),
                  SizedBox(height: 10),
                  Text(device.name),
                  SizedBox(height: 5),
                  Text(
                    device.value,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (device.threshold != null)
                    Text(
                      "Ngưỡng: ${device.threshold?.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),

            // 🔥 MENU 3 CHẤM
            Positioned(
              top: 0,
              right: 0,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == "edit") {
                    onEdit?.call();
                  } else if (value == "delete") {
                    onDelete?.call();
                  } else if (value == "threshold") {
                    onThreshold?.call();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: "edit", child: Text("Sửa")),
                  PopupMenuItem(value: "delete", child: Text("Xóa")),
                  PopupMenuItem(value: "threshold", child: Text("Thiết lập ngưỡng")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}