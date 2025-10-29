// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:hydrohub/Customer/Profile/profile.dart';
import 'package:hydrohub/Customer/Product/station_product.dart';
import 'package:hydrohub/Customer/Product/cart.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  List<dynamic> stations = [];
  bool isLoading = true;
  int _selectedIndex = 0;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getPosition().then((pos) {
      _currentPosition = pos;
      _fetchStations();
    });
  }

  // ✅ Get current position
  Future<Position?> _getPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ✅ Fetch stations from backend
  Future<void> _fetchStations() async {
    try {
      final res = await http.get(Uri.parse("http://10.0.2.2:3000/api/station"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (_currentPosition != null) {
          for (var s in data) {
            if (s['latitude'] != null && s['longitude'] != null) {
              final dist = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                double.tryParse(s['latitude'].toString()) ?? 0,
                double.tryParse(s['longitude'].toString()) ?? 0,
              );
              s['distance_km'] = (dist / 1000).toStringAsFixed(1);
            } else {
              s['distance_km'] = "-";
            }
          }
        }

        setState(() {
          stations = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching stations: $e");
    }
  }

  // ✅ Bottom nav actions
  void _onTapNav(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) return;
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CartPage(proceedRouteName: '/confirm'),
        ),
      );
    } else if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Orders page coming soon.")),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CustomerProfilePage()),
      );
    }
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
        title: const Text(
          "HydroHub",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerProfilePage()),
              );
            },
          ),
        ],
      ),

      // 🧭 Station list
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
              color: primary,
              onRefresh: _fetchStations,
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: stations.length,
                itemBuilder: (context, i) {
                  final s = stations[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
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
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StationProductsPage(
                              stationId: s['station_id'],
                              stationName: s['station_name'],
                              stationData: s, // ✅ Pass full station info
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🖼 Station image
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: Image.network(
                              "http://10.0.2.2:3000/uploads/${s['profile_picture'] ?? ''}",
                              height: 170,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 170,
                                  color: Colors.grey[800],
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.grey, size: 40),
                                );
                              },
                            ),
                          ),

                          // 📄 Station details
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['station_name'] ?? "Unnamed Station",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s['address'] ?? "No address provided",
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        color: primary, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Open: ${s['opening_time'] ?? 'Unknown'} - ${s['closing_time'] ?? 'Unknown'}",
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month,
                                        color: primary, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "Days: ${(s['working_days'] as List?)?.join(', ') ?? 'Not set'}",
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: primary, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      s['distance_km'] != null
                                          ? "${s['distance_km']} km away"
                                          : "Distance unavailable",
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

      // 🔽 Bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: card,
        currentIndex: _selectedIndex,
        onTap: _onTapNav,
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
