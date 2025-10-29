// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ConfirmOrderPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final int stationId;
  final String stationName;
  final String openingTime;
  final String closingTime;
  final List<String> workingDays;

  const ConfirmOrderPage({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.stationId,
    required this.stationName,
    required this.openingTime,
    required this.closingTime,
    required this.workingDays,
  });

  @override
  State<ConfirmOrderPage> createState() => _ConfirmOrderPageState();
}

class _ConfirmOrderPageState extends State<ConfirmOrderPage> {
  String? _deliveryType; // "today" or "preorder"
  DateTime? _selectedDate;
  String? _validationMessage;
  bool _isSubmitting = false;

  DateTime _parseClosingTime(String timeStr) {
    final parts = timeStr.split(":");
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final nextYear = DateTime(now.year + 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: nextYear,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6EACDA),
              onPrimary: Colors.white,
              surface: Color(0xFF0E1117),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final dayName = DateFormat('EEEE').format(picked);
      if (!widget.workingDays.contains(dayName)) {
        setState(() {
          _validationMessage =
              "Selected date ($dayName) is outside the station’s working days.";
          _selectedDate = null;
        });
        return;
      }
      setState(() {
        _selectedDate = picked;
        _validationMessage = null;
      });
    }
  }

  Future<void> _validateAndProceed() async {
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);

    if (_deliveryType == null) {
      setState(() => _validationMessage = "Please select a delivery type.");
      return;
    }

    if (_deliveryType == "today") {
      if (!widget.workingDays.contains(dayName)) {
        setState(() => _validationMessage =
            "The station is closed today. Please choose Pre-Order instead.");
        return;
      }

      final closing = _parseClosingTime(widget.closingTime);
      if (now.isAfter(closing.subtract(const Duration(hours: 1)))) {
        setState(() => _validationMessage =
            "On-the-day delivery is only available up to 1 hour before closing time.");
        return;
      }
    } else if (_deliveryType == "preorder") {
      if (_selectedDate == null) {
        setState(() => _validationMessage = "Please select a delivery date.");
        return;
      }
    }

    setState(() {
      _validationMessage = null;
      _isSubmitting = true;
    });

    try {
      final res = await http.post(
        Uri.parse("http://10.0.2.2:3000/api/orders"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "station_id": widget.stationId,
          "cart_items": widget.cartItems,
          "subtotal": widget.subtotal,
          "delivery_type": _deliveryType,
          "delivery_date": _selectedDate?.toIso8601String(),
        }),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF6EACDA),
            content: Text(
              "✅ Order placed successfully! Waiting for confirmation.",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() => _validationMessage = "Failed to place order.");
      }
    } catch (e) {
      setState(() => _validationMessage = "Error placing order: $e");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6EACDA);
    const bg = Color(0xFF021526);
    const card = Color(0xFF0E1117);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 1,
        title: const Text(
          "Confirm Order",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.store, color: primary, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.stationName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Delivery type
            const Text(
              "Choose Delivery Type",
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                RadioListTile<String>(
                  tileColor: card,
                  activeColor: primary,
                  value: "today",
                  groupValue: _deliveryType,
                  onChanged: (v) => setState(() => _deliveryType = v),
                  title: const Text("On-the-Day Delivery",
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                    "Available until 1 hour before closing time",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  tileColor: card,
                  activeColor: primary,
                  value: "preorder",
                  groupValue: _deliveryType,
                  onChanged: (v) => setState(() => _deliveryType = v),
                  title: const Text("Pre-Order Delivery",
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                    "Choose a future date within working days",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                if (_deliveryType == "preorder")
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
                      onPressed: _selectDate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_today, color: Colors.white),
                      label: Text(
                        _selectedDate == null
                            ? "Select Delivery Date"
                            : DateFormat('MMMM d, y').format(_selectedDate!),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Order Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Order Summary",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.white24),
                  ...widget.cartItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(item['name'],
                                  style: const TextStyle(color: Colors.white70)),
                            ),
                            Text(
                              "₱${item['price']} × ${item['qty']}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      )),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Subtotal:",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("₱${widget.subtotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Note section
            const Text(
              "⚠️ Note:",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Customers must have adequate containers ready for exchange during delivery. "
              "Failure to provide containers may result in delivery refusal.",
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),

            if (_validationMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _validationMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _validateAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        "Confirm Order",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
