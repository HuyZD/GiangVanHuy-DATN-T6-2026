import 'package:flutter/material.dart';
import '../models/node.dart';

class NodeCard extends StatelessWidget {
  final Node node;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const NodeCard({
    Key? key,
    required this.node,
    required this.onTap,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.memory, color: Colors.white),
          ),
          title: Text(node.name),
          subtitle: Text(
              "Sensors: ${node.sensors.length} | Actuators: ${node.actuators.length}"),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "edit") {
                onEdit?.call();
              } else if (value == "delete") {
                onDelete?.call();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: "edit", child: Text("Sửa")),
              PopupMenuItem(value: "delete", child: Text("Xóa")),
            ],
          ),
        ),
      ),
    );
  }
}