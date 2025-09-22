import 'package:flutter/material.dart';

class Accounts extends StatelessWidget {
  const Accounts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Accounts")),
      body: const Center(
        child: Text("This is the Account Page"),
      ),
    );
  }
}