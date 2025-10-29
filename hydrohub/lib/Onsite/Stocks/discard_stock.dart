// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../home_page.dart';

class DiscardStock extends StatefulWidget {
  final int stationId;
  final int staffId;
  const DiscardStock({super.key, required this.stationId, required this.staffId});

  @override
  State<DiscardStock> createState() => _DiscardStockState();
}

class _DiscardStockState extends State<DiscardStock> {
  String? selectedType;
  int amount = 0;
  String? selectedReason;
  String otherReason = "";

  List<dynamic> products = [];
  List<String> waterTypes = []; // ✅ Unique 20-liter product names
  Map<String, int> productMap = {}; // Maps type → product_id
  bool isLoading = true;

  final List<String> discardReasons = [
    "Leak Container",
    "Wrong Input",
    "Old Stock",
    "Others"
  ];

  @override
  void initState() {
    super.initState();
    fetchProductsForStation();
  }

  // ✅ Fetch unique 20-liter products for this station
  Future<void> fetchProductsForStation() async {
    final String apiUrl =
        "http://10.0.2.2:3000/api/products/owner/${widget.stationId}"; // ✅ Correct route

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Keep only 20-liter products
        final filtered = data.where((p) {
          final size = (p["size_category"] ?? "").toString().toLowerCase();
          return size.contains("20") && size.contains("liter");
        }).toList();

        // Remove duplicates by name
        final Map<String, int> uniqueProducts = {};
        for (var p in filtered) {
          final name = (p["name"] ?? "").toString();
          if (!uniqueProducts.containsKey(name)) {
            uniqueProducts[name] = p["id"];
          }
        }

        setState(() {
          products = filtered;
          productMap = uniqueProducts;
          waterTypes = uniqueProducts.keys.toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch products");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to load products: $e")),
      );
    }
  }

  // ✅ Fetch available stock
  Future<int> fetchAvailableStock(int productId) async {
    const String apiUrl = "http://10.0.2.2:3000/api/stocks/available";

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "product_id": productId,
        "staff_id": widget.staffId, // ✅ Required by backend
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["available"] ?? 0;
    } else {
      throw Exception("❌ Failed to fetch available stock: ${response.body}");
    }
  }

  // ✅ Save discard record
  Future<void> saveDiscardedStockToDatabase({
    required int productId,
    required int amount,
    required String date,
    required String reason,
  }) async {
    const String apiUrl = "http://10.0.2.2:3000/api/stocks";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "product_id": productId,
          "amount": amount,
          "stock_type": "discarded",
          "reason": reason,
          "date": date,
          "staff_id": widget.staffId,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🗑️ Stock discarded successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error saving: $e")),
      );
    }
  }

  // ✅ Confirm discard logic
  void _confirmDiscard() async {
    if (selectedType == null ||
        amount <= 0 ||
        selectedReason == null ||
        (selectedReason == "Others" && otherReason.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please complete all fields")),
      );
      return;
    }

    final productId = productMap[selectedType];
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Product not found")),
      );
      return;
    }

    final nowUtc = DateTime.now().toUtc();
    final formattedDate = nowUtc.toIso8601String();
    final finalReason =
        selectedReason == "Others" ? otherReason : selectedReason!;

    try {
      final available = await fetchAvailableStock(productId);

      if (amount > available) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("⚠️ Not Enough Stock",
                style: TextStyle(color: Colors.white)),
            content: Text(
              "Only $available available for $selectedType (20 Liters).",
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          ),
        );
        return;
      }

      await saveDiscardedStockToDatabase(
        productId: productId,
        amount: amount,
        date: formattedDate,
        reason: finalReason,
      );

      // ✅ Success popup
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1B263B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("🗑️ Stock Discarded",
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Water Type: $selectedType",
                  style: const TextStyle(color: Colors.white)),
              const Text("Size: 20 Liters", style: TextStyle(color: Colors.white)),
              Text("Amount: $amount", style: const TextStyle(color: Colors.white)),
              Text("Reason: $finalReason", style: const TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );

      // Reset fields
      setState(() {
        selectedType = null;
        amount = 0;
        selectedReason = null;
        otherReason = "";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.lightBlueAccent))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(
                                  stationId: widget.stationId,
                                  staffId: widget.staffId,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "HydroHub",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Icon(Icons.account_circle,
                            color: Colors.white, size: 32),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // 🔹 Water Type Dropdown
                    if (waterTypes.isEmpty)
                      const Center(
                        child: Text("No 20-Liter products available",
                            style: TextStyle(color: Colors.white70)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B263B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButton<String>(
                          hint: const Text("Select Water Type",
                              style: TextStyle(color: Colors.white)),
                          value: selectedType,
                          dropdownColor: const Color(0xFF1B263B),
                          iconEnabledColor: Colors.white,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: waterTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type,
                                  style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedType = value);
                          },
                        ),
                      ),

                    const SizedBox(height: 20),
                    const Text("Size: 20 Liters",
                        style: TextStyle(color: Colors.white70, fontSize: 16)),

                    const SizedBox(height: 20),

                    // 🔹 Amount Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (amount > 0) amount--;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B263B),
                            foregroundColor: Colors.red,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                          ),
                          child: const Text("-", style: TextStyle(fontSize: 24)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "$amount",
                            style: const TextStyle(
                                fontSize: 20, color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => amount++);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B263B),
                            foregroundColor: Colors.green,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                          ),
                          child: const Text("+", style: TextStyle(fontSize: 24)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // 🔹 Reason Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B263B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButton<String>(
                        hint: const Text("Reason for Discard",
                            style: TextStyle(color: Colors.white)),
                        value: selectedReason,
                        dropdownColor: const Color(0xFF1B263B),
                        iconEnabledColor: Colors.white,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: discardReasons.map((reason) {
                          return DropdownMenuItem(
                            value: reason,
                            child: Text(reason,
                                style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value;
                            if (value != "Others") otherReason = "";
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔹 “Others” input field
                    if (selectedReason == "Others")
                      TextField(
                        onChanged: (value) => setState(() => otherReason = value),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1B263B),
                          hintText: "Enter reason",
                          hintStyle: const TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // 🔹 Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                          onPressed: _confirmDiscard,
                          child: const Text("Discard"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
