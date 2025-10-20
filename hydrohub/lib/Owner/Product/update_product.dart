import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateProduct extends StatefulWidget {
  final int stationId; // ✅ Station foreign key

  const UpdateProduct({super.key, required this.stationId});

  @override
  State<UpdateProduct> createState() => _UpdateProductState();
}

class _UpdateProductState extends State<UpdateProduct> {
  List<dynamic> allProducts = [];
  List<dynamic> filteredProducts = [];
  bool isLoading = true;

  String selectedFilter = "All"; // ✅ All | Onsite | Delivery
  String searchQuery = "";

  final List<String> types = ["Delivery", "Onsite"];
  final List<String> onsiteSizes = ["10 liters", "20 liters"];

  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // ✅ Fetch only products for this station
  Future<void> fetchProducts() async {
    final String apiUrl =
        "http://10.0.2.2:3000/api/products?station_id=${widget.stationId}";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> products = json.decode(response.body);
        setState(() {
          allProducts = products;
          applyFilters();
          isLoading = false;
        });
      } else {
        throw Exception("Server responded ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showPopupMessage("❌ Failed to fetch products: $e");
    }
  }

  // ✅ Apply search + type filter
  void applyFilters() {
    List<dynamic> results = allProducts;

    // 🔍 Search
    if (searchQuery.isNotEmpty) {
      results = results
          .where((p) => (p["name"] ?? "")
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    }

    // 🔹 Filter by service type
    if (selectedFilter != "All") {
      results = results
          .where((p) =>
              (p["type"] ?? "")
                  .toString()
                  .toLowerCase() ==
              selectedFilter.toLowerCase())
          .toList();
    }

    setState(() => filteredProducts = results);
  }

  // ✅ Update request
  Future<void> updateProduct(int id, Map<String, String> updatedData,
      {File? image}) async {
    final String apiUrl = "http://10.0.2.2:3000/api/products/$id";
    try {
      var request = http.MultipartRequest('PUT', Uri.parse(apiUrl));
      request.fields.addAll(updatedData);
      if (image != null) {
        request.files
            .add(await http.MultipartFile.fromPath('photo', image.path));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        _showPopupMessage("✅ Product updated successfully!", success: true);
        fetchProducts();
      } else {
        _showPopupMessage("❌ Failed to update product.");
      }
    } catch (e) {
      _showPopupMessage("❌ Error: $e");
    }
  }

  Future<void> _pickImage(Function(File) onSelected) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) onSelected(File(pickedFile.path));
  }

  void _showPopupMessage(String message, {bool success = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: success ? Colors.green[100] : Colors.red[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(success ? 'Success' : 'Error',
            style: TextStyle(
                color: success ? Colors.green[900] : Colors.red[900],
                fontWeight: FontWeight.bold)),
        content: Text(message,
            style:
                TextStyle(color: success ? Colors.green[900] : Colors.red[900])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  // ✅ Dialog for editing product
  void showUpdateDialog(Map<String, dynamic> product) {
    final TextEditingController nameController =
        TextEditingController(text: product["name"] ?? "");
    final TextEditingController priceController =
        TextEditingController(text: product["price"]?.toString() ?? "");

    String selectedType = product["type"] ?? "Delivery";
    String selectedSize =
        product["size_category"] ?? (selectedType == "Delivery" ? "20 liters" : "10 liters");
    File? newImage = _image;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("✏️ Update Product",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Product Name"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Price (₱)"),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: types.map((type) {
                      bool isSelected = selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          selectedColor: Colors.blueAccent,
                          onSelected: (_) {
                            setDialogState(() {
                              selectedType = type;
                              selectedSize = type == "Delivery"
                                  ? "20 liters"
                                  : onsiteSizes.first;
                            });
                          },
                          labelStyle: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.white70),
                          backgroundColor: const Color(0xFF1B263B),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  if (selectedType == "Onsite")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: onsiteSizes.map((size) {
                        bool isSelected = selectedSize == size;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(size),
                            selected: isSelected,
                            showCheckmark: false,
                            selectedColor: Colors.green,
                            onSelected: (_) {
                              setDialogState(() => selectedSize = size);
                            },
                            labelStyle: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.white70),
                            backgroundColor: const Color(0xFF2C3E50),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),
                  if (selectedType == "Delivery")
                    GestureDetector(
                      onTap: () async {
                        await _pickImage((picked) {
                          setDialogState(() => newImage = picked);
                        });
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: newImage == null
                            ? const Center(
                                child: Text("Select New Image",
                                    style: TextStyle(color: Colors.white70)))
                            : Image.file(newImage!, fit: BoxFit.cover),
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
                  String name = nameController.text.trim();
                  String price = priceController.text.trim();

                  if (name.isEmpty ||
                      price.isEmpty ||
                      double.tryParse(price) == null) {
                    _showPopupMessage("⚠️ Please fill in all fields correctly.");
                    return;
                  }

                  bool duplicate = allProducts.any((p) =>
                      p["id"] != product["id"] &&
                      p["name"].toString().toLowerCase() ==
                          name.toLowerCase() &&
                      p["type"].toString().toLowerCase() ==
                          selectedType.toLowerCase() &&
                      p["size_category"].toString().toLowerCase() ==
                          selectedSize.toLowerCase());

                  if (duplicate) {
                    _showPopupMessage(
                        "⚠️ A product with the same name, type, and size already exists!");
                    return;
                  }

                  if (selectedType == "Delivery" && newImage == null) {
                    _showPopupMessage("⚠️ Please select an image for Delivery.");
                    return;
                  }

                  final updatedData = {
                    "name": name,
                    "price": price,
                    "type": selectedType,
                    "size_category": selectedSize,
                  };

                  updateProduct(product["id"], updatedData, image: newImage);
                  Navigator.pop(context);
                },
                child: const Text("Update",
                    style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          );
        });
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white30)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent)),
    );
  }

  // ✅ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Update Product",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Search bar
              TextField(
                onChanged: (value) {
                  searchQuery = value;
                  applyFilters();
                },
                decoration: InputDecoration(
                  hintText: "Search product...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF0A2647),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),

              // Filter chips (All / Onsite / Delivery)
              Center(
                child: Wrap(
                  spacing: 10,
                  alignment: WrapAlignment.center,
                  children: ["All", "Onsite", "Delivery"].map((filter) {
                    bool isSelected = selectedFilter == filter;
                    return ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedFilter = filter;
                          applyFilters();
                        });
                      },
                      selectedColor: const Color(0xFF205295),
                      backgroundColor: const Color(0xFF0A2647),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Product list
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredProducts.isEmpty
                        ? const Center(
                            child: Text("No products found.",
                                style: TextStyle(color: Colors.white70)))
                        : ListView.builder(
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return Card(
                                color: const Color.fromARGB(255, 1, 26, 71),
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                child: ListTile(
                                  title: Text(
                                    "${product["name"] ?? "Unnamed"} (${product["size_category"] ?? ""})",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "₱${product["price"] ?? "0"} | ${product["type"] ?? ""}",
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () =>
                                        showUpdateDialog(product),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10))),
                                    child: const Text("Update"),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
