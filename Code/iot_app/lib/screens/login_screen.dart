import 'package:flutter/material.dart';
import 'farm_list_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscure = true;

  void handleLogin() async {
    setState(() => isLoading = true);

    await Future.delayed(Duration(seconds: 2)); // giả lập API

    setState(() => isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => FarmListScreen()),
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
                              icon: Icon(obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off),
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
                                ? CircularProgressIndicator(
                              color: Colors.white,
                            )
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
                        )
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