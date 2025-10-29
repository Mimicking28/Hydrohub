import 'package:shared_preferences/shared_preferences.dart';

class CustomerSession {
  static int? customerId;
  static String? name;
  static String? email;
  static String? phone;

  // ✅ Compatibility method for older login_page.dart
  static Future<void> setSession({
    required int id,
    required String name,
    required String email,
    required String phone,
  }) async {
    await saveSession(
      id: id,
      fullName: name,
      emailAddress: email,
      phoneNumber: phone,
    );
  }

  static Future<void> saveSession({
    required int id,
    required String fullName,
    required String emailAddress,
    required String phoneNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('customer_id', id);
    await prefs.setString('name', fullName);
    await prefs.setString('email', emailAddress);
    await prefs.setString('phone', phoneNumber);

    customerId = id;
    name = fullName;
    email = emailAddress;
    phone = phoneNumber;
  }

  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    customerId = prefs.getInt('customer_id');
    name = prefs.getString('name');
    email = prefs.getString('email');
    phone = prefs.getString('phone');
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('customer_id');
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('phone');

    customerId = null;
    name = null;
    email = null;
    phone = null;
  }

  static bool get isLoggedIn => customerId != null;
}
