import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddProduct extends StatefulWidget {
  final int stationId;
  const AddProduct({super.key, required this.stationId});

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

  Future<void> _showDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A2647),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.lightBlueAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProduct() async {
    if (selectedProduct == null ||
        selectedService == null ||
        selectedSize == null ||
        _priceController.text.isEmpty) {
      _showDialog("Missing Fields", "Please fill out all required fields.");
      return;
    }

    if (double.tryParse(_priceController.text) == null) {
      _showDialog("Invalid Price", "Price must be a valid number.");
      return;
    }

    if (selectedService == "delivery" && _image == null) {
      _showDialog("Missing Image", "Please select an image for Delivery products.");
      return;
    }

    bool confirm = false;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A2647),
        title: const Text("Confirm Submission", style: TextStyle(color: Colors.white)),
        content: const Text("Do you want to add this product?",
            style: TextStyle(color: Colors.white70)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              confirm = true;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
      request.fields["station_id"] = widget.stationId.toString();

      if (_image != null) {
        request.files
            .add(await http.MultipartFile.fromPath("photo", _image!.path));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Product added successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else if (response.statusCode == 409) {
        _showDialog("Duplicate Product", "This product already exists.");
      } else {
        _showDialog("Failed", "Error adding product (${response.statusCode}).");
      }
    } catch (e) {
      _showDialog("Error", "Something went wrong: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> sizeOptions = [];
    if (selectedService == "onsite") {
      sizeOptions = ["Below 10 Liters", "20 Liters"];
    } else if (selectedService == "delivery") {
      sizeOptions = ["20 Liters"];
      selectedSize = "20 Liters";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      appBar: AppBar(
        backgroundColor: const Color(0xFF021526),
        foregroundColor: Colors.white,
        title: const Text("Add Product", 
        style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,)),
        
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            const SizedBox(height: 25),

            _buildSectionTitle("Product Name"),
            DropdownButtonFormField<String>(
              value: selectedProduct,
              dropdownColor: const Color(0xFF0A2647),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(),
              items: ["Alkaline", "Mineral", "Purified", "Distilled"]
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) => setState(() => selectedProduct = val),
            ),
            const SizedBox(height: 25),

            _buildSectionTitle("Type of Service"),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildServiceChip("Onsite", "onsite"),
                const SizedBox(width: 15),
                _buildServiceChip("Delivery", "delivery"),
              ],
            ),
            const SizedBox(height: 25),

            if (selectedService != null) ...[
              _buildSectionTitle("Size Category"),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: sizeOptions.map((size) {
                  final selected = selectedSize == size;
                  return ChoiceChip(
                    label: Text(size,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                        )),
                    selected: selected,
                    selectedColor: Colors.lightBlueAccent,
                    backgroundColor: const Color(0xFF08315C),
                    onSelected: (_) => setState(() => selectedSize = size),
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),
            ],

            _buildSectionTitle("Price"),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(hint: "Enter price (₱)"),
            ),
            const SizedBox(height: 25),

            if (selectedService == "delivery") ...[
              _buildSectionTitle("Product Image"),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Choose Image"),
                  ),
                  const SizedBox(width: 15),
                  if (_image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_image!, height: 60, width: 60, fit: BoxFit.cover),
                    ),
                ],
              ),
              const SizedBox(height: 30),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton("Cancel", const Color(0xFF08315C), () {
                  Navigator.pop(context);
                }),
                _buildActionButton("Confirm", Colors.lightBlueAccent, _submitProduct),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Helpers ----
  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF08315C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildSectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.lightBlueAccent,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );

  Widget _buildServiceChip(String label, String value) {
    final isSelected = selectedService == value;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
      selected: isSelected,
      selectedColor: Colors.lightBlueAccent,
      backgroundColor: const Color(0xFF08315C),
      onSelected: (_) => setState(() {
        selectedService = value;
        if (value == "delivery") selectedSize = "20 Liters";
      }),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(140, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
