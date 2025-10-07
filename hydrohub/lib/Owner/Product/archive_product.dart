import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ArchiveProduct extends StatefulWidget {
  const ArchiveProduct({super.key});

  @override
  State<ArchiveProduct> createState() => _ArchiveProductState();
}

class _ArchiveProductState extends State<ArchiveProduct> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    const String apiUrl = "http://10.0.2.2:3000/api/products";
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> allProducts = json.decode(response.body);
        setState(() {
          // ✅ Include both archived and non-archived
          products = allProducts;
          isLoading = false;
        });
      } else {
        throw Exception("Server responded ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showPopupMessage("❌ Failed to fetch products: $e");
    }
  }

  Future<void> toggleArchive(int id, bool currentlyArchived) async {
    final String apiUrl = "http://10.0.2.2:3000/api/products/archive/$id";

    try {
      final response = await http.put(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        await fetchProducts(); // ✅ Refresh list
        _showPopupMessage(
          currentlyArchived
              ? "✅ Product is now available and operational."
              : "📦 Product archived successfully. It is now unavailable and cannot be sold.",
          success: true,
        );
      } else {
        String body = response.body;
        String message = "❌ Failed to update product status.";
        try {
          final parsed = json.decode(body);
          if (parsed is Map && parsed['error'] != null) {
            message = "❌ ${parsed['error']}";
          }
        } catch (_) {}
        _showPopupMessage(message);
      }
    } catch (e) {
      _showPopupMessage("❌ Error: $e");
    }
  }

  Future<void> _confirmArchiveToggle(
      int id, bool currentlyArchived, String productName) async {
    String title = currentlyArchived ? "Restore Product?" : "Archive Product?";
    String message = currentlyArchived
        ? "Are you sure you want to make '$productName' available and operational again?"
        : "Are you sure you want to archive '$productName'? This product will be unavailable and cannot be sold on the platform.";

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFEEF2F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentlyArchived ? Colors.green : Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(currentlyArchived ? "Go Online" : "Archive"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await toggleArchive(id, currentlyArchived);
    }
  }

  void _showPopupMessage(String message, {bool success = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: success ? Colors.green[100] : Colors.red[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          success ? 'Success' : 'Error',
          style: TextStyle(
              color: success ? Colors.green[900] : Colors.red[900],
              fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: TextStyle(
              color: success ? Colors.green[900] : Colors.red[900]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Archive Product",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : products.isEmpty
                        ? const Center(
                            child: Text("No products found.",
                                style: TextStyle(color: Colors.white70)))
                        : ListView.builder(
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              final bool isArchived =
                                  (product["is_archived"] == true) ||
                                  (product["archived"] == true);

                              return Card(
                                color: const Color.fromARGB(255, 77, 108, 165),
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                child: ListTile(
                                  title: Text(
                                    "${product["name"] ?? "Unnamed"} (${product["size_category"] ?? ""})",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "₱${product["price"] ?? "0"} | ${product["type"] ?? ""}",
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => _confirmArchiveToggle(
                                      product["id"],
                                      isArchived,
                                      product["name"] ?? "Unnamed",
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isArchived
                                          ? Colors.redAccent
                                          : Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(isArchived ? "Archived" : "Online"),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
