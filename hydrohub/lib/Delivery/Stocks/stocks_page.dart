import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hydrohub/Onsite_Worker/Stocks/update_discard.dart';

import '../../widgets/custom_menu_button.dart';
import '../home_page.dart';
import 'deliver_stock.dart';
import 'return_stock.dart';

class StocksDeliverPage extends StatefulWidget {
  const StocksDeliverPage({super.key});

  @override
  State<StocksDeliverPage> createState() => _StocksPageState();
}

class _StocksPageState extends State<StocksDeliverPage> {
  int alkaline = 0;
  int mineral = 0;
  int purified = 0;

  @override
  void initState() {
    super.initState();
    fetchStockData();
  }

  // ✅ Fetch stock summary from backend
  Future<void> fetchStockData() async {
    try {
      final response =
          await http.get(Uri.parse("http://10.0.2.2:5000/stock_summary"));
      // ⚠️ Use 10.0.2.2 for Android emulator. Replace with PC IP if using real device.

      if (response.statusCode == 200) {
        final summary = jsonDecode(response.body);
        print("📦 Stock summary response: $summary");

        setState(() {
          alkaline = summary["Alkaline"] ?? 0;
          mineral = summary["Mineral"] ?? 0;
          purified = summary["Purified"] ?? 0;
        });
      } else {
        print("❌ Failed to load stock data: ${response.body}");
      }
    } catch (e) {
      print("⚠️ Error fetching stock data: $e");
    }
  }

  Widget buildStockCard(String label, int value) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF08315C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // Profile Icon
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.account_circle,
                          size: 35, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomePage()),
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

                  const SizedBox(height: 40),

                  // ✅ Dynamic Stock Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildStockCard("Alkaline", alkaline),
                      buildStockCard("Mineral", mineral),
                      buildStockCard("Purified", purified),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // Menu Buttons
                  CustomMenuButton(
                    icon: Icons.add,
                    label: "Add Delivery Stock",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DeliveryStock()),
                      ).then((_) => fetchStockData()); // refresh after return
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomMenuButton(
                    icon: Icons.update,
                    label: "Update Stock",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UpdateDiscard()),
                      ).then((_) => fetchStockData());
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomMenuButton(
                    icon: Icons.undo,
                    label: "Return Stock",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ReturnStock()),
                      ).then((_) => fetchStockData());
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
