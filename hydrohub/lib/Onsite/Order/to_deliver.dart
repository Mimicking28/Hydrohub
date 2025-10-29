import 'package:flutter/material.dart';

class ToDeliver extends StatelessWidget {
  final int stationId; // ✅ matches OrdersPage navigation
  const ToDeliver({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      appBar: AppBar(
        title: const Text("To Deliver"),
        backgroundColor: const Color(0xFF1B263B),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "This is the To Deliver Page",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
