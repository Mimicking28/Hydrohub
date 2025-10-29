import 'package:flutter/material.dart';

class PendingOrders extends StatelessWidget {
  final int stationId; // ✅ required for consistency
  const PendingOrders({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      appBar: AppBar(
        title: const Text("Pending Orders"),
        backgroundColor: const Color(0xFF1B263B),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "This is the Pending Orders Page",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
