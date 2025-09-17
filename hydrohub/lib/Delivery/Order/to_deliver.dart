import 'package:flutter/material.dart';

class ToDeliver extends StatelessWidget {
  const ToDeliver({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orders")),
      body: const Center(
        child: Text("This is the To deliver Page"),
      ),
    );
  }
}