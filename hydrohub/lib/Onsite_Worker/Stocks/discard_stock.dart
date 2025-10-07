import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../home_page.dart';

class DiscardStock extends StatefulWidget {
  const DiscardStock({super.key});

  @override
  State<DiscardStock> createState() => _DiscardStockState();
}

class _DiscardStockState extends State<DiscardStock> {
  String? selectedWaterType;
  String? selectedSize;
  int amount = 0;
  String? selectedReason;
  String otherReason = "";

  final List<String> waterTypes = ["Purified", "Mineral", "Alkaline"];
  final List<String> sizes = ["30L"];
  final List<String> discardReasons = [
    "Leak Container",
    "Wrong Input",
    "Old Stock",
    "Others"
  ];

  // ✅ Fetch available stock from backend
  Future<int> fetchAvailableStock(String waterType, String size) async {
    const String apiUrl = "http://10.0.2.2:3000/api/stocks/available";

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "water_type": waterType,
        "size": size,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["available"] ?? 0;
    } else {
      throw Exception(
        "❌ Failed to fetch available stock: ${response.body}",
      );
    }
  }

  // ✅ Save discarded stock
  Future<void> saveDiscardedStockToDatabase({
    required String waterType,
    required String size,
    required int amount,
    required String date,
    required String reason,
  }) async {
    const String apiUrl = "http://10.0.2.2:3000/api/stocks";

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "water_type": waterType,
        "size": size,
        "amount": amount,
        "stock_type": "discarded",
        "reason": reason,
        "date": date,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to discard stock: ${response.body}")),
      );
    }
  }

  // ✅ Confirm discard
  void _confirmDiscard() async {
    if (selectedWaterType == null ||
        selectedSize == null ||
        amount <= 0 ||
        selectedReason == null ||
        (selectedReason == "Others" && otherReason.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please complete all fields")),
      );
      return;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final finalReason = selectedReason == "Others" ? otherReason : selectedReason!;
    final type = selectedWaterType!;
    final size = selectedSize!;
    final qty = amount;
    final reason = finalReason;
    final date = formattedDate;

    try {
      // ✅ Check available stock first
      final available = await fetchAvailableStock(type, size);

      if (qty > available) {
        // ❌ Show popup if trying to discard more than available
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "⚠️ Not Enough Stock",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "You only have $available available for $type ($size).",
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        );
        return;
      }

      // ✅ Save if within limit
      await saveDiscardedStockToDatabase(
        waterType: type,
        size: size,
        amount: qty,
        date: date,
        reason: reason,
      );

      // ✅ Success dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "🗑️ Stock Discarded",
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Type: $type", style: const TextStyle(color: Colors.white)),
                Text("Size: $size", style: const TextStyle(color: Colors.white)),
                Text("Amount: $qty", style: const TextStyle(color: Colors.white)),
                Text("Reason: $reason", style: const TextStyle(color: Colors.white)),
                Text("Date: $date", style: const TextStyle(color: Colors.white)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close popup
                  Navigator.pop(context); // go back
                },
                child: const Text("OK", style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );

      // ✅ Reset fields
      setState(() {
        selectedWaterType = null;
        selectedSize = null;
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
      body: Stack(
        children: [
          // Decorative Background
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF6EACDA).withOpacity(0.3),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -80,
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(140),
              ),
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
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

                  // 👇 Push form lower
                  const Spacer(),

                  // 👇 Form scrollable
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Dropdown water type
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B263B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButton<String>(
                              hint: const Text(
                                "Water Type",
                                style: TextStyle(color: Colors.white),
                              ),
                              value: selectedWaterType,
                              dropdownColor: const Color(0xFF1B263B),
                              iconEnabledColor: Colors.white,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: waterTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type,
                                    style:
                                        const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedWaterType = value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Size buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: sizes.map((size) {
                              final isSelected = selectedSize == size;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? Colors.blue
                                        : const Color(0xFF1B263B),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      selectedSize = size;
                                    });
                                  },
                                  child: Text(size),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),

                          // Counter
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
                                  foregroundColor: Colors.white,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(20),
                                ),
                                child: const Text(
                                  "-",
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  "$amount",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    amount++;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B263B),
                                  foregroundColor: Colors.white,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(20),
                                ),
                                child: const Text(
                                  "+",
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Reason Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B263B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButton<String>(
                              hint: const Text(
                                "Reason for Discard",
                                style: TextStyle(color: Colors.white),
                              ),
                              value: selectedReason,
                              dropdownColor: const Color(0xFF1B263B),
                              iconEnabledColor: Colors.white,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: discardReasons.map((reason) {
                                return DropdownMenuItem(
                                  value: reason,
                                  child: Text(
                                    reason,
                                    style:
                                        const TextStyle(color: Colors.white),
                                  ),
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

                          // TextField if "Others"
                          if (selectedReason == "Others")
                            TextField(
                              onChanged: (value) {
                                setState(() {
                                  otherReason = value;
                                });
                              },
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

                          // Buttons
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
                                    horizontal: 30,
                                    vertical: 15,
                                  ),
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
                                    horizontal: 30,
                                    vertical: 15,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("Cancel"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
