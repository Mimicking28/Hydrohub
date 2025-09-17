import 'package:flutter/material.dart';

class UpdateSales extends StatelessWidget {
  const UpdateSales({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales")),
      body: const Center(
        child: Text("This is the Update Sales Page"),
      ),
    );
  }
}