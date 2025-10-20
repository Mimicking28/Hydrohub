import 'package:shared_preferences/shared_preferences.dart';

class DeliverySession {
  // 🔹 Basic info
  static int? deliveryId;
  static int? stationId;
  static String? deliveryName;
  static String? stationName;

  // 🔹 Optional contact details
  static String? phoneNumber;
  static String? gender;
  static String? status;

  // ✅ Check if session is valid
  static bool get isReady =>
      deliveryId != null && stationId != null && deliveryName != null;

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
    deliveryId = id;
    stationId = station;
    deliveryName = name;
    stationName = stationLabel;
    phoneNumber = phone;
    gender = genderType;
    status = currentStatus;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("delivery_id", id);
    await prefs.setInt("station_id", station);
    await prefs.setString("delivery_name", name);
    if (stationLabel != null) await prefs.setString("station_name", stationLabel);
    if (phone != null) await prefs.setString("phone_number", phone);
    if (genderType != null) await prefs.setString("gender", genderType);
    if (currentStatus != null) await prefs.setString("status", currentStatus);
  }

  // ✅ Load session data (used at startup or splash)
  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    deliveryId = prefs.getInt("delivery_id");
    stationId = prefs.getInt("station_id");
    deliveryName = prefs.getString("delivery_name");
    stationName = prefs.getString("station_name");
    phoneNumber = prefs.getString("phone_number");
    gender = prefs.getString("gender");
    status = prefs.getString("status");

    return isReady;
  }

  // ✅ Clear session data (logout)
  static Future<void> clear() async {
    deliveryId = null;
    stationId = null;
    deliveryName = null;
    stationName = null;
    phoneNumber = null;
    gender = null;
    status = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // clears saved delivery data
  }

  // ✅ Getter aliases (optional, for easy access)
  static int? get staffId => deliveryId;
  static int? get station => stationId;

  // ✅ Debug output
  static Map<String, dynamic> toJson() {
    return {
      "delivery_id": deliveryId,
      "station_id": stationId,
      "delivery_name": deliveryName,
      "station_name": stationName,
      "phone_number": phoneNumber,
      "gender": gender,
      "status": status,
    };
  }
}
