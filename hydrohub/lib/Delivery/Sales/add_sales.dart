import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
//import 'dart:convert';
import 'dart:io'; // For File
import 'package:image_picker/image_picker.dart'; // 📸 Camera package

import '../home_page.dart';

class AddSale extends StatefulWidget {
  const AddSale({super.key});

  @override
  State<AddSale> createState() => _AddSaleState();
}

class _AddSaleState extends State<AddSale> {
  String? selectedWaterType;
  String? selectedSize;
  String? selectedPayment;
  int quantity = 0;
  File? paymentProof;

  final ImagePicker _picker = ImagePicker();

  final List<String> waterTypes = ["Purified", "Mineral", "Alkaline"];
  final List<String> sizes = ["5L", "10L", "30L"];
  final List<String> paymentMethods = ["Cash", "E-wallet"];

  final Map<String, Map<String, double>> prices = {
    "Purified": {"5L": 20, "10L": 35, "30L": 90},
    "Mineral": {"5L": 25, "10L": 40, "30L": 100},
    "Alkaline": {"5L": 30, "10L": 45, "30L": 50},
  };

  double get totalPrice {
    if (selectedWaterType == null || selectedSize == null || quantity == 0) {
      return 0;
    }
    return (prices[selectedWaterType]?[selectedSize] ?? 0) * quantity;
  }

  Future<void> saveSaleToDatabase({
    required String waterType,
    required String size,
    required int quantity,
    required double total,
    required String date,
    required String paymentMethod,
    File? proofImage,
  }) async {
    const String apiUrl = "http://10.0.2.2:3000/api/sales";

    var request = http.MultipartRequest("POST", Uri.parse(apiUrl));
    request.fields["water_type"] = waterType;
    request.fields["size"] = size;
    request.fields["quantity"] = quantity.toString();
    request.fields["total"] = total.toStringAsFixed(2);
    request.fields["date"] = date;
    request.fields["payment_method"] = paymentMethod;
    request.fields["sale_type"] = "delivery"; // ✅ fixed as delivery

    if (proofImage != null) {
      request.files.add(await http.MultipartFile.fromPath("proof", proofImage.path));
    }

    var response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to save sale: ${response.statusCode}")),
      );
    }
  }

  void _confirmSale() async {
    if (selectedWaterType == null || selectedSize == null || quantity <= 0 || selectedPayment == null) {
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

    await saveSaleToDatabase(
      waterType: selectedWaterType!,
      size: selectedSize!,
      quantity: quantity,
      total: total,
      date: formattedDate,
      paymentMethod: selectedPayment!,
      proofImage: paymentProof,
    );

    // ✅ Confirmation Popup (no nulls)
    await showDialog(
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
              Text("Type: $selectedWaterType", style: const TextStyle(color: Colors.white)),
              Text("Size: $selectedSize", style: const TextStyle(color: Colors.white)),
              Text("Quantity: $quantity", style: const TextStyle(color: Colors.white)),
              Text("Total: ₱${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white)),
              Text("Payment: $selectedPayment", style: const TextStyle(color: Colors.white)),
              const Text("Sale Type: delivery", style: TextStyle(color: Colors.lightBlueAccent)),
              if (selectedPayment == "E-wallet" && paymentProof != null)
                const Text("Proof: 📸 Uploaded", style: TextStyle(color: Colors.greenAccent)),
              Text("Date: $formattedDate", style: const TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to home
              },
              child: const Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );

    // ✅ Clear form only after popup closes
    setState(() {
      selectedWaterType = null;
      selectedSize = null;
      selectedPayment = null;
      quantity = 0;
      paymentProof = null;
    });
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
      backgroundColor: const Color(0xFF021526), // Dark background
      body: Stack(
        children: [
          // 🔵 Top-right oval
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF6EACDA).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          // 🔵 Slightly lower top-right oval
          Positioned(
            top: -10,
            right: -80,
            child: Container(
              width: 160,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF6EACDA).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          // 🔵 Bottom-left oval
          Positioned(
            bottom: -60,
            left: -80,
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(140),
              ),
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            text: 'Hydro',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Hub',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.lightBlueAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Icon(Icons.account_circle, color: Colors.white, size: 32),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ✅ Your Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Water type dropdown
                          DropdownButton<String>(
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
                          const SizedBox(height: 20),

                          // Size chips
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: sizes.map((size) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: ChoiceChip(
                                  label: Text(size, style: const TextStyle(color: Colors.white)),
                                  selected: selectedSize == size,
                                  selectedColor: Colors.blue,
                                  onSelected: (_) {
                                    setState(() {
                                      selectedSize = size;
                                    });
                                  },
                                  backgroundColor: const Color(0xFF1B263B),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Quantity counter
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
                                child: Text("$quantity", style: const TextStyle(fontSize: 24, color: Colors.white)),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    quantity++;
                                  });
                                },
                                icon: const Icon(Icons.add_circle, color: Colors.white, size: 40),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 💰 Total
                          Text(
                            selectedWaterType == null || selectedSize == null || quantity == 0
                                ? "Total: ₱0.00"
                                : "$selectedWaterType - ₱${prices[selectedWaterType]?[selectedSize]?.toStringAsFixed(2)} "
                                  "x $quantity = ₱${totalPrice.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 18, color: Colors.greenAccent),
                          ),
                          const SizedBox(height: 20),

                          // Payment dropdown
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

                          // 📸 Camera if E-wallet
                          if (selectedPayment == "E-wallet")
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text("Upload Payment Proof"),
                                  onPressed: _pickImage,
                                ),
                                if (paymentProof != null) ...[
                                  const SizedBox(height: 10),
                                  Image.file(paymentProof!, height: 120),
                                ],
                              ],
                            ),
                          const SizedBox(height: 40),

                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                ),
                                onPressed: _confirmSale,
                                child: const Text("Confirm"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
