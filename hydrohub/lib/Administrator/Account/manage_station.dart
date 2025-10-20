import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageStationsPage extends StatefulWidget {
  const ManageStationsPage({super.key});

  @override
  State<ManageStationsPage> createState() => _ManageStationsPageState();
}

class _ManageStationsPageState extends State<ManageStationsPage> {
  List<dynamic> stations = [];
  List<dynamic> filteredStations = [];
  bool isLoading = true;

  String searchQuery = "";
  String filterStatus = "All"; // All, Active, Inactive

  @override
  void initState() {
    super.initState();
    fetchStations();
  }

  // ✅ Fetch all stations
  Future<void> fetchStations() async {
    const String apiUrl = "http://10.0.2.2:3000/api/accounts/stations";
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> allStations = json.decode(response.body);
        setState(() {
          stations = allStations;
          filteredStations = allStations;
          isLoading = false;
        });
      } else {
        throw Exception("Server responded ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showPopupMessage("❌ Failed to fetch stations: $e");
    }
  }

  // ✅ Search & Filter logic
  void _applyFilters() {
    setState(() {
      filteredStations = stations.where((station) {
        final name = (station["station_name"] ?? "").toLowerCase();
        final status = (station["status"] ?? "").toLowerCase();

        final matchesSearch = name.contains(searchQuery.toLowerCase());
        final matchesStatus = filterStatus == "All"
            ? true
            : status == filterStatus.toLowerCase();

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  // ✅ Toggle Active / Inactive status
  Future<void> toggleStatus(int id, bool currentlyInactive) async {
    final String apiUrl = "http://10.0.2.2:3000/api/accounts/stations/status/$id";

    try {
      final response = await http.put(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        await fetchStations();
        _showPopupMessage(
          currentlyInactive
              ? "✅ Station reactivated (including linked accounts)."
              : "🚫 Station deactivated (including linked accounts).",
          success: true,
        );
      } else {
        String message = "❌ Failed to update station status.";
        try {
          final parsed = json.decode(response.body);
          if (parsed is Map && parsed['error'] != null) {
            message = "❌ ${parsed['error']}";
          }
        } catch (_) {}
        _showPopupMessage(message);
      }
    } catch (e) {
      _showPopupMessage("❌ Error: $e");
    }
  }

  // ✅ Confirm toggle dialog
  Future<void> _confirmToggle(int id, bool currentlyInactive, String name) async {
    String title = currentlyInactive ? "Activate Station?" : "Deactivate Station?";
    String message = currentlyInactive
        ? "Are you sure you want to mark '$name' as active and fit for operation?"
        : "Are you sure you want to deactivate '$name'? All linked accounts will also be deactivated.";

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFEEF2F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentlyInactive ? Colors.green : Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(currentlyInactive ? "Activate" : "Deactivate"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await toggleStatus(id, currentlyInactive);
    }
  }

  // ✅ Popup message dialog
  void _showPopupMessage(String message, {bool success = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: success ? Colors.green[100] : Colors.red[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          success ? 'Success' : 'Error',
          style: TextStyle(
              color: success ? Colors.green[900] : Colors.red[900],
              fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: TextStyle(
              color: success ? Colors.green[900] : Colors.red[900]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

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
                    "Station Monitoring",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 🔍 Search + Filter Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      onChanged: (value) {
                        searchQuery = value;
                        _applyFilters();
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search station...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1B263B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: filterStatus,
                      dropdownColor: const Color(0xFF1B263B),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1B263B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: "All", child: Text("All")),
                        DropdownMenuItem(
                            value: "Active", child: Text("Active")),
                        DropdownMenuItem(
                            value: "Inactive", child: Text("Inactive")),
                      ],
                      onChanged: (value) {
                        filterStatus = value!;
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 📋 Station List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredStations.isEmpty
                        ? const Center(
                            child: Text("No stations found.",
                                style: TextStyle(color: Colors.white70)))
                        : ListView.builder(
                            itemCount: filteredStations.length,
                            itemBuilder: (context, index) {
                              final station = filteredStations[index];
                              final bool isInactive =
                                  (station["status"]?.toString().toLowerCase() == "inactive");

                              return Card(
                                color: const Color(0xFF4D6CA5),
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                child: ListTile(
                                  title: Text(
                                    station["station_name"] ?? "Unnamed Station",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "Status: ${isInactive ? "Inactive / Unfit" : "Active / Operational"}",
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => _confirmToggle(
                                      station["station_id"],
                                      isInactive,
                                      station["station_name"] ?? "Unnamed",
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isInactive
                                          ? Colors.green
                                          : Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(isInactive ? "Activate" : "Deactivate"),
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
