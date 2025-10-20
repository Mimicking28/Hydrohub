import 'package:flutter/material.dart';
import '../widgets/custom_menu_button.dart';
import 'Sales/sales_page.dart';
import 'Order/orders_page.dart';
import 'Stocks/stocks_page.dart';
import '../Onsite/profile.dart';

class HomePage extends StatefulWidget {
  final int stationId;
  final int staffId;

  const HomePage({
    super.key,
    required this.stationId,
    required this.staffId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
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

  // 🔹 Reusable transition builder
  PageRouteBuilder _animatedRoute(Widget page,
      {Offset beginOffset = const Offset(1.0, 0.0), int duration = 500}) {
    return PageRouteBuilder(
      transitionDuration: Duration(milliseconds: duration),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final slide = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(animation);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
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
              // 🔵 Background ovals
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

              // 🔹 Foreground content
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 👤 Profile Icon → opens profile page
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              _animatedRoute(
                                OnsiteProfilePage(
                                  staffId: widget.staffId,
                                  stationId: widget.stationId,
                                ),
                                beginOffset: const Offset(1.0, 0.0),
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

                      // HydroHub title
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            _animatedRoute(
                              HomePage(
                                stationId: widget.stationId,
                                staffId: widget.staffId,
                              ),
                              beginOffset: const Offset(-1.0, 0.0),
                              duration: 400,
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

                      // 🔹 Menu Buttons
                      CustomMenuButton(
                        icon: Icons.attach_money,
                        label: "Sales",
                        onPressed: () {
                          Navigator.push(
                            context,
                            _animatedRoute(
                              SalesPage(
                                stationId: widget.stationId,
                                staffId: widget.staffId,
                              ),
                              beginOffset: const Offset(1.0, 0.0),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      CustomMenuButton(
                        icon: Icons.local_shipping,
                        label: "Orders",
                        onPressed: () {
                          Navigator.push(
                            context,
                            _animatedRoute(
                              OrdersPage(stationId: widget.stationId),
                              beginOffset: const Offset(0.0, 1.0),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      CustomMenuButton(
                        icon: Icons.water_drop,
                        label: "Stocks",
                        onPressed: () {
                          Navigator.push(
                            context,
                            _animatedRoute(
                              StocksPage(
                                stationId: widget.stationId,
                                staffId: widget.staffId,
                              ),
                              beginOffset: const Offset(0.0, -1.0),
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
