import 'package:flutter/material.dart';

class PendingOrders extends StatelessWidget {
  final int stationId;
  final int staffId; // ✅ Add this

  const PendingOrders({
    super.key,
    required this.stationId,
    required this.staffId, // ✅ Include it
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Orders",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF021526),
      body: const Center(
        child: Text(
          "This is the To Deliver Page",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
