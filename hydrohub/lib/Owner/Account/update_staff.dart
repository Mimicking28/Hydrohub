import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UpdateStaff extends StatefulWidget {
  final int stationId;
  const UpdateStaff({super.key, required this.stationId});

  @override
  State<UpdateStaff> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<UpdateStaff> {
  List<dynamic> allStaff = [];
  List<dynamic> filteredStaff = [];
  bool isLoading = true;

  String searchQuery = "";
  String selectedRole = "All";

  final List<String> roles = [
    "All",
    "Onsite",
    "Delivery",
  ];

  @override
  void initState() {
    super.initState();
    fetchStaff();
  }

  // ✅ Fetch staff from backend
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
        throw Exception("Failed to load staff");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error loading staff: $e")),
      );
    }
  }

  // ✅ Search staff by name or username
  void filterStaff() {
    final query = searchQuery.toLowerCase();
    setState(() {
      filteredStaff = allStaff.where((staff) {
        final fullName =
            "${staff["first_name"] ?? ""} ${staff["last_name"] ?? ""}".toLowerCase();
        final username = (staff["username"] ?? "").toLowerCase();
        final type = (staff["type"] ?? "").toLowerCase();

        final matchesSearch =
            fullName.contains(query) || username.contains(query);
        final matchesRole = selectedRole == "All"
            ? true
            : type == selectedRole.toLowerCase();

        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  // ✅ Dialog to update staff details (NO status dropdown)
  void showUpdateDialog(Map<String, dynamic> staff) {
    final firstName = TextEditingController(text: staff["first_name"] ?? "");
    final lastName = TextEditingController(text: staff["last_name"] ?? "");
    final phone = TextEditingController(text: staff["phone_number"] ?? "");
    final password = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1B263B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Update Staff Account",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  _buildTextField("First Name", firstName),
                  const SizedBox(height: 10),
                  _buildTextField("Last Name", lastName),
                  const SizedBox(height: 10),
                  _buildTextField("Phone Number", phone,
                      type: TextInputType.phone),
                  const SizedBox(height: 10),
                  _buildTextField("New Password (optional)", password,
                      obscure: true),
                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final updated = {
                            "first_name": firstName.text.trim(),
                            "last_name": lastName.text.trim(),
                            "phone_number": phone.text.trim(),
                          };
                          if (password.text.isNotEmpty) {
                            updated["password"] = password.text.trim();
                          }
                          updateStaff(staff["staff_id"], updated);
                          Navigator.pop(context);
                        },
                        child: const Text("Save",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ PUT request to update staff
  Future<void> updateStaff(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse("http://10.0.2.2:3000/api/accounts/staff/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Staff updated successfully")),
        );
        fetchStaff();
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

  // ✅ TextField builder
  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscure = false, TextInputType? type}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF08315C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ✅ Card UI for each staff
  Widget _buildStaffCard(Map<String, dynamic> staff) {
    return Card(
      color: const Color(0xFF1B263B),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
          "${staff["type"] ?? "Unknown"} • ${staff["status"] ?? "Active"}\n${staff["phone_number"] ?? "No phone"}",
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.lightBlueAccent),
          onPressed: () => showUpdateDialog(staff),
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
        foregroundColor: const Color.fromARGB(255, 255, 255, 255), 
        title: const Text(
          "Update Staff",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search and Filter
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
                          borderSide: BorderSide.none),
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
                            child: Text(role,
                                style: const TextStyle(color: Colors.white)),
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

          // 📋 Staff list
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Colors.lightBlueAccent),
                  )
                : filteredStaff.isEmpty
                    ? const Center(
                        child: Text("No staff found",
                            style: TextStyle(color: Colors.white70)),
                      )
                    : ListView.builder(
                        itemCount: filteredStaff.length,
                        itemBuilder: (context, i) =>
                            _buildStaffCard(filteredStaff[i]),
                      ),
          ),
        ],
      ),
    );
  }
}
