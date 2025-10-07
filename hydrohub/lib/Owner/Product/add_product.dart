import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final TextEditingController _priceController = TextEditingController();

  String? selectedProduct;
  String? selectedService;
  String? selectedSize;
  File? _image;

  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // 🔹 Validation Dialog Helper
  Future<void> _showValidationDialog(String message) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Validation Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // 🔹 Confirmation Dialog before submitting
  Future<bool> _showConfirmationDialog() async {
    bool confirmed = false;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Submission"),
        content: const Text("Are you sure you want to add this product?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              confirmed = true;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
    return confirmed;
  }

  Future<void> _submitProduct() async {
    // ✅ Empty field validation
    if (selectedProduct == null ||
        selectedService == null ||
        selectedSize == null ||
        _priceController.text.isEmpty) {
      _showValidationDialog("Please fill out all fields.");
      return;
    }

    // ✅ Numeric price validation
    if (double.tryParse(_priceController.text) == null) {
      _showValidationDialog("Price must be a number.");
      return;
    }

    // ✅ Require image only for Delivery
    if (selectedService == "delivery" && _image == null) {
      _showValidationDialog("Please select an image for Delivery.");
      return;
    }

    // ✅ Ask for confirmation before submitting
    bool confirm = await _showConfirmationDialog();
    if (!confirm) return;

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("http://10.0.2.2:3000/api/products"),
      );

      request.fields["name"] = selectedProduct!;
      request.fields["type"] = selectedService!;
      request.fields["size_category"] = selectedSize!;
      request.fields["price"] = _priceController.text;

      if (_image != null) {
        request.files
            .add(await http.MultipartFile.fromPath("photo", _image!.path));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Product added successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (response.statusCode == 409) {
        _showValidationDialog("❌ Product already exists.");
      } else {
        _showValidationDialog("⚠️ Failed to add product (${response.statusCode}).");
      }
    } catch (e) {
      _showValidationDialog("❌ Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Dynamic size options based on service type
    List<String> sizeOptions = [];
    if (selectedService == "onsite") {
      sizeOptions = ["Below 10 Liters", "20 Liters"];
    } else if (selectedService == "delivery") {
      sizeOptions = ["20 Liters"];
      selectedSize = "20 Liters"; // auto-select 20L
    }

    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2647),
        title: const Text(
          "HydroHub",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Name of Product", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 5),
            DropdownButtonFormField<String>(
              value: selectedProduct,
              dropdownColor: const Color(0xFF144272),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF205295),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: ["Alkaline", "Mineral", "Distilled"].map((product) {
                return DropdownMenuItem(
                    value: product,
                    child: Text(product,
                        style: const TextStyle(color: Colors.white)));
              }).toList(),
              onChanged: (val) => setState(() => selectedProduct = val),
            ),
            const SizedBox(height: 20),

            const Text("Type of Service", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 5),
            Row(
              children: [
                ChoiceChip(
                  label: const Text("Onsite"),
                  selected: selectedService == "onsite",
                  onSelected: (selected) {
                    setState(() {
                      selectedService = "onsite";
                      selectedSize = null;
                      _image = null;
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Delivery"),
                  selected: selectedService == "delivery",
                  onSelected: (selected) {
                    setState(() {
                      selectedService = "delivery";
                      selectedSize = "20 Liters";
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (selectedService != null) ...[
              const Text("Size", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 5),
              Wrap(
                spacing: 10,
                children: sizeOptions.map((size) {
                  return ChoiceChip(
                    label: Text(size),
                    selected: selectedSize == size,
                    onSelected: (selected) {
                      setState(() => selectedSize = size);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            const Text("Price", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 5),
            TextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF205295),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),

            if (selectedService == "delivery") ...[
              const Text("Proof Image",
                  style: TextStyle(color: Colors.white)),
              const SizedBox(height: 5),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF205295)),
                    child: const Text("Pick Image",
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  _image != null
                      ? Image.file(_image!, height: 60)
                      : const SizedBox(),
                ],
              ),
              const SizedBox(height: 30),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF205295)),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: _submitProduct,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue),
                  child: const Text("Confirm",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
