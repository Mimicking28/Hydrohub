import 'package:shared_preferences/shared_preferences.dart';

class AdminSession {
  // 🔹 Basic admin info
  static int? adminId;
  static String? adminName;

  // 🔹 Optional contact and account info
  static String? gender;
  static String? phoneNumber;
  static String? username;

  // ✅ Check if session is valid
  static bool get isReady => adminId != null && adminName != null;

  // ✅ Save session after login
  static Future<void> setSession({
    required int id,
    required String name,
    String? genderType,
    String? phone,
    String? user,
  }) async {
    adminId = id;
    adminName = name;
    gender = genderType;
    phoneNumber = phone;
    username = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("admin_id", id);
    await prefs.setString("admin_name", name);
    if (genderType != null) await prefs.setString("gender", genderType);
    if (phone != null) await prefs.setString("phone_number", phone);
    if (user != null) await prefs.setString("username", user);
  }

  // ✅ Load session (e.g., on splash or startup)
  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    adminId = prefs.getInt("admin_id");
    adminName = prefs.getString("admin_name");
    gender = prefs.getString("gender");
    phoneNumber = prefs.getString("phone_number");
    username = prefs.getString("username");

    return isReady;
  }

  // ✅ Clear session (logout)
  static Future<void> clear() async {
    adminId = null;
    adminName = null;
    gender = null;
    phoneNumber = null;
    username = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ✅ Convert to JSON (for debugging/logging)
  static Map<String, dynamic> toJson() {
    return {
      "admin_id": adminId,
      "admin_name": adminName,
      "gender": gender,
      "phone_number": phoneNumber,
      "username": username,
    };
  }
}
