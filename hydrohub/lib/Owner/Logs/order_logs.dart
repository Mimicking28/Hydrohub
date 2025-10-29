import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class OrderLogs extends StatefulWidget {
  final int stationId; // ✅ Receive from LogsPage

  const OrderLogs({super.key, required this.stationId});

  @override
  State<OrderLogs> createState() => _OrderLogsState();
}

class _OrderLogsState extends State<OrderLogs> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  // ✅ Fetch all orders belonging to this station
  Future<void> fetchOrders() async {
    final String apiUrl =
        "http://10.0.2.2:3000/api/orders?station_id=${widget.stationId}";
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          orders = json.decode(response.body);
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
        SnackBar(content: Text("❌ Failed to fetch order logs: $e")),
      );
    }
  }

  // ✅ Format UTC → Philippine time
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
          "Order Logs",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(
                  child: Text(
                    "No orders available",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      color: const Color(0xFF1B263B),
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: ListTile(
                        title: Text(
                          "Order ID: ${order["id"] ?? "N/A"}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Customer: ${order["customer_name"] ?? "N/A"}\n"
                          "Water: ${order["water_type"] ?? "Unknown"} (${order["size"] ?? ""})\n"
                          "Quantity: ${order["quantity"] ?? 0}\n"
                          "Total: ₱${order["total"] ?? 0}\n"
                          "Payment: ${order["payment_method"] ?? "N/A"}\n"
                          "Status: ${order["status"] ?? "Pending"}\n"
                          "Date: ${formatToPHTime(order["created_at"] ?? order["date"] ?? "")}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
