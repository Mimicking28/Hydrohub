import 'package:flutter/material.dart';
import 'package:hydrohub/Customer/Product/cart.dart';
import 'package:hydrohub/Customer/Product/order.dart';
import 'package:hydrohub/Customer/Profile/profile.dart';
import 'package:hydrohub/Screen/splash_page.dart';
import 'package:hydrohub/Customer/home_page.dart';

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
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const CustomerHomePage(),
        '/cart': (context) => const CartPage(),
        '/orders': (context) => const OrdersPage(),
        '/profile': (context) => const CustomerProfilePage(),
      },
    );
  }
}
