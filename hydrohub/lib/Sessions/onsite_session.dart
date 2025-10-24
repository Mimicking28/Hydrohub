import 'package:shared_preferences/shared_preferences.dart';

class OnsiteSession {
  static int? staffId;
  static int? stationId;
  static String? onsiteName;
  static String? stationName;
  static String? phoneNumber;
  static String? gender;
  static String? status;

  static bool get isReady =>
      staffId != null && stationId != null && onsiteName != null;

  static Future<void> setSession({
    required int id,
    required int station,
    required String name,
    String? stationLabel,
    String? phone,
    String? genderType,
    String? currentStatus,
  }) async {
    staffId = id;
    stationId = station;
    onsiteName = name;
    stationName = stationLabel;
    phoneNumber = phone;
    gender = genderType;
    status = currentStatus;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("staff_id", id);
    await prefs.setInt("station_id", station);
    await prefs.setString("onsite_name", name);
    if (stationLabel != null) await prefs.setString("station_name", stationLabel);
    if (phone != null) await prefs.setString("phone_number", phone);
    if (genderType != null) await prefs.setString("gender", genderType);
    if (currentStatus != null) await prefs.setString("status", currentStatus);
  }

  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    staffId = prefs.getInt("staff_id");
    stationId = prefs.getInt("station_id");
    onsiteName = prefs.getString("onsite_name");
    stationName = prefs.getString("station_name");
    phoneNumber = prefs.getString("phone_number");
    gender = prefs.getString("gender");
    status = prefs.getString("status");
    return isReady;
  }

  static Future<void> clear() async {
    staffId = null;
    stationId = null;
    onsiteName = null;
    stationName = null;
    phoneNumber = null;
    gender = null;
    status = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Map<String, dynamic> toJson() {
    return {
      "staff_id": staffId,
      "station_id": stationId,
      "onsite_name": onsiteName,
      "station_name": stationName,
      "phone_number": phoneNumber,
      "gender": gender,
      "status": status,
    };
  }
}
