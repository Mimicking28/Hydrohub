import 'package:shared_preferences/shared_preferences.dart';

class OnsiteSession {
  // 🔹 Basic user info
  static int? onsiteId;
  static int? stationId;
  static String? onsiteName;
  static String? stationName;

  // 🔹 Optional contact details
  static String? phoneNumber;
  static String? gender;
  static String? status;

  // ✅ Check if session is valid
  static bool get isReady =>
      onsiteId != null && stationId != null && onsiteName != null;

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
    onsiteId = id;
    stationId = station;
    onsiteName = name;
    stationName = stationLabel;
    phoneNumber = phone;
    gender = genderType;
    status = currentStatus;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("onsite_id", id);
    await prefs.setInt("station_id", station);
    await prefs.setString("onsite_name", name);
    if (stationLabel != null) await prefs.setString("station_name", stationLabel);
    if (phone != null) await prefs.setString("phone_number", phone);
    if (genderType != null) await prefs.setString("gender", genderType);
    if (currentStatus != null) await prefs.setString("status", currentStatus);
  }

  // ✅ Load session data (used in splash or app start)
  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    onsiteId = prefs.getInt("onsite_id");
    stationId = prefs.getInt("station_id");
    onsiteName = prefs.getString("onsite_name");
    stationName = prefs.getString("station_name");
    phoneNumber = prefs.getString("phone_number");
    gender = prefs.getString("gender");
    status = prefs.getString("status");

    return isReady;
  }

  // ✅ Clear session data completely (logout)
  static Future<void> clear() async {
    onsiteId = null;
    stationId = null;
    onsiteName = null;
    stationName = null;
    phoneNumber = null;
    gender = null;
    status = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ✅ Getter aliases (for easy use)
  static int? get staffId => onsiteId;
  static int? get station => stationId;

  // ✅ Debug or logging
  static Map<String, dynamic> toJson() {
    return {
      "onsite_id": onsiteId,
      "station_id": stationId,
      "onsite_name": onsiteName,
      "station_name": stationName,
      "phone_number": phoneNumber,
      "gender": gender,
      "status": status,
    };
  }
}
