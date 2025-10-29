// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';

class CustomerSignUpPage extends StatefulWidget {
  const CustomerSignUpPage({super.key});

  @override
  State<CustomerSignUpPage> createState() => _CustomerSignUpPageState();
}

class _CustomerSignUpPageState extends State<CustomerSignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  // =====================================================
  // 🧾 REGISTER CUSTOMER ACCOUNT
  // =====================================================
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("http://10.0.2.2:3000/api/accounts/customer/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "first_name": _firstName.text.trim(),
          "last_name": _lastName.text.trim(),
          "email": _email.text.trim(),
          "phone_number": _phone.text.trim(),
          "password": _password.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["error"] ?? "Failed to register"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =====================================================
  // 🎨 BUILD UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF021526);
    const primary = Color(0xFF6EACDA);
    const field = Color(0xFF1B263B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text("Create Account",
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ---------------- HEADER ----------------
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary.withOpacity(0.3), field],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: "Hydro",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: "Hub",
                            style: TextStyle(
                              color: primary,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Join our community and order water refills with ease!",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ---------------- FORM FIELDS ----------------
              _input("First Name", Icons.person_outline, _firstName, field),
              const SizedBox(height: 14),
              _input("Last Name", Icons.person_outline, _lastName, field),
              const SizedBox(height: 14),
              _input("Email", Icons.email_outlined, _email, field, validator: (v) {
                if (v == null || v.isEmpty) return "Enter email";
                if (!v.contains("@")) return "Enter a valid email address";
                return null;
              }),
              const SizedBox(height: 14),
              _input("Phone Number", Icons.phone_outlined, _phone, field,
                  validator: (v) {
                if (v == null || v.isEmpty) return "Enter phone number";
                if (!RegExp(r'^[0-9+\- ]+$').hasMatch(v)) return "Invalid number";
                return null;
              }),
              const SizedBox(height: 14),
              _passwordInput("Password", _password, _obscure, () {
                setState(() => _obscure = !_obscure);
              }, field),
              const SizedBox(height: 14),
              _passwordInput("Confirm Password", _confirmPassword, _obscureConfirm, () {
                setState(() => _obscureConfirm = !_obscureConfirm);
              }, field),
              const SizedBox(height: 26),

              // ---------------- BUTTON ----------------
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),

              // ---------------- FOOTER ----------------
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text(
                  "Already have an account? Sign In",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // 🔹 FORM INPUT WIDGETS
  // =====================================================
  Widget _input(String label, IconData icon, TextEditingController ctrl, Color field,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      validator: validator ?? (v) => (v == null || v.isEmpty) ? "Enter $label" : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: field,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6EACDA), width: 1.3),
        ),
      ),
    );
  }

  Widget _passwordInput(
      String label, TextEditingController ctrl, bool obscure, VoidCallback toggle, Color field) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      validator: (v) => (v == null || v.isEmpty) ? "Enter $label" : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70),
        ),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: field,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6EACDA), width: 1.3),
        ),
      ),
    );
  }
}
