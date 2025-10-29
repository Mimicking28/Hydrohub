import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AccountList extends StatefulWidget {
  const AccountList({super.key});

  @override
  State<AccountList> createState() => _AccountListState();
}

class _AccountListState extends State<AccountList> {
  List<dynamic> allAccounts = [];
  List<dynamic> filteredAccounts = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedRole = 'All';

  @override
  void initState() {
    super.initState();
    fetchAccounts();
  }

  // ✅ Fetch all accounts from backend
  Future<void> fetchAccounts() async {
    const String apiUrl = "http://10.0.2.2:3000/api/accounts/all";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          allAccounts = data;
          filteredAccounts = data;
          isLoading = false;
        });
      } else {
        throw Exception("Server responded ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showPopup("❌ Failed to fetch accounts: $e");
    }
  }

  // ✅ Apply search + role filters
  void _filterAccounts() {
    setState(() {
      filteredAccounts = allAccounts.where((account) {
        final name =
            "${account['first_name']} ${account['last_name']}".toLowerCase();
        final username = account['username']?.toLowerCase() ?? '';
        final role = account['role']?.toString().toLowerCase() ?? '';
        final type = account['type']?.toString().toLowerCase() ?? '';

        final matchesSearch = name.contains(searchQuery.toLowerCase()) ||
            username.contains(searchQuery.toLowerCase());

        bool matchesRole = true;
        if (selectedRole != 'All') {
          final filter = selectedRole.toLowerCase();
          if (filter == 'onsite' || filter == 'delivery') {
            matchesRole = type == filter;
          } else {
            matchesRole = role == filter;
          }
        }

        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  // ✅ Popup alert
  void _showPopup(String message, {bool success = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: success ? Colors.green[100] : Colors.red[100],
        title: Text(
          success ? 'Success' : 'Error',
          style: TextStyle(
            color: success ? Colors.green[900] : Colors.red[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  // ✅ Account details dialog
  void _showDetailsDialog(dynamic account) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF021526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "${account['first_name']} ${account['last_name']}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow("Role", account['role']),
            if (account['type'] != null)
              _buildDetailRow("Type", account['type']),
            _buildDetailRow("Gender", account['gender']),
            _buildDetailRow("Phone", account['phone_number']),
            _buildDetailRow("Username", account['username']),
            if (account['station_name'] != null)
              _buildDetailRow("Station", account['station_name']),
            if (account['status'] != null)
              _buildDetailRow("Status", account['status']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.lightBlueAccent)),
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "N/A",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Main UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "All Accounts",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search + Filter Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        searchQuery = value;
                        _filterAccounts();
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search by name or username...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF1B263B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.lightBlueAccent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    dropdownColor: const Color(0xFF1B263B),
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(
                        value: 'All',
                        child: Text('All', style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: 'Administrator',
                        child: Text('Administrator',
                            style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: 'Owner',
                        child: Text('Owner',
                            style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: 'Onsite',
                        child: Text('Onsite Staff',
                            style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: 'Delivery',
                        child: Text('Delivery Staff',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => selectedRole = value!);
                      _filterAccounts();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // List of Accounts
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredAccounts.isEmpty
                        ? const Center(
                            child: Text(
                              "No matching accounts found.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredAccounts.length,
                            itemBuilder: (context, index) {
                              final acc = filteredAccounts[index];
                              return Card(
                                color: const Color(0xFF4D6CA5),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                                child: ListTile(
                                  title: Text(
                                    "${acc['first_name']} ${acc['last_name']}",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "${acc['role']} ${acc['type'] != null ? "(${acc['type']})" : ""}",
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => _showDetailsDialog(acc),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Color.fromARGB(255, 255, 255, 255),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text("View Details"),
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
