import 'package:flutter/material.dart';
import 'package:hydrohub/Onsite/Order/pending_orders.dart';
import 'package:hydrohub/Onsite/Order/to_deliver.dart';
import '../../widgets/custom_menu_button.dart';
import '../home_page.dart';

class OrdersPage extends StatelessWidget {
  final int stationId; // ✅ The station assigned to this onsite
  const OrdersPage({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      body: Stack(
        children: [
          // 🔵 Background Decorations
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF6EACDA).withOpacity(0.3),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Positioned(
            top: -10,
            right: -80,
            child: Container(
              width: 160,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF6EACDA).withOpacity(0.3),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -80,
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(140),
              ),
            ),
          ),

          // Foreground content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile icon
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        // Future: Add profile navigation
                      },
                      icon: const Icon(
                        Icons.account_circle,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // HydroHub title
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HomePage(stationId: stationId, staffId: 0),
                          ),
                        );
                      },
                      child: Text.rich(
                        TextSpan(
                          text: 'Hydro',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(
                              text: 'Hub',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // 🔹 Pending Orders
                  CustomMenuButton(
                    icon: Icons.pending_actions,
                    label: "Pending Orders",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PendingOrders(stationId: stationId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Delivery List
                  CustomMenuButton(
                    icon: Icons.local_shipping,
                    label: "Delivery List",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ToDeliver(stationId: stationId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
