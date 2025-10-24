// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../home_page.dart';

class ReturnStock extends StatefulWidget {
  final int stationId;
  final int staffId;
  const ReturnStock({super.key, required this.stationId, required this.staffId});

  @override
  State<ReturnStock> createState() => _ReturnStockState();
}

class _ReturnStockState extends State<ReturnStock> {
  String? selectedType;
  String? selectedReason;
  String otherReason = "";
  int amount = 0;

  List<String> waterTypes = [];
  Map<String, int> productMap = {};
  bool isLoading = true;

  final List<String> returnReasons = [
    "Customer Return",
    "Not Sold",
    "Damaged",
    "Others"
  ];

  @override
  void initState() {
    super.initState();
    fetchDeliveryProducts();
  }

  // ✅ Fetch active delivery products (all 20L)
  Future<void> fetchDeliveryProducts() async {
    final String apiUrl =
        "http://10.0.2.2:3000/api/products?station_id=${widget.stationId}&type=delivery";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Filter only active delivery-type products
        final filtered = data.where((p) {
          final type = (p["type"] ?? "").toString().toLowerCase();
          final archived = p["is_archived"];
          final bool isActive = (archived == false ||
              archived == 0 ||
              archived == null ||
              archived.toString().toLowerCase() == "false");
          return type == "delivery" && isActive;
        }).toList();

        final Map<String, int> nameToId = {};
        for (var p in filtered) {
          nameToId[p["name"]] = p["id"];
        }

        setState(() {
          productMap = nameToId;
          waterTypes = nameToId.keys.toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch delivery products");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error loading products: $e")),
      );
    }
  }

  // ✅ Check available stock using delivery products
  Future<int> fetchAvailableStock(int productId) async {
    const String apiUrl = "http://10.0.2.2:3000/api/stocks/available";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "product_id": productId,
          "staff_id": widget.staffId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["available"] ?? 0;
      } else {
        throw Exception("Failed to fetch available stock");
      }
    } catch (e) {
      throw Exception("⚠️ Error fetching stock: $e");
    }
  }

  // ✅ Save returned stock record
  Future<void> saveReturnedStockToDatabase({
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
          "stock_type": "returned",
          "reason": reason,
          "date": date,
          "staff_id": widget.staffId,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("♻️ Stock returned successfully")),
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

  // ✅ Confirm return with validation
  void _confirmReturn() async {
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
              "Only $available available for $selectedType.",
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

      final nowUtc = DateTime.now().toUtc();
      final formattedDate = nowUtc.toIso8601String();
      final finalReason =
          selectedReason == "Others" ? otherReason : selectedReason!;

      await saveReturnedStockToDatabase(
        productId: productId,
        amount: amount,
        date: formattedDate,
        reason: finalReason,
      );

      // ✅ Success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1B263B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("♻️ Stock Returned",
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Water Type: $selectedType",
                  style: const TextStyle(color: Colors.white)),
              const Text("Size: 20 Liters", style: TextStyle(color: Colors.white)),
              Text("Amount: $amount", style: const TextStyle(color: Colors.white)),
              Text("Reason: $finalReason",
                  style: const TextStyle(color: Colors.white)),
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

      setState(() {
        selectedType = null;
        selectedReason = null;
        otherReason = "";
        amount = 0;
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
                        )
                      ],
                    ),
                    const SizedBox(height: 40),

                    // 🔹 Water Type Dropdown
                    if (waterTypes.isEmpty)
                      const Center(
                        child: Text("No delivery products available",
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
                        hint: const Text("Reason for Return",
                            style: TextStyle(color: Colors.white)),
                        value: selectedReason,
                        dropdownColor: const Color(0xFF1B263B),
                        iconEnabledColor: Colors.white,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: returnReasons.map((reason) {
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

                    // 🔹 “Others” input
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
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                          onPressed: _confirmReturn,
                          child: const Text("Confirm"),
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
