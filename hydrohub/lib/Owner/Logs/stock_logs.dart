import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class StockLogs extends StatefulWidget {
  final int stationId;

  const StockLogs({super.key, required this.stationId});

  @override
  State<StockLogs> createState() => _StockLogsState();
}

class _StockLogsState extends State<StockLogs> {
  List<dynamic> stocks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStocks();
  }

  // ✅ Fetch all stock logs for this station
  Future<void> fetchStocks() async {
    final String apiUrl =
        "http://10.0.2.2:3000/api/stocks?station_id=${widget.stationId}";
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          stocks = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to fetch stock logs: $e")),
      );
    }
  }

  // ✅ Convert UTC time to PH time for display
  String formatToPHTime(String utcString) {
    try {
      final utcTime = DateTime.parse(utcString).toUtc();
      final phTime = utcTime.add(const Duration(hours: 8));
      return DateFormat('yyyy-MM-dd hh:mm a').format(phTime);
    } catch (e) {
      return utcString;
    }
  }

  // 🎨 Color-coding for each stock type
  Color getTypeColor(String type) {
    switch (type) {
      case "refilled":
        return Colors.greenAccent;
      case "returned":
        return Colors.lightBlueAccent;
      case "discarded":
        return Colors.redAccent;
      case "delivered":
        return Colors.orangeAccent;
      default:
        return Colors.white;
    }
  }

  // 🧠 Determine action label dynamically
  String getActionLabel(String type) {
    switch (type) {
      case "refilled":
        return "Added by";
      case "returned":
        return "Returned by";
      case "discarded":
        return "Discarded by";
      case "delivered":
        return "Delivered by";
      default:
        return "Updated by";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        foregroundColor: Colors.white,
        title: const Text(
          "Inventory Logs",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent))
          : stocks.isEmpty
              ? const Center(
                  child: Text(
                    "No stock logs available",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: stocks.length,
                  itemBuilder: (context, index) {
                    final stock = stocks[index];
                    final stockType = stock["stock_type"] ?? "unknown";
                    final actionLabel = getActionLabel(stockType);
                    final textColor = getTypeColor(stockType);

                    return Card(
                      color: const Color(0xFF1B263B),
                      margin:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Title Line (Product + Size)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "💧 ${stock["product_name"] ?? "N/A"} (${stock["size_category"] ?? "N/A"})",
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: textColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    stockType.toUpperCase(),
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 🔹 Quantity
                            Text(
                              "📦 Quantity: ${stock["amount"] ?? "0"}",
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.5),
                            ),

                            // 🔹 Optional Reason (only for returned/discarded)
                            if (stockType == "returned" ||
                                stockType == "discarded") ...[
                              const SizedBox(height: 4),
                              Text(
                                "📝 Reason: ${stock["reason"]?.isNotEmpty == true ? stock["reason"] : "N/A"}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],

                            const SizedBox(height: 4),

                            // 🔹 Action performer
                            Text(
                              "🧍 $actionLabel: ${(stock["first_name"] ?? "Unknown")} ${(stock["last_name"] ?? "")}",
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.5),
                            ),

                            // 🔹 Date
                            Text(
                              "🕒 Date: ${formatToPHTime(stock["date"] ?? "")}",
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
