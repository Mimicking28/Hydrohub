import 'package:flutter/material.dart';
import 'Delivery/home_page.dart';

void main() {
  runApp(const HydroHubApp());
}

class HydroHubApp extends StatelessWidget {
  const HydroHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydroHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const HomePage(),
    );
  }
}
