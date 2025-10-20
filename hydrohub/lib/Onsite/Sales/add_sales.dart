import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../home_page.dart';

class AddSale extends StatefulWidget {
  final int stationId;
  final int staffId;

  const AddSale({
    super.key,
    required this.stationId,
    required this.staffId,
  });

  @override
  State<AddSale> createState() => _AddSaleState();
}

class _AddSaleState extends State<AddSale> {
  String? selectedProduct;
  String? selectedSize;
  String? selectedPayment;
  int quantity = 0;
  File? paymentProof;

  final ImagePicker _picker = ImagePicker();

  List<dynamic> products = [];
  Map<String, Map<String, double>> productMap = {}; // name → {size: price}
  List<String> availableProducts = [];
  List<String> availableSizes = [];

  final List<String> paymentMethods = ["Cash", "E-wallet"];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOnsiteProducts();
  }

  // ✅ Fetch onsite products for this station
  Future<void> fetchOnsiteProducts() async {
    final String apiUrl =
        "http://10.0.2.2:3000/api/products?station_id=${widget.stationId}&type=onsite";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final Map<String, Map<String, double>> newProductMap = {};
        final Set<String> productSet = {};

        for (var p in data) {
          final name = p["name"] ?? "Unknown";
          final size = p["size_category"] ?? "N/A";
          final price = double.tryParse(p["price"].toString()) ?? 0.0;

          productSet.add(name);
          newProductMap.putIfAbsent(name, () => {});
          newProductMap[name]![size] = price;
        }

        setState(() {
          products = data;
          productMap = newProductMap;
          availableProducts = productSet.toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch onsite products");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to load products: $e")),
      );
    }
  }

  // ✅ Compute total price
  double get totalPrice {
    if (selectedProduct == null || selectedSize == null || quantity <= 0) return 0;
    return (productMap[selectedProduct]?[selectedSize] ?? 0) * quantity;
  }

  // ✅ Confirm sale
  void _confirmSale() async {
    if (selectedProduct == null ||
        selectedSize == null ||
        quantity <= 0 ||
        selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please complete all fields")),
      );
      return;
    }

    if (selectedPayment == "E-wallet" && paymentProof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please upload E-wallet payment proof")),
      );
      return;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final double total = totalPrice;

    const String apiUrl = "http://10.0.2.2:3000/api/sales";

    var request = http.MultipartRequest("POST", Uri.parse(apiUrl));
    request.fields["product_name"] = selectedProduct!;
    request.fields["size"] = selectedSize!;
    request.fields["quantity"] = quantity.toString();
    request.fields["total"] = total.toStringAsFixed(2);
    request.fields["date"] = formattedDate;
    request.fields["payment_method"] = selectedPayment!;
    request.fields["sale_type"] = "onsite";
    request.fields["staff_id"] = widget.staffId.toString();

    if (paymentProof != null) {
      request.files.add(await http.MultipartFile.fromPath("proof", paymentProof!.path));
    }

    var response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      // ✅ Show confirmation only on success
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF021526),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("✅ Sale Confirmed", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Product: $selectedProduct", style: const TextStyle(color: Colors.white)),
                Text("Size: $selectedSize", style: const TextStyle(color: Colors.white)),
                Text("Quantity: $quantity", style: const TextStyle(color: Colors.white)),
                Text("Total: ₱${total.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.greenAccent)),
                Text("Payment: $selectedPayment", style: const TextStyle(color: Colors.white)),
                if (selectedPayment == "E-wallet" && paymentProof != null)
                  const Text("Proof: 📸 Uploaded",
                      style: TextStyle(color: Colors.lightBlueAccent)),
                Text("Date: $formattedDate", style: const TextStyle(color: Colors.white70)),
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
      );

      // Reset form after successful save
      setState(() {
        selectedProduct = null;
        selectedSize = null;
        selectedPayment = null;
        quantity = 0;
        paymentProof = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to save sale: ${response.statusCode}")),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        paymentProof = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent))
            : Padding(
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
                    const SizedBox(height: 30),

                    // Product dropdown
                    DropdownButton<String>(
                      hint: const Text("Select Product", style: TextStyle(color: Colors.white)),
                      value: selectedProduct,
                      dropdownColor: const Color(0xFF1B263B),
                      iconEnabledColor: Colors.white,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: availableProducts.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedProduct = value;
                          selectedSize = null;
                          availableSizes = productMap[value]?.keys.toList() ?? [];
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Sizes
                    if (selectedProduct != null)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: availableSizes.map((size) {
                          final isSelected = selectedSize == size;
                          return ChoiceChip(
                            label: Text(size, style: const TextStyle(color: Colors.white)),
                            selected: isSelected,
                            selectedColor: Colors.blue,
                            onSelected: (_) => setState(() => selectedSize = size),
                            backgroundColor: const Color(0xFF1B263B),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),

                    // Quantity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (quantity > 0) quantity--;
                            });
                          },
                          icon: const Icon(Icons.remove_circle, color: Colors.white, size: 40),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text("$quantity",
                              style: const TextStyle(fontSize: 24, color: Colors.white)),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => quantity++);
                          },
                          icon: const Icon(Icons.add_circle, color: Colors.white, size: 40),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Price & Total
                    if (selectedProduct != null && selectedSize != null)
                      Text(
                        "₱${productMap[selectedProduct]?[selectedSize]?.toStringAsFixed(2)} per container",
                        style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 16),
                      ),
                    Text(
                      "Total: ₱${totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 18),
                    ),
                    const SizedBox(height: 20),

                    // Payment method
                    DropdownButton<String>(
                      hint: const Text("Payment Method", style: TextStyle(color: Colors.white)),
                      value: selectedPayment,
                      dropdownColor: const Color(0xFF1B263B),
                      iconEnabledColor: Colors.white,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: paymentMethods.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPayment = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // E-wallet proof
                    if (selectedPayment == "E-wallet")
                      Column(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            label: const Text("Upload Payment Proof",
                                style: TextStyle(color: Colors.white)),
                            onPressed: _pickImage,
                          ),
                          if (paymentProof != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Image.file(paymentProof!, height: 120),
                            ),
                        ],
                      ),

                    const Spacer(),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                          onPressed: _confirmSale,
                          child: const Text("Confirm", style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel", style: TextStyle(color: Colors.white)),
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
