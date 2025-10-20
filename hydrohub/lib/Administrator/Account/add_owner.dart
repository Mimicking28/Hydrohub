import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class AddOwnerAccountPage extends StatefulWidget {
  const AddOwnerAccountPage({super.key});

  @override
  State<AddOwnerAccountPage> createState() => _AddOwnerAccountPageState();
}

class _AddOwnerAccountPageState extends State<AddOwnerAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _stationController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  static int ownerCount = 0;
  String generatedUsername = "";
  String generatedPassword = "";
  String? selectedGender;

  // ✅ Random password generator
  String generateRandomPassword(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // ✅ Generate username based on last name + number
  void generateCredentials() {
    ownerCount++;
    final last = _lastNameController.text.trim().toLowerCase();
    generatedUsername = "$last${ownerCount.toString().padLeft(6, '0')}";
    generatedPassword = generateRandomPassword(10);
  }

  // ✅ Save to backend
  Future<void> saveToDatabase() async {
    final url = Uri.parse("http://10.0.2.2:3000/api/accounts/owner");
    final body = {
      "station_name": _stationController.text.trim(),
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "gender": selectedGender!,
      "phone_number": _phoneController.text.trim(),
      "password": generatedPassword,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data["success"] == true) {
        setState(() => generatedUsername = data["username"]);
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.red,
              content: Text(data["error"] ?? "Failed to save owner")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text("Error connecting to server: $e")),
      );
    }
  }

  void _confirmAddOwner() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select gender")),
      );
      return;
    }

    generateCredentials();
    await saveToDatabase();
  }

  // ✅ Success dialog with Copy Credentials feature
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF021526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "✅ Owner Account Created",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Station: ${_stationController.text}",
                style: const TextStyle(color: Colors.white)),
            Text("Owner: ${_firstNameController.text} ${_lastNameController.text}",
                style: const TextStyle(color: Colors.white)),
            Text("Gender: $selectedGender",
                style: const TextStyle(color: Colors.white)),
            Text("Phone: ${_phoneController.text}",
                style: const TextStyle(color: Colors.white)),
            const Divider(color: Colors.white24),
            Text("Username: $generatedUsername",
                style: const TextStyle(color: Colors.lightBlueAccent)),
            Text("Password: $generatedPassword",
                style: const TextStyle(color: Colors.orangeAccent)),
            const SizedBox(height: 10),

            // 📋 Copy Credentials Button
            TextButton.icon(
              icon: const Icon(Icons.copy, color: Colors.lightBlueAccent),
              label: const Text("Copy Credentials",
                  style: TextStyle(color: Colors.lightBlueAccent)),
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text:
                      "Username: $generatedUsername\nPassword: $generatedPassword",
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Copied to clipboard")),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text("OK", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _stationController.clear();
      _firstNameController.clear();
      _lastNameController.clear();
      _phoneController.clear();
      selectedGender = null;
      generatedUsername = "";
      generatedPassword = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "HydroHub",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                const Text(
                  "Add Owner Account",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 25),

                _buildTextField("Water Refilling Station Name", _stationController),
                const SizedBox(height: 20),
                _buildTextField("Owner First Name", _firstNameController),
                const SizedBox(height: 20),
                _buildTextField("Owner Last Name", _lastNameController),
                const SizedBox(height: 20),
                _buildGenderDropdown(),
                const SizedBox(height: 20),
                _buildPhoneField(),
                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                      ),
                      onPressed: _confirmAddOwner,
                      child: const Text("Add Owner",
                          style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Helpers ----
  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1B263B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF6EACDA), width: 1),
        ),
      ),
      validator: (v) => v!.isEmpty ? "Please enter $label" : null,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      dropdownColor: const Color(0xFF1B263B),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Gender",
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1B263B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF6EACDA), width: 1),
        ),
      ),
      items: const [
        DropdownMenuItem(value: "Male", child: Text("Male")),
        DropdownMenuItem(value: "Female", child: Text("Female")),
      ],
      onChanged: (value) => setState(() => selectedGender = value),
      validator: (v) => v == null ? "Please select gender" : null,
    );
  }

  // ✅ Phone field with auto 11-digit enforcement
  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Phone Number (11 digits)",
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1B263B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF6EACDA), width: 1),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Please enter phone number";
        if (v.length != 11) return "Phone number must be exactly 11 digits";
        if (!v.startsWith('09')) return "Phone number must start with 09";
        return null;
      },
    );
  }
}
