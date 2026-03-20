import 'package:flutter/material.dart';
import '../models/farm.dart';

class FarmCard extends StatelessWidget {
  final Farm farm;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FarmCard({
    Key? key,
    required this.farm,
    required this.onTap,
    this.onEdit,
    this.onDelete,
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
            child: Icon(Icons.agriculture, color: Colors.white),
          ),
          title: Text(farm.name),
          subtitle: Text(farm.location),
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