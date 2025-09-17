import 'package:flutter/material.dart';

class PendingOrders extends StatelessWidget {
  const PendingOrders({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orders")),
      body: const Center(
        child: Text("This is the Pending Orders Page"),
      ),
    );
  }
}