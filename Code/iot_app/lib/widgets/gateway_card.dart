import 'package:flutter/material.dart';
import '../models/gateway.dart';

class GatewayCard extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final Gateway gateway;


  const GatewayCard({
    Key? key,
    required this.gateway,
    this.onTap,
    this.onDelete,
    this.onEdit
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade700,
          child: Icon(Icons.router, color: Colors.white),
        ),
        title: Text(gateway.name),
        subtitle: Text("Status: ${gateway.status}"),
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
    );
  }
}