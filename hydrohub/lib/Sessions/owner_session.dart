import 'package:shared_preferences/shared_preferences.dart';

class OwnerSession {
  // 🔹 Basic user info
  static int? ownerId;
  static int? stationId;
  static String? ownerName;
  static String? stationName;

  // 🔹 Optional contact details
  static String? phoneNumber;
  static String? gender;
  static String? status;

  // ✅ Check if session is valid
  static bool get isReady =>
      ownerId != null && stationId != null && ownerName != null;

  // ✅ Save session after login
  static Future<void> setSession({
    required int id,
    required int station,
    required String name,
    String? stationLabel,
    String? phone,
    String? genderType,
    String? currentStatus,
  }) async {
    ownerId = id;
    stationId = station;
    ownerName = name;
    stationName = stationLabel;
    phoneNumber = phone;
    gender = genderType;
    status = currentStatus;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("owner_id", id);
    await prefs.setInt("station_id", station);
    await prefs.setString("owner_name", name);
    if (stationLabel != null) await prefs.setString("station_name", stationLabel);
    if (phone != null) await prefs.setString("phone_number", phone);
    if (genderType != null) await prefs.setString("gender", genderType);
    if (currentStatus != null) await prefs.setString("status", currentStatus);
  }

  // ✅ Load session data (used in splash screen or startup)
  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    ownerId = prefs.getInt("owner_id");
    stationId = prefs.getInt("station_id");
    ownerName = prefs.getString("owner_name");
    stationName = prefs.getString("station_name");
    phoneNumber = prefs.getString("phone_number");
    gender = prefs.getString("gender");
    status = prefs.getString("status");

    return isReady;
  }

  // ✅ Clear session completely (logout)
  static Future<void> clear() async {
    ownerId = null;
    stationId = null;
    ownerName = null;
    stationName = null;
    phoneNumber = null;
    gender = null;
    status = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ✅ Getters (optional aliases)
  static int? get id => ownerId;
  static int? get station => stationId;

  // ✅ Convert to JSON (for debugging or logging)
  static Map<String, dynamic> toJson() {
    return {
      "owner_id": ownerId,
      "station_id": stationId,
      "owner_name": ownerName,
      "station_name": stationName,
      "phone_number": phoneNumber,
      "gender": gender,
      "status": status,
    };
  }
}
