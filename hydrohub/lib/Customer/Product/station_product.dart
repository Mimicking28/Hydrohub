// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hydrohub/Customer/Product/cart.dart';
import 'package:hydrohub/Customer/Profile/profile.dart';
import 'package:hydrohub/Customer/home_page.dart';
import 'package:hydrohub/Customer/Product/confirm_order.dart';
import 'package:hydrohub/Customer/Product/order.dart' show OrdersPage;

class StationProductsPage extends StatefulWidget {
  final int stationId;
  final String stationName;
  final Map<String, dynamic> stationData; // ✅ added

  const StationProductsPage({
    super.key,
    required this.stationId,
    required this.stationName,
    required this.stationData,
  });

  @override
  State<StationProductsPage> createState() => _StationProductsPageState();
}

class _StationProductsPageState extends State<StationProductsPage> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final res = await http.get(
        Uri.parse("http://10.0.2.2:3000/api/products?station_id=${widget.stationId}"),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List) {
          final deliveryProducts = body.where((p) {
            final type = (p['type'] ?? '').toString().toLowerCase();
            final archived = p['is_archived'] == true || p['is_archived'] == 'true';
            return type == 'delivery' && !archived;
          }).map((p) => Map<String, dynamic>.from(p)).toList();

          setState(() {
            products = deliveryProducts;
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Error fetching products: $e");
      setState(() => isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerHomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CartPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrdersPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerProfilePage()),
        );
        break;
    }
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    await CartStorage.addItem(
      productId: product['id'],
      stationId: widget.stationId,
      name: product['name'] ?? "Unnamed Product",
      imageUrl: "http://10.0.2.2:3000/uploads/${product['photo'] ?? ''}",
      price: double.tryParse(product['price'].toString()) ?? 0,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF6EACDA),
        content: Text(
          "${product['name']} added to cart!",
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _proceedToConfirm() async {
    final cartItems = await CartStorage.load();
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty")),
      );
      return;
    }

    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + ((item['price'] as num).toDouble() * (item['qty'] as int)),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmOrderPage(
          cartItems: cartItems,
          subtotal: subtotal,
          stationId: widget.stationId,
          stationName: widget.stationName,
          openingTime: widget.stationData['opening_time'] ?? "08:00",
          closingTime: widget.stationData['closing_time'] ?? "17:00",
          workingDays: List<String>.from(widget.stationData['working_days'] ?? []),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6EACDA);
    const bg = Color(0xFF021526);
    const card = Color(0xFF0E1117);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 1,
        centerTitle: true,
        title: Text(
          widget.stationName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
            tooltip: "Go to confirmation",
            onPressed: _proceedToConfirm,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : products.isEmpty
              ? const Center(
                  child: Text(
                    "No delivery products available.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final product = products[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🖼 Product Image
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(
                              "http://10.0.2.2:3000/uploads/${product['photo'] ?? ''}",
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 150,
                                  color: Colors.grey[800],
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.grey, size: 40),
                                );
                              },
                            ),
                          ),

                          // 🧾 Product Details
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'] ?? "Unnamed Product",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product['size_category'] ?? "No size info",
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "₱${product['price'] ?? '0.00'}",
                                  style: const TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _addToCart(product),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text("Add to Cart",
                                            style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _proceedToConfirm,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text("Buy Now",
                                            style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: card,
        selectedItemColor: primary,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_rounded), label: "Cart"),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded), label: "Orders"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }
}
 