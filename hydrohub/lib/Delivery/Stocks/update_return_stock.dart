import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class UpdateReturnStock extends StatefulWidget {
  const UpdateReturnStock({super.key});

  @override
  State<UpdateReturnStock> createState() => _UpdateStockState();
}

class _UpdateStockState extends State<UpdateReturnStock> {
  List<dynamic> stocks = [];
  bool isLoading = true;

  final List<String> waterTypes = ["Purified", "Mineral", "Alkaline"];
  final List<String> sizes = ["5L", "10L", "30L"];
  final List<String> reasons = ["Damaged", "Expired", "Customer Return", "Other"];

  @override
  void initState() {
    super.initState();
    fetchStocks();
  }

  Future<void> fetchStocks() async {
    const String apiUrl = "http://10.0.2.2:3000/api/stocks";
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final allStocks = json.decode(response.body);

      setState(() {
        // ✅ filter only returned stocks
        stocks = allStocks.where((stock) => stock["stock_type"] == "returned").toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to fetch stocks")),
      );
    }
  }

  Future<void> updateStock(int id, Map<String, dynamic> updatedData) async {
    final String apiUrl = "http://10.0.2.2:3000/api/stocks/$id";

    final response = await http.put(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(updatedData),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Stock updated successfully")),
      );
      fetchStocks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update stock: ${response.body}")),
      );
    }
  }

  void showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("⚠️ Warning", style: TextStyle(color: Colors.orange)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
    );
  }

  void showUpdateDialog(Map<String, dynamic> stock) {
    String selectedType = stock["water_type"];
    String selectedSize = stock["size"];
    int amount = stock["amount"];
    int availableStock = stock["amount"]; // Original available
    String? selectedReason = stock["reason"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("✏️ Update Stock", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Water Type
                DropdownButton<String>(
                  value: selectedType,
                  dropdownColor: const Color(0xFF1B263B),
                  iconEnabledColor: Colors.white,
                  isExpanded: true,
                  items: waterTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Size
                DropdownButton<String>(
                  value: selectedSize,
                  dropdownColor: const Color(0xFF1B263B),
                  iconEnabledColor: Colors.white,
                  isExpanded: true,
                  items: sizes.map((size) {
                    return DropdownMenuItem(
                      value: size,
                      child: Text(size, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedSize = value!;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Amount controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setStateDialog(() {
                          if (amount > 0) amount--;
                        });
                      },
                      icon: const Icon(Icons.remove, color: Colors.white),
                    ),
                    Text("$amount", style: const TextStyle(color: Colors.white)),
                    IconButton(
                      onPressed: () {
                        setStateDialog(() {
                          amount++;
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Reason
                DropdownButton<String>(
                  value: selectedReason,
                  hint: const Text("Reason", style: TextStyle(color: Colors.white)),
                  dropdownColor: const Color(0xFF1B263B),
                  iconEnabledColor: Colors.white,
                  isExpanded: true,
                  items: reasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedReason = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () {
                  // ✅ Validation before updating
                  if (amount < 0) {
                    showAlert("Amount cannot be less than 0.");
                    return;
                  }

                  if (amount > availableStock) {
                    showAlert("Amount exceeds available stock ($availableStock).");
                    return;
                  }

                  final nowUtc = DateTime.now().toUtc();
                  final isoUtc = nowUtc.toIso8601String();

                  final updatedData = {
                    "water_type": selectedType,
                    "size": selectedSize,
                    "amount": amount,
                    "stock_type": stock["stock_type"],
                    "reason": selectedReason,
                    "date": isoUtc,
                  };

                  updateStock(stock["id"], updatedData);
                  Navigator.pop(context);
                },
                child: const Text("Update", style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        });
      },
    );
  }

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
        title: const Text("Update Return Stocks"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: stocks.length,
              itemBuilder: (context, index) {
                final stock = stocks[index];
                return Card(
                  color: const Color(0xFF1B263B),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    title: Text(
                      "${stock["water_type"]} - ${stock["size"]}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Amount: ${stock["amount"]} | Type: ${stock["stock_type"]}"
                      "${stock["reason"] != null ? " | Reason: ${stock["reason"]}" : ""}\n"
                      "Date: ${formatToPHTime(stock["date"])}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => showUpdateDialog(stock),
                      child: const Text("Update"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
