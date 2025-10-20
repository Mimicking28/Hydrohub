import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hydrohub/Onsite/Stocks/update_stock_page.dart';
import '../../widgets/custom_menu_button.dart';
import '../home_page.dart';
import 'add_stock.dart';
import 'discard_stock.dart';

class StocksPage extends StatefulWidget {
  final int stationId;
  final int staffId;
  const StocksPage({super.key, required this.stationId, required this.staffId});

  @override
  State<StocksPage> createState() => _StocksPageState();
}

class _StocksPageState extends State<StocksPage> {
  List<dynamic> stockSummary = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStockData();
  }

  Future<void> fetchStockData() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          "http://10.0.2.2:3000/api/stocks/stock_summary?station_id=${widget.stationId}",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📦 Stock summary for station ${widget.stationId}: $data");

        setState(() {
          stockSummary = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("❌ Failed to load stock summary: ${response.body}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("⚠️ Error fetching stock summary: $e");
    }
  }

  // ✅ Remove “20 Liters” text before displaying
  String cleanProductName(String name) {
    return name.replaceAll(RegExp(r'20\s*Liters', caseSensitive: false), '').trim();
  }

  Widget buildStockCard(Map<String, dynamic> stock) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 6),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF08315C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              cleanProductName(stock["name"]),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            stock["available"].toString(),
            style: const TextStyle(
              fontSize: 22,
              color: Colors.lightBlueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStockList() {
    if (stockSummary.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text(
          "No stock data available.",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return Column(
      children: stockSummary.map((stock) => buildStockCard(stock)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      body: RefreshIndicator(
        onRefresh: fetchStockData,
        color: Colors.lightBlueAccent,
        child: Stack(
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
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Icon
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
                      const SizedBox(height: 10),

                      // HydroHub Title
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(
                                stationId: widget.stationId,
                                staffId: widget.staffId,
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

                      const SizedBox(height: 35),

                      // 🌊 Elegant Section Header
                      Column(
                        children: [
                          const Text(
                            "💧 Available Stocks",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 3,
                            width: 120,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6EACDA),
                                  Color(0xFF00BFFF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // ✅ Dynamic Stock Display
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: CircularProgressIndicator(
                            color: Colors.lightBlueAccent,
                          ),
                        )
                      else
                        buildStockList(),

                      const SizedBox(height: 50),

                      // Menu Buttons
                      CustomMenuButton(
                        icon: Icons.add,
                        label: "Add Stock",
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddStock(
                                stationId: widget.stationId,
                                staffId: widget.staffId,
                              ),
                            ),
                          );
                          fetchStockData();
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomMenuButton(
                        icon: Icons.update,
                        label: "Update Stock",
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UpdateStock(
                                stationId: widget.stationId,
                                staffId: widget.staffId,
                              ),
                            ),
                          );
                          fetchStockData();
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomMenuButton(
                        icon: Icons.delete,
                        label: "Discard Stock",
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiscardStock(
                                stationId: widget.stationId,
                                staffId: widget.staffId,
                              ),
                            ),
                          );
                          fetchStockData();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
