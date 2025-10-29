// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartStorage {
  static const _key = 'customer_cart';

  static Future<List<Map<String, dynamic>>> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<void> save(List<Map<String, dynamic>> items) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(items));
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }

  static Future<void> addItem({
    required int productId,
    required int stationId,
    required String name,
    required String imageUrl,
    required double price,
    int qty = 1,
  }) async {
    final items = await load();
    final idx = items.indexWhere((e) =>
        e['product_id'] == productId && e['station_id'] == stationId);
    if (idx >= 0) {
      items[idx]['qty'] = (items[idx]['qty'] as int) + qty;
    } else {
      items.add({
        'product_id': productId,
        'station_id': stationId,
        'name': name,
        'image_url': imageUrl,
        'price': price,
        'qty': qty,
      });
    }
    await save(items);
  }

  static Future<void> removeAt(int index) async {
    final items = await load();
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      await save(items);
    }
  }

  static Future<void> updateQty(int index, int qty) async {
    final items = await load();
    if (index >= 0 && index < items.length) {
      if (qty <= 0) {
        items.removeAt(index);
      } else {
        items[index]['qty'] = qty;
      }
      await save(items);
    }
  }
}

class CartPage extends StatefulWidget {
  final Future<void> Function(List<Map<String, dynamic>> items)? onProceed;
  final String? proceedRouteName;

  const CartPage({super.key, this.onProceed, this.proceedRouteName});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  double get _subtotal {
    double total = 0;
    for (final e in _items) {
      total += (e['price'] as num).toDouble() * (e['qty'] as int);
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    _items = await CartStorage.load();
    setState(() => _loading = false);
  }

  Future<void> _inc(int i) async {
    final q = (_items[i]['qty'] as int) + 1;
    await CartStorage.updateQty(i, q);
    await _reload();
  }

  Future<void> _dec(int i) async {
    final q = (_items[i]['qty'] as int) - 1;
    await CartStorage.updateQty(i, q);
    await _reload();
  }

  Future<void> _remove(int i) async {
    await CartStorage.removeAt(i);
    await _reload();
  }

  Future<void> _clear() async {
    await CartStorage.clear();
    await _reload();
  }

  Future<void> _proceed() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart is empty")),
      );
      return;
    }

    if (widget.proceedRouteName != null) {
      Navigator.pushNamed(context, widget.proceedRouteName!, arguments: {
        'cartItems': _items,
        'subtotal': _subtotal,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No confirmation page")),
      );
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/cart');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/orders');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    const primary = Color(0xFF6EACDA);
    const bg = Color(0xFF021526);
    const card = Color(0xFF0E1117);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          "My Cart",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              onPressed: _clear,
              tooltip: "Clear all",
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    "Your cart is empty",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final it = _items[i];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  // 🖼 Product Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      it['image_url'] ?? "",
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[700],
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.white38,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // 📄 Product info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          it['name'] ?? "Unknown Product",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          money.format(it['price']),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 🔢 Qty + Delete
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove,
                                                color: Colors.white70),
                                            onPressed: () => _dec(i),
                                          ),
                                          Text(
                                            "${it['qty']}",
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add,
                                                color: Colors.white70),
                                            onPressed: () => _inc(i),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent),
                                        onPressed: () => _remove(i),
                                        tooltip: "Remove item",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // 🧾 Subtotal Section
                    Container(
                      color: card,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Subtotal:",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                money.format(_subtotal),
                                style: const TextStyle(
                                    color: primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _proceed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "Proceed to Confirmation",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: card,
        currentIndex: 1,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary,
        unselectedItemColor: Colors.white54,
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
