import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../home_page.dart';

class DeliveryStock extends StatefulWidget {
  final int stationId;
  final int staffId;

  const DeliveryStock({
    super.key,
    required this.stationId,
    required this.staffId,
  });

  @override
  State<DeliveryStock> createState() => _DeliveryStockState();
}

class _DeliveryStockState extends State<DeliveryStock> {
  String? selectedType;
  int amount = 0;

  List<dynamic> products = [];
  List<String> waterTypes = []; // 20L types
  Map<String, int> productMap = {}; // type → product_id
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProductsForStation();
  }

  // ✅ Fetch unique 20-liter products from this station
  Future<void> fetchProductsForStation() async {
    final String apiUrl =
        "http://10.0.2.2:3000/api/products?station_id=${widget.stationId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Keep only 20L products
        final filtered = data.where((p) {
          final size = (p["size_category"] ?? "").toString().toLowerCase();
          return size.contains("20") && size.contains("liter");
        }).toList();

        // Unique names
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

  // ✅ Fetch available stock count from backend
  Future<int> fetchAvailableStock(int productId) async {
    const String apiUrl = "http://10.0.2.2:3000/api/stocks/available";

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "product_id": productId,
        "station_id": widget.stationId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["available"] ?? 0;
    } else {
      throw Exception("❌ Failed to fetch available stock: ${response.body}");
    }
  }

  // ✅ Save delivery stock record
  Future<void> saveDeliveredStock({
    required int productId,
    required int amount,
    required String date,
  }) async {
    const String apiUrl = "http://10.0.2.2:3000/api/stocks";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "product_id": productId,
          "amount": amount,
          "stock_type": "delivered",
          "reason": "",
          "date": date,
          "staff_id": widget.staffId,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Stock delivered successfully")),
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

  // ✅ Confirm delivery
  void _confirmDelivery() async {
    if (selectedType == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please select a water type and amount")),
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

      if (available - amount < 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("⚠️ Exceeds Available Stock",
                style: TextStyle(color: Colors.white)),
            content: Text(
              "You only have $available available for $selectedType (20 Liters). "
              "Delivering $amount will make it negative.",
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

      final nowUtc = DateTime.now().toUtc();
      final isoUtc = nowUtc.toIso8601String();
      final phTime = nowUtc.add(const Duration(hours: 8));
      final formattedPHTime = DateFormat('yyyy-MM-dd hh:mm a').format(phTime);

      await saveDeliveredStock(
        productId: productId,
        amount: amount,
        date: isoUtc,
      );

      // ✅ Success dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("🚚 Stock Delivered", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Water Type: $selectedType",
                    style: const TextStyle(color: Colors.white)),
                const Text("Size: 20 Liters",
                    style: TextStyle(color: Colors.white)),
                Text("Amount: $amount",
                    style: const TextStyle(color: Colors.white)),
                Text("Date: $formattedPHTime",
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
          );
        },
      ).then((_) {
        setState(() {
          selectedType = null;
          amount = 0;
        });
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
          ? const Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 🔹 Header
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
                        const Icon(Icons.account_circle, color: Colors.white, size: 32),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // 🔹 Dropdown for 20L water types
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
                              child:
                                  Text(type, style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedType = value);
                          },
                        ),
                      ),

                    const SizedBox(height: 30),

                    const Text("Size: 20 Liters",
                        style: TextStyle(color: Colors.white70, fontSize: 16)),

                    const SizedBox(height: 30),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Number of Containers:",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                    ),

                    const SizedBox(height: 8),

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
                            style: const TextStyle(fontSize: 20, color: Colors.white),
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
                              horizontal: 30,
                              vertical: 15,
                            ),
                          ),
                          onPressed: _confirmDelivery,
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
                              horizontal: 30,
                              vertical: 15,
                            ),
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
