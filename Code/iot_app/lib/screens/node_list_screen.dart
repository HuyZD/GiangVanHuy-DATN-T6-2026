import 'package:flutter/material.dart';
import '../models/gateway.dart';
import 'node_detail_screen.dart';
import '../models/node.dart';
import '../widgets/node_card.dart';
class NodeListScreen extends StatefulWidget {
  final Gateway gateway;

  NodeListScreen({required this.gateway});

  @override
  _NodeListScreenState createState() => _NodeListScreenState();
}

class _NodeListScreenState extends State<NodeListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gateway.name),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showAddNodeDialog(context);
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: widget.gateway.nodes.length,
        itemBuilder: (context, index) {
          final node = widget.gateway.nodes[index];

          return NodeCard(
            node: node,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NodeDetailScreen(node: node),
                ),
              );
            },
            onDelete: () {
              showDeleteNode(index);
            },
            onEdit: () {
              showEditNodeDialog(index);
            },
          );
        },
      ),
    );
  }
  void showEditNodeDialog(int index) {
    final controller =
    TextEditingController(text: widget.gateway.nodes[index].name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Sửa Node"),
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
                widget.gateway.nodes[index].name = controller.text;
              });
              Navigator.pop(context);
            },
            child: Text("Lưu"),
          ),
        ],
      ),
    );
  }
  void showDeleteNode(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Xóa Node"),
        content: Text("Bạn có chắc muốn xóa không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.gateway.nodes.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text("Xóa"),
          ),
        ],
      ),
    );
  }
  void showAddNodeDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Thêm Node"),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: "Tên Node"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.gateway.nodes.add(
                  Node(
                    id: DateTime.now().toString(),
                    name: nameController.text,
                    sensors: [],
                    actuators: [],
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