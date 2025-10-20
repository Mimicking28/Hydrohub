import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class UpdateRefilled extends StatefulWidget {
  final int stationId;
  final int staffId;
  const UpdateRefilled({
    super.key,
    required this.stationId,
    required this.staffId,
  });

  @override
  State<UpdateRefilled> createState() => _UpdateRefilledState();
}

class _UpdateRefilledState extends State<UpdateRefilled> {
  List<dynamic> stocks = [];
  List<dynamic> products = [];
  bool isLoading = true;

  List<String> waterTypes = [];
  Map<String, int> productMap = {}; // name → product_id

  @override
  void initState() {
    super.initState();
    fetchProductsForStation();
  }

  // ✅ Fetch only unique 20L products from this station
  Future<void> fetchProductsForStation() async {
    final url = "http://10.0.2.2:3000/api/products?station_id=${widget.stationId}";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Filter for 20-liter items
        final filtered = data.where((p) {
          final size = (p["size_category"] ?? "").toString().toLowerCase();
          return size.contains("20") && size.contains("liter");
        }).toList();

        // Remove duplicates (onsite + delivery considered same)
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
        });

        await fetchRefilledStocks();
      } else {
        throw Exception("Failed to fetch products (${response.statusCode})");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Failed to load products: $e")));
    }
  }

  // ✅ Fetch refilled stock records for this station
  Future<void> fetchRefilledStocks() async {
    final url = "http://10.0.2.2:3000/api/stocks/refilled?station_id=${widget.stationId}";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        setState(() {
          stocks = data;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch refilled stocks");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("⚠️ Error fetching stocks: $e")));
    }
  }

  // ✅ Update a refilled stock entry
  Future<void> updateStock(int id, Map<String, dynamic> updatedData) async {
    final url = "http://10.0.2.2:3000/api/stocks/$id";
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(updatedData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Refilled stock updated successfully")),
        );
        fetchRefilledStocks();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("❌ Update failed: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("⚠️ Error updating: $e")));
    }
  }

  // ✅ Update Dialog
  void showUpdateDialog(Map<String, dynamic> stock) {
    final currentProduct = products.firstWhere(
      (p) => p["id"] == stock["product_id"],
      orElse: () => {},
    );

    String selectedType = currentProduct["name"] ?? "Unknown";
    int amount = stock["amount"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("✏️ Update Refilled Stock",
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Water Type Dropdown
                DropdownButton<String>(
                  value: selectedType,
                  dropdownColor: const Color(0xFF1B263B),
                  iconEnabledColor: Colors.white,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: waterTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child:
                          Text(type, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 10),
                const Text("Size: 20 Liters",
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),

                // Amount Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setDialogState(() {
                          if (amount > 0) amount--;
                        });
                      },
                      icon: const Icon(Icons.remove_circle, color: Colors.white),
                    ),
                    Text("$amount",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18)),
                    IconButton(
                      onPressed: () {
                        setDialogState(() {
                          amount++;
                        });
                      },
                      icon: const Icon(Icons.add_circle, color: Colors.white),
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
                  final productId = productMap[selectedType];
                  if (productId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("⚠️ Invalid product selected")));
                    return;
                  }

                  final updatedData = {
                    "product_id": productId,
                    "amount": amount,
                    "stock_type": "refilled",
                    "date": stock["date"],
                    "staff_id": widget.staffId
                  };

                  updateStock(stock["id"], updatedData);
                  Navigator.pop(context);
                },
                child: const Text("Update",
                    style: TextStyle(color: Colors.lightBlueAccent)),
              ),
            ],
          );
        });
      },
    );
  }

  // ✅ Convert UTC → PH time
  String formatToPHTime(String utcString) {
    try {
      final utc = DateTime.parse(utcString).toUtc();
      final ph = utc.add(const Duration(hours: 8));
      return DateFormat('yyyy-MM-dd hh:mm a').format(ph);
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
        title: const Text("Update Refilled Stocks",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.lightBlueAccent))
          : stocks.isEmpty
              ? const Center(
                  child: Text("No refilled stocks available",
                      style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: stocks.length,
                  itemBuilder: (context, index) {
                    final stock = stocks[index];
                    final product = products.firstWhere(
                      (p) => p["id"] == stock["product_id"],
                      orElse: () => {},
                    );

                    final name = product["name"] ?? "Unknown";

                    return Card(
                      color: const Color(0xFF1B263B),
                      margin:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: ListTile(
                        title: Text(
                          "$name - 20 Liters",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Amount: ${stock["amount"]}\n"
                          "Date: ${formatToPHTime(stock["date"])}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
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
