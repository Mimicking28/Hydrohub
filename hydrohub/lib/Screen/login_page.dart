// ignore_for_file: unused_element

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// HydroHub pages
import 'package:hydrohub/Screen/splash_page.dart';
import 'package:hydrohub/Administrator/home_page.dart' as admin;
import 'package:hydrohub/Owner/home_page.dart' as owner;
import 'package:hydrohub/Onsite/home_page.dart' as onsite;
import 'package:hydrohub/Delivery/home_page.dart' as delivery;

// Sessions
import 'package:hydrohub/Sessions/admin_session.dart';
import 'package:hydrohub/Sessions/owner_session.dart';
import 'package:hydrohub/Sessions/onsite_session.dart';
import 'package:hydrohub/Sessions/delivery_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  String _selectedRole = "Staff";
  String? _selectedStaffType;
  bool _isLoading = false;
  bool _obscure = true;
  bool _rememberMe = false;
  bool _checkingSession = true;

  final _staffTypes = const [
    "Administrator",
    "Station Owner",
    "Onsite Worker",
    "Delivery Worker",
  ];

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  int? _asInt(dynamic v) => v is int ? v : int.tryParse('$v');
  String? _asStr(dynamic v) => v?.toString();

  Map<String, dynamic> _safeJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {"success": false, "error": "Malformed response"};
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF6EACDA),
      ),
    );
  }

  // ---------- AUTO-LOGIN ----------
  Future<void> _autoLogin() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('user_role');
    final savedData = prefs.getString('user_data');

    await Future.delayed(const Duration(milliseconds: 600));

    if (savedRole != null && savedData != null) {
      final Map<String, dynamic> userData = jsonDecode(savedData);
      switch (savedRole) {
        case "admin":
          AdminSession.setSession(
            id: userData["admin_id"],
            name: "${userData["first_name"]} ${userData["last_name"]}",
            genderType: userData["gender"],
            phone: userData["phone_number"],
            user: userData["username"],
          );
          _navigateToHome("admin");
          return;
        case "owner":
          OwnerSession.setSession(
            id: userData["owner_id"],
            station: userData["station_id"],
            name: "${userData["first_name"]} ${userData["last_name"]}",
            stationLabel: "Station ${userData["station_id"]}",
          );
          _navigateToHome("owner");
          return;
        case "onsite":
          OnsiteSession.setSession(
            id: userData["staff_id"],
            station: userData["station_id"],
            name: "${userData["first_name"]} ${userData["last_name"]}",
            stationLabel: "Station ${userData["station_id"]}",
            phone: userData["phone_number"],
            genderType: userData["gender"],
            currentStatus: userData["status"],
          );
          _navigateToHome("onsite");
          return;
        case "delivery":
          DeliverySession.setSession(
            id: userData["staff_id"],
            station: userData["station_id"],
            name: "${userData["first_name"]} ${userData["last_name"]}",
            stationLabel: "Station ${userData["station_id"]}",
            phone: userData["phone_number"],
            genderType: userData["gender"],
            currentStatus: userData["status"],
          );
          _navigateToHome("delivery");
          return;
      }
    }

    setState(() => _checkingSession = false);
  }

  // ---------- LOGIN FLOW ----------
  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("http://10.0.2.2:3000/api/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _username.text.trim(),
          "password": _password.text.trim(),
        }),
      );

      final data = _safeJson(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        final prefs = await SharedPreferences.getInstance();

        if (data.containsKey("admin")) {
          final user = data["admin"];
          if (_rememberMe) {
            await prefs.setString("user_role", "admin");
            await prefs.setString("user_data", jsonEncode(user));
          }
          AdminSession.setSession(
            id: user["admin_id"],
            name: "${user["first_name"]} ${user["last_name"]}",
            genderType: user["gender"],
            phone: user["phone_number"],
            user: user["username"],
          );
          _navigateToHome("admin");
        } else if (data.containsKey("owner")) {
          final user = data["owner"];
          if (_rememberMe) {
            await prefs.setString("user_role", "owner");
            await prefs.setString("user_data", jsonEncode(user));
          }
          OwnerSession.setSession(
            id: user["owner_id"],
            station: user["station_id"],
            name: "${user["first_name"]} ${user["last_name"]}",
            stationLabel: "Station ${user["station_id"]}",
          );
          _navigateToHome("owner");
        } else if (data.containsKey("staff")) {
          final user = data["staff"];
          final type = user["type"].toString().toLowerCase();

          if (_rememberMe) {
            await prefs.setString("user_role", type);
            await prefs.setString("user_data", jsonEncode(user));
          }

          if (type == "onsite") {
            OnsiteSession.setSession(
              id: user["staff_id"],
              station: user["station_id"],
              name: "${user["first_name"]} ${user["last_name"]}",
              stationLabel: "Station ${user["station_id"]}",
              phone: user["phone_number"],
              genderType: user["gender"],
              currentStatus: user["status"],
            );
            _navigateToHome("onsite");
          } else if (type == "delivery") {
            DeliverySession.setSession(
              id: user["staff_id"],
              station: user["station_id"],
              name: "${user["first_name"]} ${user["last_name"]}",
              stationLabel: "Station ${user["station_id"]}",
              phone: user["phone_number"],
              genderType: user["gender"],
              currentStatus: user["status"],
            );
            _navigateToHome("delivery");
          }
        }
      } else {
        _toast(data["error"] ?? "Invalid credentials.", isError: true);
      }
    } catch (e) {
      _toast("Network error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------- NAVIGATION ----------
  void _navigateToHome(String type) {
    Widget next;
    switch (type) {
      case "admin":
        next = admin.HomePage();
        break;
      case "owner":
        next = owner.HomePage(stationId: OwnerSession.stationId!, ownerId: OwnerSession.ownerId!);
        break;
      case "onsite":
        next = onsite.HomePage(
          stationId: OnsiteSession.stationId!,
          staffId: OnsiteSession.staffId!,
        );
        break;
      case "delivery":
        next = delivery.HomePage(
          stationId: DeliverySession.stationId!,
          staffId: DeliverySession.staffId!,
        );
        break;
      default:
        next = const SplashScreen();
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          ),
          pageBuilder: (_, __, ___) => next,
        ),
      );
    });
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF6EACDA);
    final bg = const Color(0xFF021526);

    if (_checkingSession) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF6EACDA)),
              const SizedBox(height: 20),
              Text("Checking session...",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return _loginForm(primary, bg);
  }

  Widget _loginForm(Color primary, Color bg) {
    final card = const Color(0xFF0E1117);
    final field = const Color(0xFF1B263B);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bg,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(primary, field),
                  const SizedBox(height: 28),
                  _form(card, field, primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(Color primary, Color field) => Stack(
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 140,
              height: 120,
              decoration: BoxDecoration(
                color: primary.withOpacity(.22),
                borderRadius: BorderRadius.circular(80),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withOpacity(.3), field],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primary.withOpacity(.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: 'Hydro',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: 'Hub',
                        style: TextStyle(
                          color: primary,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Sign in to manage your station and team",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _form(Color card, Color field, Color primary) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: card.withOpacity(.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.06)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _roleSelector(field, primary),
              const SizedBox(height: 14),
              _textField("Username", Icons.person_outline, _username, field, primary),
              const SizedBox(height: 14),
              _passwordField(field, primary),
              if (_selectedRole == "Staff") ...[
                const SizedBox(height: 14),
                _staffDropdown(field, primary),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: primary,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  ),
                  const Text("Remember Me", style: TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 16),
              _signInButton(primary),
            ],
          ),
        ),
      );

  Widget _roleSelector(Color field, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(.35)),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _RoleChip(
              label: "Customer",
              selected: _selectedRole == "Customer",
              onTap: () => setState(() {
                _selectedRole = "Customer";
                _selectedStaffType = null;
              }),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _RoleChip(
              label: "Staff",
              selected: _selectedRole == "Staff",
              onTap: () => setState(() {
                _selectedRole = "Staff";
                _selectedStaffType = null;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _staffDropdown(Color field, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(.35)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStaffType,
          hint: const Text("Select Staff Type", style: TextStyle(color: Colors.white70)),
          dropdownColor: field,
          iconEnabledColor: Colors.white70,
          style: const TextStyle(color: Colors.white),
          items: _staffTypes
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _selectedStaffType = v),
        ),
      ),
    );
  }

  Widget _textField(String label, IconData icon, TextEditingController controller,
          Color field, Color primary) =>
      TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: _fieldDecoration(label, icon, field, primary),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? "Please enter $label" : null,
      );

  Widget _passwordField(Color field, Color primary) => TextFormField(
        controller: _password,
        obscureText: _obscure,
        style: const TextStyle(color: Colors.white),
        decoration:
            _fieldDecoration("Password", Icons.lock_outline, field, primary).copyWith(
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
            ),
          ),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Please enter password" : null,
      );

  Widget _signInButton(Color primary) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isLoading ? null : _login,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Sign In",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      );

  InputDecoration _fieldDecoration(
      String label, IconData icon, Color field, Color primary) {
    return InputDecoration(
      filled: true,
      fillColor: field,
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary.withOpacity(.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 1.4),
      ),
    );
  }
}

// ✅ Role chip widget
class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF6EACDA);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
