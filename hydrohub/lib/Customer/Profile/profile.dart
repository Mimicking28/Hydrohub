// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrohub/Customer/Profile/address.dart';
import 'package:hydrohub/Customer/home_page.dart';
import 'package:hydrohub/Screen/login_page.dart';
import 'package:hydrohub/Sessions/customer_session.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  bool _isLoading = true;
  int _selectedIndex = 3;
  String? name, email, phone;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    try {
      name = CustomerSession.name ?? '';
      email = CustomerSession.email ?? '';
      phone = CustomerSession.phone ?? '';
    } catch (e) {
      debugPrint("❌ Error loading customer data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------- Bottom navigation ----------
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CustomerHomePage()),
      );
    } else if (index == 1 || index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("This feature will be available soon."),
        duration: Duration(seconds: 1),
      ));
    }
  }

  // ---------- Show Update Profile modal ----------
  void _showProfileModal() {
    const bg = Color(0xFF021526);
    const primary = Color(0xFF6EACDA);

    final nameController = TextEditingController(text: name ?? '');
    final emailController = TextEditingController(text: email ?? '');
    final phoneController = TextEditingController(text: phone ?? '');
    final passwordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Update Profile",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // ✅ Full Name
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "Full Name",
                      labelStyle: TextStyle(color: Colors.white70)),
                ),

                // ✅ Email Address
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "Email Address",
                      labelStyle: TextStyle(color: Colors.white70)),
                ),

                // ✅ Phone Number
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "Phone Number",
                      labelStyle: TextStyle(color: Colors.white70)),
                ),

                // ✅ Optional Password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "New Password (optional)",
                      labelStyle: TextStyle(color: Colors.white70)),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.white70))),
                    ElevatedButton(
                      onPressed: () async {
                        await _updateCustomer(
                          nameController.text.trim(),
                          emailController.text.trim(),
                          phoneController.text.trim(),
                          passwordController.text.trim().isEmpty
                              ? null
                              : passwordController.text.trim(),
                        );
                        Navigator.pop(context);
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: primary),
                      child: const Text("Save",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Update backend ----------
  Future<void> _updateCustomer(
      String newName, String newEmail, String newPhone, String? newPassword) async {
    try {
      final res = await http.put(
        Uri.parse(
            "http://10.0.2.2:3000/api/customers/${CustomerSession.customerId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "first_name": newName.split(" ").first,
          "last_name": newName.split(" ").skip(1).join(" "),
          "email": newEmail,
          "phone_number": newPhone,
          "password": newPassword,
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["success"] == true) {
        setState(() {
          name = newName;
          email = newEmail;
          phone = newPhone;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("✅ Profile updated successfully")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(data["error"] ?? "Failed to update profile information.")));
      }
    } catch (e) {
      debugPrint("❌ Error updating customer: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Server error. Try again later.")));
    }
  }

  // ---------- Logout ----------
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_data');

    await CustomerSession.clearSession();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6EACDA);
    const bg = Color(0xFF021526);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor:  const Color(0xFF021526),
        elevation: 0,
        centerTitle: true,
        title: const Text("Account",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧍 Profile Header Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1117),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: primary.withOpacity(0.25),
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 38),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name ?? "Customer",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(email ?? "",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        Text(phone ?? "",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showProfileModal,
                          child: const Text("View profile",
                              style: TextStyle(
                                  color: Colors.lightBlueAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 📦 Quick Access Buttons (Orders + Addresses)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1117),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _quickButton(Icons.receipt_long_rounded, "Orders", () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Orders page coming soon!"),
                      duration: Duration(seconds: 1),
                    ));
                  }),
                  _quickButton(Icons.location_on_rounded, "Addresses", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CustomerAddressPage()),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🚪 Logout Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),

      // 🔽 Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
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

  // ---------- Reusable Quick Button ----------
  Widget _quickButton(IconData icon, String label, VoidCallback onTap) {
    const primary = Color(0xFF6EACDA);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: primary.withOpacity(0.15),
            radius: 26,
            child: Icon(icon, color: primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
