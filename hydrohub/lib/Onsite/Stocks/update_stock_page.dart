import 'package:flutter/material.dart';
import 'package:hydrohub/Onsite/Stocks/update_discard.dart';
import 'package:hydrohub/Onsite/Stocks/update_refilled.dart';
import '../../../widgets/custom_menu_button.dart';
import '../../../Onsite/home_page.dart';

class UpdateStock extends StatelessWidget {
  final int stationId;
  final int staffId; // ✅ Added staffId for backend linkage

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
                  // Profile Icon
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        // optional future profile feature
                      },
                      icon: const Icon(
                        Icons.account_circle,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // HydroHub Title
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

                  // Menu Buttons
                  CustomMenuButton(
                    icon: Icons.update_disabled_rounded,
                    label: "Update Refilled Stocks",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateRefilled(
                            stationId: stationId,
                            staffId: staffId,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  CustomMenuButton(
                    icon: Icons.delete_forever,
                    label: "Update Discarded Stocks",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateDiscard(
                            stationId: stationId,
                            staffId: staffId,
                          ),
                        ),
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
