import 'package:flutter/material.dart';
import '../models/farm.dart';
import '../models/gateway.dart';
import '../widgets/gateway_card.dart';
import './node_list_screen.dart';
import '../widgets/gateway_card.dart';
class GatewayListScreen extends StatefulWidget {
  final Farm farm;

  GatewayListScreen({required this.farm});

  @override
  _GatewayListScreenState createState() => _GatewayListScreenState();
}
class _GatewayListScreenState extends State<GatewayListScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farm.name),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showAddGatewayDialog(context);
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: widget.farm.gateways.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NodeListScreen(
                    gateway: widget.farm.gateways[index],
                  ),
                ),
              );
            },
            child: GatewayCard(
              gateway: widget.farm.gateways[index],
              onDelete: () {
                showDeleteGateway(index);
              },
              onEdit: () {
                showEditGatewayDialog(index);
              },
            ),
          );
        },
      ),
    );
  }
  void showEditGatewayDialog(int index) {
    final controller =
    TextEditingController(text: widget.farm.gateways[index].name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Sửa Gateway"),
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
                widget.farm.gateways[index].name = controller.text;
              });
              Navigator.pop(context);
            },
            child: Text("Lưu"),
          ),
        ],
      ),
    );
  }
  void showDeleteGateway(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Xóa Gateway"),
        content: Text("Bạn có chắc không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.farm.gateways.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text("Xóa"),
          ),
        ],
      ),
    );
  }
  void showAddGatewayDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text("Thêm Gateway"),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: "Tên Gateway"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () {
              setState(() {
                widget.farm.gateways.add(
                  Gateway(
                    id: DateTime.now().toString(),
                    name: nameController.text,
                    status: "offline",
                    nodes: []
                  ),
                );
              });

              Navigator.pop(context);
            },
            child: Text("Thêm"),
          ),
        ],
      ),
    );
  }
}