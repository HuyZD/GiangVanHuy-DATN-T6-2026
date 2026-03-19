import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/farm.dart';
import '../widgets/farm_card.dart';
import 'gateway_list_screen.dart';
import './login_screen.dart';
import '../models/gateway.dart';
import '../models/node.dart';

class FarmListScreen extends StatefulWidget {
  @override
  _FarmListScreenState createState() => _FarmListScreenState();
}

class _FarmListScreenState extends State<FarmListScreen> {
  List<Farm> farms = [
    Farm(
      id: "1",
      name: "Farm Hà Nội",
      location: "Hoàn Kiếm",
      gateways: [
        Gateway(
          id: "1",
          name: "Gateway 01",
          status: "online",
          nodes: [
            Node(
              id: "1",
              name: "Node 01",
              sensors: [
                Device(id: "1", name: "Temperature", type: "sensor", value: "28°C"),
                Device(id: "2", name: "Humidity", type: "sensor", value: "70%"),
              ],
              actuators: [
                Device(id: "3", name: "Light", type: "actuator", value: "OFF"),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh sách nông trại"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.logout),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showAddFarmDialog(context);
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: farms.length,
        itemBuilder: (context, index) {
          return FarmCard(
            farm: farms[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GatewayListScreen(farm: farms[index]),
                ),
              );
            },
            onDelete: () {
              showDeleteDialog(index);
            },
            onEdit: () {
              showEditFarmDialog(index);
            },
          );
        },
      ),
    );
  }
  void showEditFarmDialog(int index) {
    final nameController =
    TextEditingController(text: farms[index].name);
    final locationController =
    TextEditingController(text: farms[index].location);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Sửa nông trại"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Tên"),
            ),
            TextField(
              controller: locationController,
              decoration: InputDecoration(labelText: "Địa điểm"),
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
                farms[index].name = nameController.text;
                farms[index].location = locationController.text;
              });
              Navigator.pop(context);
            },
            child: Text("Lưu"),
          ),
        ],
      ),
    );
  }
  void showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Xóa nông trại"),
        content: Text("Bạn có chắc muốn xóa không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                farms.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text("Xóa"),
          ),
        ],
      ),
    );
  }
  void showAddFarmDialog(BuildContext context) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Thêm nông trại"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Tên farm"),
            ),
            TextField(
              controller: locationController,
              decoration: InputDecoration(labelText: "Địa điểm"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              setState(() {
                farms.add(
                  Farm(
                    id: DateTime.now().toString(),
                    name: nameController.text,
                    location: locationController.text,
                    gateways: [],
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
