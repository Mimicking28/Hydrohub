import 'package:flutter/material.dart';
import 'package:hydrohub/Owner/Account/account_page.dart';
import 'package:hydrohub/Owner/Logs/logs_page.dart';
import 'package:hydrohub/Owner/Product/product_page.dart';
import 'package:hydrohub/Owner/profile.dart'; // ✅ Import profile page
import '../widgets/custom_menu_button.dart';

class HomePage extends StatelessWidget {
  final int stationId; // 🔹 The station assigned to this owner
  final int ownerId;
  const HomePage({super.key, required this.stationId, required this.ownerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526), // Dark background
      body: Stack(
        children: [
          // 🔵 Top-right ovals
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Column(
                  key: const ValueKey("home_main_view"),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 👤 Profile Icon aligned top-right
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => OwnerProfilePage(
                                ownerId: ownerId,
                                stationId: stationId,
                              ),
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                              transitionsBuilder:
                                  (_, animation, __, child) => FadeTransition(
                                opacity: animation,
                                child: child,
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
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => HomePage(
                                stationId: stationId,
                                ownerId: ownerId,
                              ),
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                              transitionsBuilder:
                                  (_, animation, __, child) => FadeTransition(
                                opacity: animation,
                                child: child,
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

                    // Buttons with animated navigation
                    CustomMenuButton(
                      icon: Icons.person,
                      label: "Accounts",
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => AccountPage(
                              stationId: stationId,
                              ownerId: ownerId,
                            ),
                            transitionDuration:
                                const Duration(milliseconds: 400),
                            transitionsBuilder:
                                (_, animation, __, child) => FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    CustomMenuButton(
                      icon: Icons.local_mall,
                      label: "Product",
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => ProductPage(
                              stationId: stationId,
                              ownerId: ownerId,
                            ),
                            transitionDuration:
                                const Duration(milliseconds: 400),
                            transitionsBuilder:
                                (_, animation, __, child) => FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    CustomMenuButton(
                      icon: Icons.history,
                      label: "Logs",
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => LogsPage(
                              stationId: stationId,
                              ownerId: ownerId,
                            ),
                            transitionDuration:
                                const Duration(milliseconds: 400),
                            transitionsBuilder:
                                (_, animation, __, child) => FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    CustomMenuButton(
                      icon: Icons.water_drop,
                      label: "Reports",
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => ProductPage(
                              stationId: stationId,
                              ownerId: ownerId,
                            ),
                            transitionDuration:
                                const Duration(milliseconds: 400),
                            transitionsBuilder:
                                (_, animation, __, child) => FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
