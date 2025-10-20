import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ProductLogs extends StatefulWidget {
  const ProductLogs({super.key});

  @override
  State<ProductLogs> createState() => _ProductLogsState();
}

class _ProductLogsState extends State<ProductLogs> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // ✅ Fetch all products
  Future<void> fetchProducts() async {
    const String apiUrl = "http://10.0.2.2:3000/api/products";
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to fetch products: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error fetching products: $e")),
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
          "All Product Logs",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(
                  child: Text(
                    "No products available",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isArchived = product["is_archived"] == true;

                    return Card(
                      color: const Color(0xFF1B263B),
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: ListTile(
                        leading: Icon(
                          isArchived ? Icons.archive : Icons.local_drink,
                          color: isArchived ? Colors.redAccent : Colors.greenAccent,
                          size: 32,
                        ),
                        title: Text(
                          "${product["name"] ?? "Unnamed"} (${product["size_category"] ?? ""})",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Station: ${product["station_name"] ?? "N/A"}\n"
                          "Type: ${product["type"] ?? "N/A"}\n"
                          "Price: ₱${product["price"] ?? "0"}\n"
                          "Status: ${isArchived ? "Archived" : "Active"}\n"
                          "Date Created: ${formatToPHTime(product["created_at"])}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
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
