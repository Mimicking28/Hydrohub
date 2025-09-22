import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class OrderLogs extends StatefulWidget {
  const OrderLogs({super.key});

  @override
  State<OrderLogs> createState() => _OrderLogsState();
}

class _OrderLogsState extends State<OrderLogs> {
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
                    return Card(
                      color: const Color(0xFF1B263B),
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: ListTile(
                        title: Text(
                          "Water: ${sale["water_type"]} (${sale["size"]})",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20, // Bigger title text
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Quantity: ${sale["quantity"]}\n"
                          "Total: ₱${sale["total"]}\n"
                          "Payment: ${sale["payment_method"]}\n"
                          "Type: ${sale["sale_type"]}\n"
                          "Date: ${formatToPHTime(sale["date"])}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16, // Bigger details text
                            height: 1.5, // More spacing between lines
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
