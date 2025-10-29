// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hydrohub/Sessions/customer_session.dart';

class CustomerAddressPage extends StatefulWidget {
  const CustomerAddressPage({super.key});

  @override
  State<CustomerAddressPage> createState() => _CustomerAddressPageState();
}

class _CustomerAddressPageState extends State<CustomerAddressPage> {
  List<dynamic> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  // ✅ Fetch addresses from DB
  Future<void> _fetchAddresses() async {
    try {
      final res = await http.get(Uri.parse(
          "http://10.0.2.2:3000/api/customers/${CustomerSession.customerId}/addresses"));
      if (res.statusCode == 200) {
        setState(() {
          addresses = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        debugPrint("❌ Failed to fetch addresses: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error loading addresses: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ✅ Delete address
  Future<void> _deleteAddress(int addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Address"),
        content: const Text("Are you sure you want to delete this address?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.delete(Uri.parse(
          "http://10.0.2.2:3000/api/customers/${CustomerSession.customerId}/addresses/$addressId"));
      if (res.statusCode == 200) {
        _fetchAddresses();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Address deleted successfully")));
      }
    } catch (e) {
      debugPrint("❌ Error deleting address: $e");
    }
  }

  // ✅ Set as default
  Future<void> _setDefaultAddress(int addressId) async {
    try {
      final res = await http.put(Uri.parse(
          "http://10.0.2.2:3000/api/customers/${CustomerSession.customerId}/addresses/$addressId/default"));
      if (res.statusCode == 200) {
        _fetchAddresses();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Default address updated")));
      }
    } catch (e) {
      debugPrint("❌ Error setting default: $e");
    }
  }

  // ✅ Open Add Address modal
  void _openAddAddressModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddAddressSheet(),
    ).then((value) {
      if (value == true) _fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF021526);
    const primary = Color(0xFF6EACDA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Addresses",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : addresses.isEmpty
              ? _emptyState(primary)
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final addr = addresses[index];
                    final isDefault = addr["is_default"] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E1117),
                        borderRadius: BorderRadius.circular(14),
                        border: isDefault
                            ? Border.all(color: primary, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: primary, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addr["label"] ?? "Address",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  addr["address"] ?? "No address details",
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                                if (addr["note"] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Note: ${addr["note"]}",
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white70),
                            color: const Color(0xFF1B263B),
                            onSelected: (value) {
                              if (value == "default") {
                                _setDefaultAddress(addr["address_id"]);
                              } else if (value == "delete") {
                                _deleteAddress(addr["address_id"]);
                              }
                            },
                            itemBuilder: (context) => [
                              if (!isDefault)
                                const PopupMenuItem(
                                  value: "default",
                                  child: Text("Set as Default",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              const PopupMenuItem(
                                value: "delete",
                                child: Text("Delete",
                                    style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _openAddAddressModal,
            icon: const Icon(Icons.add_location_alt, color: Colors.white),
            label: const Text(
              "Add New Address",
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 80, color: Colors.white24),
            const SizedBox(height: 12),
            const Text(
              "No saved address yet",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _openAddAddressModal,
              icon:
                  const Icon(Icons.add_location_alt, color: Colors.white),
              label: const Text("Add New Address",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            )
          ],
        ),
      ),
    );
  }
}

// =====================================================
// 📍 Add/Update Address Modal
// =====================================================
class AddAddressSheet extends StatefulWidget {
  const AddAddressSheet({super.key});

  @override
  State<AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<AddAddressSheet> {
  final _addressInput = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  final LatLng _tagbilaranCenter = const LatLng(9.6477, 123.8556);

  Future<void> _findAddressOnMap() async {
    if (_addressInput.text.trim().isEmpty) return;

    try {
      List<Location> locations =
          await locationFromAddress("${_addressInput.text}, Tagbilaran City, Bohol");
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final pos = LatLng(loc.latitude, loc.longitude);

        if (loc.latitude < 9.62 ||
            loc.latitude > 9.68 ||
            loc.longitude < 123.82 ||
            loc.longitude > 123.88) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Address must be within Tagbilaran City.")));
          return;
        }

        setState(() => _selectedPosition = pos);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't locate that address.")));
    }
  }

  Future<void> _saveAddress() async {
    if (_selectedPosition == null || _addressInput.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please enter an address and select location.")));
      return;
    }

    try {
      final res = await http.post(
        Uri.parse(
            "http://10.0.2.2:3000/api/customers/${CustomerSession.customerId}/addresses"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "label": "Home",
          "address": _addressInput.text,
          "note": "Default delivery address",
          "latitude": _selectedPosition!.latitude,
          "longitude": _selectedPosition!.longitude,
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["success"] == true) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data["error"] ?? "Failed to save address.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Server error.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6EACDA);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 4,
              width: 50,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const Text(
              "Add Delivery Address",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressInput,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter your address within Tagbilaran City",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1B263B),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: primary),
                  onPressed: _findAddressOnMap,
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF1B263B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: _tagbilaranCenter, zoom: 14.5),
                  onMapCreated: (c) => _mapController = c,
                  markers: _selectedPosition != null
                      ? {
                          Marker(
                            markerId: const MarkerId("pin"),
                            position: _selectedPosition!,
                            draggable: true,
                            onDragEnd: (pos) =>
                                setState(() => _selectedPosition = pos),
                          ),
                        }
                      : {},
                  onTap: (pos) {
                    if (pos.latitude >= 9.62 &&
                        pos.latitude <= 9.68 &&
                        pos.longitude >= 123.82 &&
                        pos.longitude <= 123.88) {
                      setState(() => _selectedPosition = pos);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveAddress,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text("Save Address",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
