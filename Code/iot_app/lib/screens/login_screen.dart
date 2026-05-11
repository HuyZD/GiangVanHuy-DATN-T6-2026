import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/node.dart';
import 'node_detail_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscure = true;

  void handleLogin() async {
    setState(() => isLoading = true);

    await Future.delayed(Duration(seconds: 2)); // giả lập API

    if (!mounted) return;

    setState(() => isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NodeDetailScreen(
          node: Node(
            id: "node-01",
            name: "Node",
            sensors: [
              Device(
                id: "tds",
                name: "TDS",
                type: "sensor",
                value: "--",
                unit: "ppm",
              ),
              Device(id: "ph", name: "PH", type: "sensor", value: "--"),
              Device(
                id: "light",
                name: "AS",
                type: "sensor",
                value: "--",
                unit: "lux",
              ),
              Device(
                id: "co2",
                name: "CO2",
                type: "sensor",
                value: "--",
                unit: "ppm",
              ),
              Device(
                id: "temperature",
                name: "Nhiệt độ",
                type: "sensor",
                value: "--",
                unit: "°C",
              ),
              Device(
                id: "humidity",
                name: "Độ ẩm",
                type: "sensor",
                value: "--",
                unit: "%",
              ),
            ],
            actuators: [
              Device(
                id: "RL1",
                name: "RL1",
                type: "actuator",
                value: "0",
                actuatorType: "relay",
              ),
              Device(
                id: "RL2",
                name: "RL2",
                type: "actuator",
                value: "0",
                actuatorType: "relay",
              ),
              Device(
                id: "AC",
                name: "Điều hòa",
                type: "actuator",
                value: "0",
                actuatorType: "ac",
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFA5D6A7), // xanh nhạt
              Color(0xFFE8F5E9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Icon(Icons.eco, size: 80, color: Colors.green),
                SizedBox(height: 10),
                Text(
                  "Smart Farm",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),

                SizedBox(height: 40),

                // Card form
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        TextField(
                          controller: passwordController,
                          obscureText: obscure,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() => obscure = !obscure);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    "Đăng nhập",
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),

                        SizedBox(height: 10),

                        TextButton(
                          onPressed: () {},
                          child: Text("Quên mật khẩu?"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
