import 'package:flutter/material.dart';
import '../../../widgets/custom_menu_button.dart';
import '../../../Delivery/home_page.dart';
import '../../Delivery/Stocks/update_delivery_stock.dart';
import '../../Delivery/Stocks/update_return_stock.dart';
import '../../../Delivery/profile.dart'; // ✅ Added profile navigation

class UpdateStock extends StatelessWidget {
  final int stationId;
  final int staffId;

  const UpdateStock({
    super.key,
    required this.stationId,
    required this.staffId,
  });

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
                color: const Color(0xFF6EACDA).withOpacity(0.3),
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
                color: const Color(0xFF6EACDA).withOpacity(0.3),
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
                color: Colors.white.withOpacity(0.08),
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
                  // 👤 Profile Icon (navigates to profile)
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

                  // 💧 HydroHub Title
                  Center(
                    child: GestureDetector(
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

                  // 🚚 Update Delivery Stocks
                  CustomMenuButton(
                    icon: Icons.local_shipping,
                    label: "Update Delivery Stocks",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateDeliveryStock(
                            stationId: stationId,
                            staffId: staffId,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 🔁 Update Return Stocks
                  CustomMenuButton(
                    icon: Icons.assignment_return,
                    label: "Update Return Stocks",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateReturnStock(
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
