import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ArchiveProduct extends StatefulWidget {
  final int stationId; // ✅ Linked to the current water station

  const ArchiveProduct({super.key, required this.stationId});

  @override
  State<ArchiveProduct> createState() => _ArchiveProductState();
}

class _ArchiveProductState extends State<ArchiveProduct> {
  List<dynamic> allProducts = [];
  List<dynamic> filteredProducts = [];
  bool isLoading = true;

  String selectedFilter = "All"; // "All", "Active", "Archived"
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // ✅ Fetch only products for this station
  Future<void> fetchProducts() async {
    final String apiUrl =
        "http://10.0.2.2:3000/api/products?station_id=${widget.stationId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> products = json.decode(response.body);
        setState(() {
          allProducts = products;
          applyFilters();
          isLoading = false;
        });
      } else {
        throw Exception("Server responded with ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showPopupMessage("❌ Failed to fetch products: $e");
    }
  }

  // ✅ Apply search and filter logic
  void applyFilters() {
    List<dynamic> results = allProducts;

    // Search filter
    if (searchQuery.isNotEmpty) {
      results = results
          .where((p) => (p["name"] ?? "")
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Status filter
    if (selectedFilter == "Active") {
      results = results.where((p) => p["is_archived"] == false).toList();
    } else if (selectedFilter == "Archived") {
      results = results.where((p) => p["is_archived"] == true).toList();
    }

    setState(() {
      filteredProducts = results;
    });
  }

  // ✅ Toggle archive/unarchive
  Future<void> toggleArchive(int id, bool currentlyArchived) async {
    final String apiUrl = "http://10.0.2.2:3000/api/products/archive/$id";

    try {
      final response = await http.put(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // 🔄 Update UI instantly
        setState(() {
          for (var p in allProducts) {
            if (p["id"] == id) {
              p["is_archived"] = !currentlyArchived;
            }
          }
          applyFilters();
        });

        _showPopupMessage(
          currentlyArchived
              ? "✅ Product restored and now available."
              : "📦 Product archived successfully.",
          success: true,
        );
      } else {
        String message = "❌ Failed to update product status.";
        try {
          final parsed = json.decode(response.body);
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

  // ✅ Confirmation before archiving/unarchiving
  Future<void> _confirmArchiveToggle(
      int id, bool currentlyArchived, String productName) async {
    String title = currentlyArchived ? "Restore Product?" : "Archive Product?";
    String message = currentlyArchived
        ? "Are you sure you want to make '$productName' available again?"
        : "Are you sure you want to archive '$productName'? It will no longer be available to customers.";

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
          style: const TextStyle(color: Colors.black87, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  currentlyArchived ? Colors.green : Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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

  // ✅ Popup dialog for feedback
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
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: success ? Colors.green[900] : Colors.red[900],
          ),
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

  // ✅ UI Layout
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
              // 🔹 Header
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
              const SizedBox(height: 15),

              // 🔍 Search bar
              TextField(
                onChanged: (value) {
                  searchQuery = value;
                  applyFilters();
                },
                decoration: InputDecoration(
                  hintText: "Search product...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF0A2647),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),

              // 🧩 Filter Chips
              Center(
                child: Wrap(
                  spacing: 10,
                  alignment: WrapAlignment.center,
                  children: ["All", "Active", "Archived"].map((filter) {
                    bool isSelected = selectedFilter == filter;
                    return ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedFilter = filter;
                          applyFilters();
                        });
                      },
                      selectedColor: const Color(0xFF205295),
                      backgroundColor: const Color(0xFF0A2647),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // 📋 Product List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredProducts.isEmpty
                        ? const Center(
                            child: Text(
                              "No products found.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              final bool isArchived =
                                  (product["is_archived"] == true) ||
                                      (product["archived"] == true);

                              return Card(
                                color: const Color(0xFF1C3D73),
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                child: ListTile(
                                  title: Text(
                                    "${product["name"] ?? "Unnamed"} (${product["size_category"] ?? ""})",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "₱${product["price"] ?? "0"} | ${product["type"] ?? ""}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
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
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                        isArchived ? "Archived" : "Online"),
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
