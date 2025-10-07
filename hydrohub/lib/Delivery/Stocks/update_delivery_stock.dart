import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class UpdateDeliveryStock extends StatefulWidget {
  const UpdateDeliveryStock({super.key});

  @override
  State<UpdateDeliveryStock> createState() => _UpdateDeliveryStockState();
}

class _UpdateDeliveryStockState extends State<UpdateDeliveryStock> {
  List<dynamic> stocks = [];
  bool isLoading = true;

  final List<String> waterTypes = ["Purified", "Mineral", "Alkaline"];
  final List<String> sizes = ["5L", "10L", "30L"];

  @override
  void initState() {
    super.initState();
    fetchStocks();
  }

  // ✅ Fetch only delivered stocks
  Future<void> fetchStocks() async {
    const String apiUrl = "http://10.0.2.2:3000/api/stocks";
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final allStocks = json.decode(response.body);

        setState(() {
          stocks = allStocks
              .where((stock) =>
                  stock["stock_type"] != null &&
                  stock["stock_type"].toString().toLowerCase() == "delivered")
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception("Server responded ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to fetch stocks: $e")),
      );
    }
  }

  // ✅ Update stock entry
  Future<void> updateStock(int id, Map<String, dynamic> updatedData) async {
    final String apiUrl = "http://10.0.2.2:3000/api/stocks/$id";

    try {
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
        throw Exception(response.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update stock: $e")),
      );
    }
  }

  // ✅ Update dialog with validation
  void showUpdateDialog(Map<String, dynamic> stock) {
    String selectedType = stock["water_type"] ?? "Purified";
    String selectedSize = stock["size"] ?? "5L";
    int amount = (stock["amount"] ?? 0).toInt();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("✏️ Update Stock",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Water Type Dropdown
                DropdownButton<String>(
                  value: selectedType,
                  dropdownColor: const Color(0xFF1B263B),
                  iconEnabledColor: Colors.white,
                  isExpanded: true,
                  items: waterTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type,
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // ✅ Size Dropdown
                DropdownButton<String>(
                  value: selectedSize,
                  dropdownColor: const Color(0xFF1B263B),
                  iconEnabledColor: Colors.white,
                  isExpanded: true,
                  items: sizes.map((size) {
                    return DropdownMenuItem(
                      value: size,
                      child: Text(size,
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedSize = value!;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // ✅ Amount Counter
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
                    Text("$amount",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16)),
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text("Cancel", style: TextStyle(color: Colors.redAccent)),
              ),
              TextButton(
                onPressed: () {
                  final nowUtc = DateTime.now().toUtc();
                  final updatedData = {
                    "water_type": selectedType,
                    "size": selectedSize,
                    "amount": amount,
                    "stock_type": stock["stock_type"],
                    "date": nowUtc.toIso8601String(),
                  };

                  updateStock(stock["id"], updatedData);
                  Navigator.pop(context);
                },
                child:
                    const Text("Update", style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          );
        });
      },
    );
  }

  // ✅ Convert UTC to PH Time
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
        title: const Text("Update Delivered Stocks"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : stocks.isEmpty
              ? const Center(
                  child: Text("No delivered stocks found.",
                      style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: stocks.length,
                  itemBuilder: (context, index) {
                    final stock = stocks[index];
                    return Card(
                      color: const Color(0xFF1B263B),
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: ListTile(
                        title: Text(
                          "${stock["water_type"] ?? "Unknown"} - ${stock["size"] ?? ""}",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Amount: ${stock["amount"] ?? 0} | Type: ${stock["stock_type"] ?? ""}\n"
                          "Date: ${formatToPHTime(stock["date"] ?? "")}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
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
