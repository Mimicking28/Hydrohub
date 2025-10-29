import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class UpdateReturnStock extends StatefulWidget {
  final int stationId;
  final int staffId;
  const UpdateReturnStock({
    super.key,
    required this.stationId,
    required this.staffId,
  });

  @override
  State<UpdateReturnStock> createState() => _UpdateReturnStockState();
}

class _UpdateReturnStockState extends State<UpdateReturnStock> {
  List<dynamic> stocks = [];
  List<dynamic> products = [];
  bool isLoading = true;

  List<String> waterTypes = [];
  Map<String, int> productMap = {}; // name → product_id

  final List<String> returnReasons = [
    "Damaged",
    "Not Sold",
    "Customer Return",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  // ✅ Fetch products + returned stocks together
  Future<void> fetchAllData() async {
    try {
      await fetchProductsForStation();
      await fetchReturnedStocks();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("⚠️ Error: $e")));
    }
  }

  // ✅ Fetch all product records linked to returned stocks
  Future<void> fetchProductsForStation() async {
    final url =
        "http://10.0.2.2:3000/api/stocks/type/${widget.stationId}/returned";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;

      // ✅ No size filtering — include all returned items
      final Map<String, int> allProducts = {};
      for (var p in data) {
        allProducts[p["product_name"]] = p["product_id"];
      }

      setState(() {
        products = data;
        productMap = allProducts;
        waterTypes = allProducts.keys.toList();
      });
    } else {
      throw Exception("Failed to fetch products (${response.statusCode})");
    }
  }

  // ✅ Fetch returned stock entries
  Future<void> fetchReturnedStocks() async {
    final url =
        "http://10.0.2.2:3000/api/stocks/type/${widget.stationId}/returned";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      setState(() {
        stocks = data;
      });
    } else {
      throw Exception("Failed to fetch returned stocks");
    }
  }

  // ✅ Update record
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
          const SnackBar(content: Text("✅ Returned stock updated successfully")),
        );
        fetchReturnedStocks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error updating: $e")),
      );
    }
  }

  // ✅ Update Dialog
  void showUpdateDialog(Map<String, dynamic> stock) {
    final productMatch = products.firstWhere(
      (p) => p["product_id"] == stock["product_id"],
      orElse: () => {},
    );

    String selectedType = productMatch["product_name"] ?? "Unknown Product";
    int amount = stock["amount"];
    String reason = stock["reason"] ?? "";
    String? selectedReason;
    String otherReason = "";

    if (returnReasons.contains(reason)) {
      selectedReason = reason;
    } else if (reason.isNotEmpty) {
      selectedReason = "Other";
      otherReason = reason;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("✏️ Update Returned Stock",
                style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 Product Dropdown
                  DropdownButton<String>(
                    value: waterTypes.contains(selectedType)
                        ? selectedType
                        : (waterTypes.isNotEmpty ? waterTypes.first : null),
                    hint: const Text("Select Product",
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

                  // 🔹 Amount Counter
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

                  // 🔹 Reason Dropdown
                  DropdownButton<String>(
                    value: selectedReason,
                    hint: const Text("Select Reason",
                        style: TextStyle(color: Colors.white)),
                    dropdownColor: const Color(0xFF1B263B),
                    iconEnabledColor: Colors.white,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: returnReasons.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child:
                            Text(r, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedReason = value;
                        if (value != "Other") otherReason = "";
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // 🔹 "Other" text field
                  if (selectedReason == "Other")
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

                  final finalReason = selectedReason == "Other"
                      ? (otherReason.isNotEmpty ? otherReason : "Unspecified")
                      : selectedReason ?? "Unspecified";

                  final updatedData = {
                    "product_id": productId,
                    "amount": amount,
                    "stock_type": "returned",
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

  // ✅ Convert UTC → PH Time
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
        title: const Text("Update Returned Stocks",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.lightBlueAccent))
          : stocks.isEmpty
              ? const Center(
                  child: Text("No returned stocks available",
                      style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: stocks.length,
                  itemBuilder: (context, index) {
                    final stock = stocks[index];
                    final productMatch = products.firstWhere(
                      (p) => p["product_id"] == stock["product_id"],
                      orElse: () => {},
                    );
                    final name =
                        productMatch["product_name"] ?? "Unknown Product";

                    return Card(
                      color: const Color(0xFF1B263B),
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: ListTile(
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
