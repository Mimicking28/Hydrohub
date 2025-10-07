import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../home_page.dart';

class AddStock extends StatefulWidget {
  const AddStock({super.key});

  @override
  State<AddStock> createState() => _AddStockState();
}

class _AddStockState extends State<AddStock> {
  String? selectedWaterType;
  String? selectedSize;
  int amount = 0;

  final List<String> waterTypes = ["Purified", "Mineral", "Alkaline"];
  final List<String> sizes = ["30L"];

  // ✅ Save stock to backend
  Future<void> saveStockToDatabase({
    required String waterType,
    required String size,
    required int amount,
    required String date,
  }) async {
    const String apiUrl = "http://10.0.2.2:3000/api/stocks";

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: '''
        {
          "water_type": "$waterType",
          "size": "$size",
          "amount": $amount,
          "stock_type": "refilled",
          "reason": "",
          "date": "$date"
        }
      ''',
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to add stock: ${response.body}")),
      );
    }
  }

  // ✅ Confirm add logic
  void _confirmAdd() async {
    if (selectedWaterType == null || selectedSize == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please complete all fields")),
      );
      return;
    }

    final finalWaterType = selectedWaterType!;
    final finalSize = selectedSize!;
    final finalAmount = amount;

    // Save UTC for backend
    final nowUtc = DateTime.now().toUtc();
    final isoUtc = nowUtc.toIso8601String();

    // Display PH time for user
    final phTime = nowUtc.add(const Duration(hours: 8));
    final formattedPHTime = DateFormat('yyyy-MM-dd hh:mm a').format(phTime);

    await saveStockToDatabase(
      waterType: finalWaterType,
      size: finalSize,
      amount: finalAmount,
      date: isoUtc, // backend gets UTC
    );

    // Confirmation dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B263B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "✅ Stock Added",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Type: $finalWaterType", style: const TextStyle(color: Colors.white)),
              Text("Size: $finalSize", style: const TextStyle(color: Colors.white)),
              Text("Amount: $finalAmount", style: const TextStyle(color: Colors.white)),
              Text("Date: $formattedPHTime", style: const TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        selectedWaterType = null;
        selectedSize = null;
        amount = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      body: Stack(
        children: [
          // 🔵 Decorative shapes
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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 🔹 Top bar
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
                      const Icon(Icons.account_circle, color: Colors.white, size: 32),
                    ],
                  ),

                  // 🔹 Form content
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),

                            // Water Type Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B263B),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButton<String>(
                                hint: const Text("Water Type", style: TextStyle(color: Colors.white)),
                                value: selectedWaterType,
                                dropdownColor: const Color(0xFF1B263B),
                                iconEnabledColor: Colors.white,
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: waterTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type, style: const TextStyle(color: Colors.white)),
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

                            // Label for Size
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Select Size:",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Size buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: sizes.map((size) {
                                final isSelected = selectedSize == size;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSelected ? Colors.blue : const Color(0xFF1B263B),
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

                            // Label for Number of Containers
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Number of Containers:",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Amount Counter
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
                                    foregroundColor: const Color.fromARGB(255, 184, 35, 35),
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(20),
                                  ),
                                  child: const Text("-", style: TextStyle(fontSize: 24)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text("$amount", style: const TextStyle(fontSize: 20, color: Colors.white)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      amount++;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B263B),
                                    foregroundColor: const Color.fromARGB(255, 14, 166, 90),
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(20),
                                  ),
                                  child: const Text("+", style: TextStyle(fontSize: 24)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            // Confirm + Cancel buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 14, 166, 90),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  ),
                                  onPressed: _confirmAdd,
                                  child: const Text("Confirm"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
