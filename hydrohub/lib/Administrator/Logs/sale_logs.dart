import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class SalesLogs extends StatefulWidget {
  const SalesLogs({super.key});

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

  // ✅ Fetch all sales (admin view)
  Future<void> fetchSales() async {
    const String apiUrl = "http://10.0.2.2:3000/api/sales/admin";
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          sales = json.decode(response.body);
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
        SnackBar(content: Text("❌ Failed to fetch sales logs: $e")),
      );
    }
  }

  // ✅ Convert UTC to Philippine time
  String formatToPHTime(String utcString) {
    try {
      final utcTime = DateTime.parse(utcString).toUtc();
      final phTime = utcTime.add(const Duration(hours: 8));
      return DateFormat('yyyy-MM-dd hh:mm a').format(phTime);
    } catch (e) {
      return utcString;
    }
  }

  // 🎨 Color tag for payment method
  Color getPaymentColor(String method) {
    if (method.toLowerCase() == "cash") {
      return Colors.greenAccent;
    } else if (method.toLowerCase() == "e-wallet") {
      return Colors.blueAccent;
    } else {
      return Colors.grey;
    }
  }

  // 🧾 Show payment proof
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
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        foregroundColor: Colors.white,
        title: const Text(
          "Sales Logs (All Stations)",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent))
          : sales.isEmpty
              ? const Center(
                  child: Text(
                    "No sales records available",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    final payment = sale["payment_method"] ?? "Unknown";
                    final tagColor = getPaymentColor(payment);

                    // Proof URL
                    final proofUrl = (sale["proof"] != null && sale["proof"].toString().isNotEmpty)
                        ? "http://10.0.2.2:3000/uploads/${sale["proof"]}"
                        : null;

                    return Card(
                      color: const Color(0xFF1B263B),
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Header (Water + Tag)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: tagColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    payment.toUpperCase(),
                                    style: TextStyle(
                                      color: tagColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 📋 Sale Info
                            Text(
                              "🏪 Station: ${sale["station_name"] ?? "N/A"}",
                              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                            ),
                            Text(
                              "🧍 Staff: ${(sale["first_name"] ?? "Unknown")} ${(sale["last_name"] ?? "")}",
                              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                            ),
                            Text(
                              "📦 Quantity: ${sale["quantity"] ?? "0"}",
                              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                            ),
                            Text(
                              "💰 Total: ₱${sale["total"] ?? "0"}",
                              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                            ),
                            Text(
                              "🛒 Type: ${sale["sale_type"] ?? "N/A"}",
                              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                            ),
                            Text(
                              "🕒 Date: ${formatToPHTime(sale["date"] ?? "")}",
                              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                            ),

                            const SizedBox(height: 10),

                            // 📷 Payment Proof (for e-wallet only)
                            if (payment.toLowerCase() == "e-wallet" && proofUrl != null)
                              Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => showPhotoDialog(proofUrl),
                                  child: const Text(
                                    "View Proof",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
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
