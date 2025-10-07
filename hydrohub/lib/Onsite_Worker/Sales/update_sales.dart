import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class UpdateSales extends StatefulWidget {
  const UpdateSales({super.key});

  @override
  State<UpdateSales> createState() => _UpdateOnsiteSalesState();
}

class _UpdateOnsiteSalesState extends State<UpdateSales> {
  List<dynamic> sales = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSales();
  }

  // ✅ Fetch only onsite sales
  Future<void> fetchSales() async {
    const String apiUrl = "http://10.0.2.2:3000/api/sales?type=onsite";
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      setState(() {
        sales = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to fetch onsite sales")),
      );
    }
  }

  // ✅ Update a sale by ID
  Future<void> updateSale(int id, Map<String, dynamic> updatedData) async {
    final String apiUrl = "http://10.0.2.2:3000/api/sales/$id";

    final response = await http.put(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(updatedData),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Sale updated successfully")),
      );
      fetchSales(); // refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update sale: ${response.body}")),
      );
    }
  }

  // ✅ Dialog for updating a sale
  void showUpdateDialog(Map<String, dynamic> sale) {
    String waterType = sale["water_type"];
    String size = sale["size"];
    int quantity = sale["quantity"];
    double totalAmount = double.tryParse(sale["total"].toString()) ?? 0.0;
    String paymentMethod = sale["payment_method"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("✏️ Update Onsite Sale", style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Water Type
                  TextField(
                    controller: TextEditingController(text: waterType),
                    onChanged: (value) => waterType = value,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Water Type",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Size
                  TextField(
                    controller: TextEditingController(text: size),
                    onChanged: (value) => size = value,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Size",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quantity with buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            if (quantity > 0) quantity--;
                          });
                        },
                        icon: const Icon(Icons.remove, color: Colors.white),
                      ),
                      Text("$quantity", style: const TextStyle(color: Colors.white)),
                      IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            quantity++;
                          });
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Total Amount
                  TextField(
                    controller: TextEditingController(text: totalAmount.toStringAsFixed(2)),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      totalAmount = double.tryParse(value) ?? 0.0;
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Total Amount",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Payment Method
                  TextField(
                    controller: TextEditingController(text: paymentMethod),
                    onChanged: (value) => paymentMethod = value,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Payment Method",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () {
                  final updatedData = {
                    "water_type": waterType,
                    "size": size,
                    "quantity": quantity,
                    "total": totalAmount,
                    "date": sale["date"], // keep same date
                    "payment_method": paymentMethod,
                    "sale_type": "onsite", // ensure stays onsite
                  };

                  updateSale(sale["id"], updatedData);
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

  // ✅ Format date to PH time
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
        title: const Text("Update Onsite Sales"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sales.isEmpty
              ? const Center(
                  child: Text("No onsite sales available",
                      style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return Card(
                      color: const Color(0xFF1B263B),
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: ListTile(
                        subtitle: Text(
                          "Water: ${sale["water_type"]}\n"
                          "Size: ${sale["size"]}\n"
                          "Quantity: ${sale["quantity"]}\n"
                          "Total: ₱${sale["total"]}\n"
                          "Payment: ${sale["payment_method"]}\n"
                          "Date: ${formatToPHTime(sale["date"])}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => showUpdateDialog(sale),
                          child: const Text("Update"),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
