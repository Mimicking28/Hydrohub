import 'package:flutter/material.dart';
import '../../../widgets/custom_menu_button.dart';
import '../home_page.dart';
import 'add_sales.dart';
import 'update_sales.dart';

class SalesPage extends StatefulWidget {
  final int stationId;
  final int staffId;

  const SalesPage({
    super.key,
    required this.stationId,
    required this.staffId,
  });

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🔹 Smooth slide-in transition to a new page
  Route _createRoute(Widget page, {Offset beginOffset = const Offset(1.0, 0.0)}) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        final fade = Tween<double>(begin: 0, end: 1).animate(animation);
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Stack(
            children: [
              // 🔵 Background shapes
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

              // 🔹 Foreground
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.account_circle,
                            size: 35,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // HydroHub Title (fixed)
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            _createRoute(
                              HomePage(
                                stationId: widget.stationId,
                                staffId: widget.staffId, // ✅ Fixed here
                              ),
                              beginOffset: const Offset(-1.0, 0.0),
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

                      const SizedBox(height: 60),

                      // Buttons with entry animation
                      CustomMenuButton(
                        icon: Icons.attach_money,
                        label: "Add Sales",
                        onPressed: () {
                          Navigator.push(
                            context,
                            _createRoute(
                              AddSale(
                                stationId: widget.stationId,
                                staffId: widget.staffId,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      CustomMenuButton(
                        icon: Icons.local_shipping,
                        label: "Update Sales",
                        onPressed: () {
                          Navigator.push(
                            context,
                            _createRoute(
                              UpdateSales(
                                stationId: widget.stationId,
                                staffId: widget.staffId,
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
        ),
      ),
    );
  }
}
