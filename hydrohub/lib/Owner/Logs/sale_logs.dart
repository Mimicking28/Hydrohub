import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class SalesLogs extends StatefulWidget {
  final int stationId;
  const SalesLogs({super.key, required this.stationId});

  @override
  State<SalesLogs> createState() => _SalesLogsState();
}

class _SalesLogsState extends State<SalesLogs> {
  List<dynamic> sales = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSales();
  }

  // ✅ Fetch only sales from this station
  Future<void> fetchSales() async {
    final String apiUrl =
        "http://10.0.2.2:3000/api/sales?station_id=${widget.stationId}";
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          sales = json.decode(response.body);
          isLoading = false;
        });

        for (var sale in sales) {
          debugPrint("Sale: $sale");
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to fetch sales: $e")),
      );
    }
  }

  // ✅ Format UTC date to Philippine Time
  String formatToPHTime(String utcString) {
    try {
      final utcTime = DateTime.parse(utcString).toUtc();
      final phTime = utcTime.add(const Duration(hours: 8));
      return DateFormat('yyyy-MM-dd hh:mm a').format(phTime);
    } catch (e) {
      return utcString;
    }
  }

  // ✅ Show payment proof image in popup
  void showPhotoDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image,
                        size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }

  // 🌈 Clean color palette by payment type
  Color getPaymentColor(String method) {
    switch (method.toLowerCase()) {
      case "cash":
        return Colors.greenAccent;
      case "e-wallet":
        return Colors.blueAccent;
      default:
        return Colors.white70;
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
          "Sales Logs",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Colors.lightBlueAccent),
            )
          : sales.isEmpty
              ? const Center(
                  child: Text(
                    "No sales available",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    final isEwallet =
                        sale["payment_method"].toString().toLowerCase() ==
                            "e-wallet";

                    // ✅ Build proof image URL
                    final proofUrl = sale["proof"] != null &&
                            sale["proof"].toString().isNotEmpty
                        ? "http://10.0.2.2:3000/uploads/${sale["proof"]}"
                        : null;

                    final paymentColor =
                        getPaymentColor(sale["payment_method"] ?? "");

                    return Card(
                      color: const Color(0xFF1B263B),
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 💧 Product + Size
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "💧 ${sale["water_type"] ?? "Unknown"} (${sale["size"] ?? "N/A"})",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: paymentColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (sale["payment_method"] ?? "N/A")
                                        .toString()
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: paymentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 📋 Sale details
                            Text(
                              "📦 Quantity: ${sale["quantity"] ?? "0"}\n"
                              "💰 Total: ₱${sale["total"] ?? "0"}\n"
                              "📋 Type: ${sale["sale_type"] ?? "N/A"}\n"
                              "🕒 Date: ${formatToPHTime(sale["date"] ?? "")}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // 🧍 Recorded by
                            Text(
                              "🧍 Recorded by: ${(sale["first_name"] ?? "Unknown")} ${(sale["last_name"] ?? "")}",
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.5),
                            ),

                            if (isEwallet && proofUrl != null) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => showPhotoDialog(proofUrl),
                                  child: const Text("View Photo"),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
