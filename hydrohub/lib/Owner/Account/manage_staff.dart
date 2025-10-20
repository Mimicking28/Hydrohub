import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ManageStaff extends StatefulWidget {
  final int stationId;
  const ManageStaff({super.key, required this.stationId});

  @override
  State<ManageStaff> createState() => _ActivateStaffState();
}

class _ActivateStaffState extends State<ManageStaff> {
  List<dynamic> allStaff = [];
  List<dynamic> filteredStaff = [];
  bool isLoading = true;

  String searchQuery = "";
  String selectedRole = "All";

  final List<String> roles = ["All", "Onsite", "Delivery"];

  @override
  void initState() {
    super.initState();
    fetchStaff();
  }

  // ✅ Fetch staff list by station ID
  Future<void> fetchStaff() async {
    setState(() => isLoading = true);
    try {
      final url =
          "http://10.0.2.2:3000/api/accounts/staff?station_id=${widget.stationId}";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          allStaff = data;
          filteredStaff = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to load staff: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("⚠️ Error: $e")));
    }
  }

  // ✅ Filter staff by name and role
  void filterStaff() {
    final query = searchQuery.toLowerCase();
    setState(() {
      filteredStaff = allStaff.where((staff) {
        final fullName =
            "${staff["first_name"] ?? ""} ${staff["last_name"] ?? ""}".toLowerCase();
        final username = (staff["username"] ?? "").toLowerCase();
        final role = (staff["type"] ?? "").toLowerCase();

        final matchesSearch =
            fullName.contains(query) || username.contains(query);
        final matchesRole =
            selectedRole == "All" ? true : role == selectedRole.toLowerCase();

        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  // ✅ Toggle staff status (Active/Inactive)
  Future<void> toggleStatus(int staffId) async {
    try {
      final url = "http://10.0.2.2:3000/api/accounts/staff/status/$staffId";
      final response = await http.put(Uri.parse(url));

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"] ?? "Status updated")),
        );
        fetchStaff(); // Refresh after update
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("⚠️ Error: $e")));
    }
  }

  // ✅ Build staff card with toggle switch
  Widget buildStaffCard(Map<String, dynamic> staff) {
    final bool isActive =
        (staff["status"]?.toString().toLowerCase() ?? "active") == "active";

    return Card(
      color: const Color(0xFF1B263B),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.lightBlueAccent.withOpacity(0.3),
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          "${staff["first_name"] ?? ""} ${staff["last_name"] ?? ""}",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "${staff["type"] ?? "Unknown"} • ${staff["phone_number"] ?? "No phone"}",
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isActive ? "Active" : "Inactive",
              style: TextStyle(
                color: isActive ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: isActive,
              activeColor: Colors.greenAccent,
              inactiveThumbColor: Colors.redAccent,
              onChanged: (_) => toggleStatus(staff["staff_id"]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        foregroundColor: Colors.white,
        title: const Text(
          "Activate / Deactivate Staff",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) {
                      searchQuery = val;
                      filterStaff();
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search staff...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF08315C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF08315C),
                  value: selectedRole,
                  iconEnabledColor: Colors.white,
                  items: roles
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(
                              role,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedRole = val!;
                      filterStaff();
                    });
                  },
                ),
              ],
            ),
          ),

          // 📋 Staff List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Colors.lightBlueAccent),
                  )
                : filteredStaff.isEmpty
                    ? const Center(
                        child: Text(
                          "No staff found.",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredStaff.length,
                        itemBuilder: (context, i) =>
                            buildStaffCard(filteredStaff[i]),
                      ),
          ),
        ],
      ),
    );
  }
}
