import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Delivery/home_page.dart';
import '../../Screen/login_page.dart';
import '../../Sessions/delivery_session.dart'; // ✅ ensure this path is correct

class DeliveryProfilePage extends StatefulWidget {
  final int staffId;
  final int stationId;

  const DeliveryProfilePage({
    super.key,
    required this.staffId,
    required this.stationId,
  });

  @override
  State<DeliveryProfilePage> createState() => _DeliveryProfilePageState();
}

class _DeliveryProfilePageState extends State<DeliveryProfilePage> {
  bool isLoading = true;
  Map<String, dynamic> profile = {};

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  // ✅ Fetch profile data
  Future<void> fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:3000/api/accounts/staff/${widget.staffId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          profile = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("⚠️ Error fetching profile: $e");
    }
  }

  // ✅ Update profile
  Future<void> updateProfile(Map<String, dynamic> updatedData) async {
    try {
      final response = await http.put(
        Uri.parse("http://10.0.2.2:3000/api/accounts/staff/${widget.staffId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profile updated successfully")),
        );
        fetchProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Update failed: ${response.body}")),
        );
      }
    } catch (e) {
      print("⚠️ Error updating profile: $e");
    }
  }

  // ✅ Show update dialog
  void showUpdateDialog() {
    final firstNameController =
        TextEditingController(text: profile["first_name"] ?? "");
    final lastNameController =
        TextEditingController(text: profile["last_name"] ?? "");
    final phoneController =
        TextEditingController(text: profile["phone_number"] ?? "");
    final passwordController = TextEditingController();

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
                    "Update Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildTextField("First Name", firstNameController),
                  const SizedBox(height: 12),
                  buildTextField("Last Name", lastNameController),
                  const SizedBox(height: 12),
                  buildTextField("Phone Number", phoneController,
                      type: TextInputType.phone),
                  const SizedBox(height: 12),
                  buildTextField("New Password (optional)", passwordController,
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
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final updatedData = {
                            "first_name": firstNameController.text.trim(),
                            "last_name": lastNameController.text.trim(),
                            "phone_number": phoneController.text.trim(),
                          };
                          if (passwordController.text.isNotEmpty) {
                            updatedData["password"] =
                                passwordController.text.trim();
                          }
                          updateProfile(updatedData);
                          Navigator.pop(context);
                        },
                        child: const Text("Save",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool obscure = false, TextInputType? type}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: const Color(0xFF08315C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ✅ Logout confirmation with proper session clear
  void confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF06233E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Logout",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to log out?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await DeliverySession.clear(); // ✅ Clears memory + prefs

              // Navigate cleanly to login
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ Build info row
  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ✅ UI Layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      body: Stack(
        children: [
          // Background visuals
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF6EACDA).withOpacity(0.25),
                borderRadius: BorderRadius.circular(90),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 220,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.lightBlueAccent),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios,
                                  color: Colors.white),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomePage(
                                      stationId: widget.stationId,
                                      staffId: widget.staffId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Text(
                              "Profile",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Avatar and Info
                        CircleAvatar(
                          radius: 45,
                          backgroundColor:
                              Colors.lightBlueAccent.withOpacity(0.3),
                          child: const Icon(Icons.person,
                              size: 55, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${profile["first_name"] ?? ""} ${profile["last_name"] ?? ""}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        const Text("Delivery Worker",
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 20),

                        // Info card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF08315C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildInfoRow(
                                  "Username", profile["username"] ?? ""),
                              buildInfoRow(
                                  "Phone", profile["phone_number"] ?? "N/A"),
                              buildInfoRow(
                                  "Station", profile["station_name"] ?? ""),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Buttons
                        ElevatedButton.icon(
                          onPressed: showUpdateDialog,
                          icon:
                              const Icon(Icons.edit, color: Colors.white, size: 20),
                          label: const Text("Update Profile"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlueAccent,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: confirmLogout,
                          icon:
                              const Icon(Icons.logout, color: Colors.white, size: 20),
                          label: const Text("Logout"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
