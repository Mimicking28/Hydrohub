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

  // ✅ Fetch all products (Admin View)
  Future<void> fetchProducts() async {
    const String apiUrl = "http://10.0.2.2:3000/api/products/admin";
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
          SnackBar(
              content:
                  Text("❌ Failed to fetch products: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error fetching products: $e")),
      );
    }
  }

  // ✅ Format date to Philippine Time
  String formatToPHTime(String utcString) {
    try {
      final utcTime = DateTime.parse(utcString).toUtc();
      final phTime = utcTime.add(const Duration(hours: 8));
      return DateFormat('yyyy-MM-dd hh:mm a').format(phTime);
    } catch (e) {
      return utcString;
    }
  }

  // 🎨 Tag color based on product type (Onsite / Online)
  Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case "onsite":
        return Colors.greenAccent;
      case "delivery":
        return Colors.blueAccent;
      default:
        return Colors.grey;
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
          "Product Logs (All Stations)",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.lightBlueAccent))
          : products.isEmpty
              ? const Center(
                  child: Text(
                    "No products available",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final type = product["type"] ?? "Unknown";
                    final tagColor = getTypeColor(type);
                    final isArchived = product["is_archived"] == true;

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
                            // 🔹 Header Line (Name + Tag)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "💧 ${product["name"] ?? "Unnamed"} (${product["size_category"] ?? "N/A"})",
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
                                    color: tagColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    type.toUpperCase(),
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

                            // 🏪 Station Name
                            Text(
                              "🏪 Station: ${product["station_name"] ?? "N/A"}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),

                            // 💰 Price
                            Text(
                              "💰 Price: ₱${product["price"] ?? "0"}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),

                            // 📦 Status
                            Text(
                              "📦 Status: ${isArchived ? "Archived" : "Active"}",
                              style: TextStyle(
                                color: isArchived
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            // 🕒 Date Created
                            Text(
                              "🕒 Created: ${formatToPHTime(product["created_at"] ?? "")}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.5,
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
