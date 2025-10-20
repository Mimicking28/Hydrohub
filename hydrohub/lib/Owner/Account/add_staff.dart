import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddStaff extends StatefulWidget {
  final int stationId;

  const AddStaff({super.key, required this.stationId});

  @override
  State<AddStaff> createState() => _AddStaffState();
}

class _AddStaffState extends State<AddStaff> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? selectedGender;
  String? selectedType; // "Onsite" or "Delivery"

  // ✅ Save staff to backend
  Future<void> saveToDatabase() async {
    final url = Uri.parse("http://10.0.2.2:3000/api/accounts/staff");

    final body = {
      "station_id": widget.stationId.toString(),
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "gender": selectedGender,
      "phone_number": _phoneController.text.trim(),
      "type": selectedType,
      "password": "default123", // optional placeholder if backend requires
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data["success"] == true) {
        _showSuccessDialog(
          generatedUsername: data["username"],
          staffType: selectedType!,
        );
      } else {
        _showPopupMessage(data["error"] ?? "Failed to add staff");
      }
    } catch (e) {
      _showPopupMessage("❌ Server connection error: $e");
    }
  }

  // ✅ Confirmation before sending
  void _confirmAddStaff() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedGender == null) {
      _showPopupMessage("Please select gender");
      return;
    }
    if (selectedType == null) {
      _showPopupMessage("Please select staff type");
      return;
    }

    await saveToDatabase();
  }

  // ✅ Success Dialog
  void _showSuccessDialog({required String generatedUsername, required String staffType}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF021526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("✅ Staff Account Created", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Staff: ${_firstNameController.text} ${_lastNameController.text}",
                style: const TextStyle(color: Colors.white)),
            Text("Type: $staffType", style: const TextStyle(color: Colors.white)),
            const Divider(color: Colors.white24),
            Text("Username: $generatedUsername",
                style: const TextStyle(color: Colors.lightBlueAccent)),
            const Text("Password: (auto-generated)",
                style: TextStyle(color: Colors.orangeAccent)),
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

  // ✅ Popup Error
  void _showPopupMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Error",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _phoneController.clear();
      selectedGender = null;
      selectedType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("HydroHub",
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Icon(Icons.badge, color: Colors.white, size: 32),
                  ],
                ),
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    "Add Staff Account",
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 25),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _firstNameController,
                        label: "First Name",
                        validatorText: "Please enter first name",
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _lastNameController,
                        label: "Last Name",
                        validatorText: "Please enter last name",
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        dropdownColor: const Color(0xFF1B263B),
                        style: const TextStyle(color: Colors.white),
                        decoration: _dropdownDecoration("Gender"),
                        items: const [
                          DropdownMenuItem(value: "Male", child: Text("Male")),
                          DropdownMenuItem(value: "Female", child: Text("Female")),
                        ],
                        onChanged: (value) => setState(() => selectedGender = value),
                        validator: (v) => v == null ? "Please select gender" : null,
                      ),
                      const SizedBox(height: 20),

                      // ✅ Staff Type Selection
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Select Staff Type",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _typeButton("Onsite"),
                          const SizedBox(width: 12),
                          _typeButton("Delivery"),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _phoneController,
                        label: "Phone Number (11 digits)",
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Please enter phone number";
                          }
                          if (!RegExp(r'^[0-9]{11}$').hasMatch(v)) {
                            return "Phone number must be 11 digits";
                          }
                          return null;
                        },
                        validatorText: "",
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                            ),
                            onPressed: _confirmAddStaff,
                            child: const Text("Add Staff",
                                style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeButton(String label) {
    final isSelected = selectedType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6EACDA) : const Color(0xFF1B263B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF6EACDA) : Colors.white24,
              width: 1.3,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            "$label Staff",
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1B263B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6EACDA), width: 1),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String validatorText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1B263B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6EACDA), width: 1),
        ),
      ),
      validator: validator ?? (v) => (v == null || v.isEmpty) ? validatorText : null,
    );
  }
}
