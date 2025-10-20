import 'package:flutter/material.dart';
import '../../../widgets/custom_menu_button.dart';
import '../../Delivery/home_page.dart';
import 'add_sales.dart';
import 'update_sales.dart';
import '../profile.dart'; // ✅ delivery profile page

class SalesPage extends StatelessWidget {
  final int stationId;
  final int staffId;

  const SalesPage({
    super.key,
    required this.stationId,
    required this.staffId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      body: Stack(
        children: [
          // 🌊 HydroHub glowing background
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
                  // 👤 Profile icon
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeliveryProfilePage(
                              stationId: stationId,
                              staffId: staffId,
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

                  // 💧 HydroHub header
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(
                            stationId: stationId,
                            staffId: staffId,
                          ),
                        ),
                      );
                    },
                    child: Center(
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

                  const SizedBox(height: 50),

                  // 💰 Add Sales
                  CustomMenuButton(
                    icon: Icons.add_shopping_cart,
                    label: "Add Sales",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddSale(
                            stationId: stationId,
                            staffId: staffId,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // 🧾 Update Sales
                  CustomMenuButton(
                    icon: Icons.receipt_long,
                    label: "Update Sales",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateSales(
                            stationId: stationId,
                            staffId: staffId,
                          ),
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
