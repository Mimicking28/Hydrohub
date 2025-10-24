import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class UpdateDiscard extends StatefulWidget {
  final int stationId;
  final int staffId;
  const UpdateDiscard({
    super.key,
    required this.stationId,
    required this.staffId,
  });

  @override
  State<UpdateDiscard> createState() => _UpdateDiscardState();
}

class _UpdateDiscardState extends State<UpdateDiscard> {
  List<dynamic> stocks = [];
  List<dynamic> products = [];
  bool isLoading = true;

  List<String> waterTypes = [];
  Map<String, int> productMap = {}; // name → product_id

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  // ✅ Combined fetch for products + discarded stocks
  Future<void> fetchAllData() async {
    try {
      await fetchProductsForStation();
      await fetchDiscardedStocks();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("⚠️ Error: $e")));
    }
  }

  // ✅ Fetch all 20L products (archived included)
  Future<void> fetchProductsForStation() async {
    final url =
        "http://10.0.2.2:3000/api/stocks/type/${widget.stationId}/discarded";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;

      // Filter only 20-liter products
      final filtered = data.where((p) {
        final size = (p["size_category"] ?? "").toString().toLowerCase();
        return size.contains("20") && size.contains("liter");
      }).toList();

      // Allow archived — no filtering by is_archived
      final Map<String, int> allProducts = {};
      for (var p in filtered) {
        allProducts[p["product_name"]] = p["product_id"];
      }

      setState(() {
        products = filtered;
        productMap = allProducts;
        waterTypes = allProducts.keys.toList();
      });
    } else {
      throw Exception("Failed to fetch products (${response.statusCode})");
    }
  }

  // ✅ Fetch discarded stock entries
  Future<void> fetchDiscardedStocks() async {
    final url =
        "http://10.0.2.2:3000/api/stocks/type/${widget.stationId}/discarded";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      setState(() {
        stocks = data;
      });
    } else {
      throw Exception("Failed to fetch discarded stocks");
    }
  }

  // ✅ Update record
  Future<void> updateStock(int id, Map<String, dynamic> updatedData) async {
    final url = "http://10.0.2.2:3000/api/stocks/$id";
    try {
      final response = await http.put(Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: json.encode(updatedData));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("✅ Discarded stock updated successfully")));
        fetchDiscardedStocks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Failed: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("⚠️ Error updating: $e")));
    }
  }

  // ✅ Update dialog with reason dropdown
  void showUpdateDialog(Map<String, dynamic> stock) {
    final productMatch =
        products.firstWhere((p) => p["product_id"] == stock["product_id"], orElse: () => {});
    String selectedType = productMatch["product_name"] ?? "Unknown Product";
    int amount = stock["amount"];
    String reason = stock["reason"] ?? "";
    String? selectedReason;
    String otherReason = "";

    final discardReasons = ["Leak Container", "Wrong Input", "Old Stock", "Others"];

    // Pre-fill dropdown if reason matches
    if (discardReasons.contains(reason)) {
      selectedReason = reason;
    } else if (reason.isNotEmpty) {
      selectedReason = "Others";
      otherReason = reason;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("✏️ Update Discarded Stock",
                style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 Water type dropdown
                  DropdownButton<String>(
                    value: waterTypes.contains(selectedType)
                        ? selectedType
                        : (waterTypes.isNotEmpty ? waterTypes.first : null),
                    hint: const Text("Select Water Type",
                        style: TextStyle(color: Colors.white)),
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

                  // 🔹 Amount counter
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
                          style: const TextStyle(color: Colors.white, fontSize: 18)),
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
                  const SizedBox(height: 10),

                  // 🔹 Reason dropdown
                  DropdownButton<String>(
                    value: selectedReason,
                    hint: const Text("Select Reason",
                        style: TextStyle(color: Colors.white)),
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
                      setDialogState(() {
                        selectedReason = value;
                        if (value != "Others") otherReason = "";
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // 🔹 "Others" text field
                  if (selectedReason == "Others")
                    TextField(
                      onChanged: (v) => setDialogState(() => otherReason = v),
                      controller: TextEditingController(text: otherReason),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter other reason",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF0D1B2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel",
                    style: TextStyle(color: Colors.redAccent)),
              ),
              TextButton(
                onPressed: () {
                  final productId = productMap[selectedType];
                  if (productId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("⚠️ Invalid product selected")));
                    return;
                  }

                  final finalReason = selectedReason == "Others"
                      ? (otherReason.isNotEmpty ? otherReason : "Unspecified")
                      : selectedReason ?? "Unspecified";

                  final updatedData = {
                    "product_id": productId,
                    "amount": amount,
                    "stock_type": "discarded",
                    "reason": finalReason,
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

  // ✅ Convert UTC → PH
  String formatToPHTime(String utcString) {
    try {
      final utc = DateTime.parse(utcString).toUtc();
      final ph = utc.add(const Duration(hours: 8));
      return DateFormat('yyyy-MM-dd hh:mm a').format(ph);
    } catch (_) {
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
        title: const Text("Update Discarded Stocks",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.lightBlueAccent))
          : stocks.isEmpty
              ? const Center(
                  child: Text("No discarded stocks available",
                      style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: stocks.length,
                  itemBuilder: (context, index) {
                    final stock = stocks[index];
                    final productMatch = products.firstWhere(
                        (p) => p["product_id"] == stock["product_id"],
                        orElse: () => {});
                    final name = productMatch["product_name"] ?? "Unknown Product";

                    return Card(
                      color: const Color(0xFF1B263B),
                      margin:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: ListTile(
                        title: Text(
                          "$name - 20 Liters",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Amount: ${stock["amount"]}\n"
                          "Reason: ${stock["reason"] ?? "N/A"}\n"
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
