import 'package:flutter/material.dart';
import 'package:hydrohub/Administrator/Logs/order_logs.dart';
import 'package:hydrohub/Administrator/Logs/product_logs.dart';
import 'package:hydrohub/Administrator/Logs/sale_logs.dart';
import 'package:hydrohub/Administrator/Logs/stock_logs.dart';
import 'package:hydrohub/Administrator/profile.dart';
import '../../../widgets/custom_menu_button.dart';
import '../home_page.dart';
import 'package:hydrohub/Sessions/admin_session.dart';


class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526), // Dark background
      body: Stack(
        children: [
          // 🔵 Top-right oval
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF6EACDA).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          // 🔵 Slightly lower top-right oval
          Positioned(
            top: -10,
            right: -80,
            child: Container(
              width: 160,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF6EACDA).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          // 🔵 Bottom-left oval
          Positioned(
            bottom: -60,
            left: -80,
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(140),
              ),
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Icon aligned top-right
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                     onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (context) => AdminProfilePage(
                            adminId: AdminSession.adminId!, // 👈 Pass current admin’s ID
                          ),
                        ),
                          );
                        },
                      icon: const Icon(
                        Icons.account_circle,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // HydroHub Title centered
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomePage()),
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
                          children: <TextSpan>[
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

                  // Buttons
                  CustomMenuButton(
                    icon: Icons.attach_money,
                    label: "Sales Logs",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SalesLogs()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomMenuButton(
                    icon: Icons.local_shipping,
                    label: "Order Logs",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrderLogs()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomMenuButton(
                    icon: Icons.inventory,
                    label: "Inventory Logs",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StockLogs()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomMenuButton(
                    icon: Icons.menu,
                    label: "Product Logs",   
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductLogs()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

