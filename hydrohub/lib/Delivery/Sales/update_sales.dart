import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class UpdateSales extends StatefulWidget {
  final int stationId;
  final int staffId;
  const UpdateSales({super.key, required this.stationId, required this.staffId});

  @override
  State<UpdateSales> createState() => _UpdateSalesState();
}

class _UpdateSalesState extends State<UpdateSales>
    with SingleTickerProviderStateMixin {
  List<dynamic> sales = [];
  List<dynamic> products = [];
  bool isLoading = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    fetchProductsAndSales();
  }

  // ✅ Fetch both products and sales
  Future<void> fetchProductsAndSales() async {
    await fetchProducts();
    await fetchSales();
  }

  // ✅ Fetch only active (not archived) delivery products for this station
  Future<void> fetchProducts() async {
    final String apiUrl =
        "http://10.0.2.2:3000/api/products?station_id=${widget.stationId}";
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> allProducts = json.decode(response.body);

      // ✅ Filter: only NOT archived + delivery type
      final List<dynamic> filteredProducts = allProducts.where((p) {
        final bool isArchived = p["is_archived"] == true; // Boolean
        final type = (p["type"] ?? "").toString().toLowerCase();
        return !isArchived && type == "delivery";
      }).toList();

      setState(() {
        products = filteredProducts;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to fetch products: ${response.body}")),
      );
    }
  }

  // ✅ Fetch delivery sales
  Future<void> fetchSales() async {
    final String apiUrl =
        "http://10.0.2.2:3000/api/sales?type=delivery&station_id=${widget.stationId}";
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      setState(() {
        sales = json.decode(response.body);
        isLoading = false;
        _controller.forward();
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to fetch delivery sales")),
      );
    }
  }

  // ✅ Update sale (supports image upload)
  Future<void> updateSale(int id, Map<String, dynamic> updatedData,
      {File? proofImage}) async {
    final String apiUrl = "http://10.0.2.2:3000/api/sales/$id";
    final request = http.MultipartRequest("PUT", Uri.parse(apiUrl));

    // Add fields
    updatedData.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    // Attach image if available
    if (proofImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath("proof", proofImage.path),
      );
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Sale updated successfully")),
      );
      fetchSales();
    } else {
      final body = await response.stream.bytesToString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update sale: $body")),
      );
    }
  }

  // ✅ Format UTC → PH time
  String formatToPHTime(String utcString) {
    try {
      final utcTime = DateTime.parse(utcString).toUtc();
      final phTime = utcTime.add(const Duration(hours: 8));
      return DateFormat('yyyy-MM-dd hh:mm a').format(phTime);
    } catch (_) {
      return utcString;
    }
  }

  // ✅ Show Update Dialog
  void showUpdateDialog(Map<String, dynamic> sale) async {
    await fetchProducts(); // Always refresh before showing dropdown

    String selectedWater = sale["water_type"];
    String selectedSize = sale["size"];
    int quantity = sale["quantity"];
    double total = double.tryParse(sale["total"].toString()) ?? 0.0;
    String payment = sale["payment_method"];

    File? proofImage;
    final ImagePicker _picker = ImagePicker();

    final List<String> paymentMethods = ["Cash", "E-wallet"];

    // Group products by water type
    final Map<String, List<String>> waterTypeToSizes = {};
    final Map<String, Map<String, double>> priceMap = {};

    for (var p in products) {
      final type = p["name"];
      final size = p["size_category"];
      final price = double.tryParse(p["price"].toString()) ?? 0.0;

      waterTypeToSizes.putIfAbsent(type, () => []);
      if (!waterTypeToSizes[type]!.contains(size)) {
        waterTypeToSizes[type]!.add(size);
      }

      priceMap.putIfAbsent(type, () => {});
      priceMap[type]![size] = price;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B263B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "✏️ Update Sale",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔹 Water Type
                    DropdownButtonFormField<String>(
                      value: waterTypeToSizes.containsKey(selectedWater)
                          ? selectedWater
                          : null,
                      dropdownColor: const Color(0xFF1B263B),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Water Type",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      items: waterTypeToSizes.keys.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedWater = val!;
                          selectedSize = waterTypeToSizes[val]!.first;
                          total = (priceMap[selectedWater]?[selectedSize] ?? 0) * quantity;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // 🔹 Size
                    DropdownButtonFormField<String>(
                      value: selectedSize,
                      dropdownColor: const Color(0xFF1B263B),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Size",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      items: (waterTypeToSizes[selectedWater] ?? [])
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedSize = val!;
                          total = (priceMap[selectedWater]?[selectedSize] ?? 0) * quantity;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // 🔹 Quantity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              if (quantity > 1) quantity--;
                              total = (priceMap[selectedWater]?[selectedSize] ?? 0) * quantity;
                            });
                          },
                          icon: const Icon(Icons.remove_circle, color: Colors.white),
                        ),
                        Text("$quantity",
                            style: const TextStyle(color: Colors.white, fontSize: 18)),
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              quantity++;
                              total = (priceMap[selectedWater]?[selectedSize] ?? 0) * quantity;
                            });
                          },
                          icon: const Icon(Icons.add_circle, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 💰 Total
                    Text(
                      "₱${total.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 18),
                    ),
                    const SizedBox(height: 10),

                    // 🔹 Payment Method
                    DropdownButtonFormField<String>(
                      value: payment,
                      dropdownColor: const Color(0xFF1B263B),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Payment Method",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      items: paymentMethods.map((e) {
                        return DropdownMenuItem(
                            value: e,
                            child: Text(e, style: const TextStyle(color: Colors.white)));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => payment = val!),
                    ),
                    const SizedBox(height: 15),

                    // 📸 Proof (for E-wallet)
                    if (payment == "E-wallet") ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            setDialogState(() {
                              proofImage = File(image.path);
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        label: const Text("Take Payment Proof",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (proofImage != null)
                        Image.file(proofImage!,
                            height: 120, width: 120, fit: BoxFit.cover),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () {
                final data = {
                  "water_type": selectedWater,
                  "size": selectedSize,
                  "quantity": quantity,
                  "total": total,
                  "date": sale["date"],
                  "payment_method": payment,
                  "sale_type": "delivery",
                  "station_id": widget.stationId,
                  "staff_id": widget.staffId,
                };

                updateSale(sale["id"], data, proofImage: proofImage);
                Navigator.pop(context);
              },
              child: const Text("Update",
                  style: TextStyle(color: Colors.lightBlueAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        foregroundColor: Colors.white,
        title: const Text(
          "Update Delivery Sales",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: sales.isEmpty
                    ? const Center(
                        child: Text(
                          "No Delivery sales available",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: sales.length,
                        itemBuilder: (context, index) {
                          final sale = sales[index];
                          return Card(
                            color: const Color(0xFF1B263B),
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            child: ListTile(
                              title: Text(
                                "${sale["water_type"]} (${sale["size"]})",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Qty: ${sale["quantity"]}\n"
                                "₱${sale["total"]}\n"
                                "${sale["payment_method"]}\n"
                                "${formatToPHTime(sale["date"])}",
                                style:
                                    const TextStyle(color: Colors.white70),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => showUpdateDialog(sale),
                                child: const Text("Update"),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
    );
  }
}
