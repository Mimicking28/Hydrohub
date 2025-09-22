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

  // ✅ Fetch all sales (delivery + onsite)
  Future<void> fetchSales() async {
    const String apiUrl = "http://10.0.2.2:5000/sales";
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      setState(() {
        sales = json.decode(response.body);
        isLoading = false;
      });

      // Debug print all sales data
      for (var sale in sales) {
        debugPrint("Sale: $sale");
      }
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to fetch sales logs")),
      );
    }
  }

  // ✅ Format date to PH time
  String formatToPHTime(String utcString) {
    try {
      final utcTime = DateTime.parse(utcString).toUtc();
      final phTime = utcTime.add(const Duration(hours: 8));
      return DateFormat('yyyy-MM-dd hh:mm a').format(phTime);
    } catch (e) {
      return utcString;
    }
  }

  // ✅ Show photo popup
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
            )
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
          "All Sales Logs",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sales.isEmpty
              ? const Center(
                  child: Text(
                    "No sales available",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    final isEwallet =
                        sale["payment_method"].toString().toLowerCase() ==
                            "e-wallet";

                    // ✅ Build full URL for proof image
                    final proofUrl = sale["proof"] != null &&
                            sale["proof"].toString().isNotEmpty
                        ? "http://10.0.2.2:5000/uploads/${sale["proof"]}"
                        : null;

                    return Card(
                      color: const Color(0xFF1B263B),
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "💧 Water: ${sale["water_type"]} (${sale["size"]})",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "📦 Quantity: ${sale["quantity"]}\n"
                              "💰 Total: ₱${sale["total"]}\n"
                              "💳 Payment: ${sale["payment_method"]}\n"
                              "📋 Type: ${sale["sale_type"]}\n"
                              "🕒 Date: ${formatToPHTime(sale["date"])}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            if (isEwallet && proofUrl != null)
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
                                  onPressed: () {
                                    showPhotoDialog(proofUrl);
                                  },
                                  child: const Text("View Photo"),
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
