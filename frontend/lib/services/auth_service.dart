import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  // Keys for storing data
  static const String _isLoggedInKey = "isLoggedIn";
  static const String _userNameKey = "userName";
  static const String _userPhoneKey = "userPhone";
  static const String _userLocationKey = "userLocation";

  // LOGIC: Check if user is already logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // LOGIC: Login (Sync with Backend)
  static Future<bool> login(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Call Backend
    final result = await ApiService.login(
      phone, 
      "Farmer", // Logic to get name from UI if needed
      "en", 
      []
    );

    if (result != null) {
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userPhoneKey, phone);
      await prefs.setString(_userNameKey, result['name'] ?? "Farmer");
      // Save other fields if needed
      return true;
    }
    
    return false; // Login failed
  }

  // LOGIC: Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Wipes all data
  }

  // LOGIC: Get User Profile
  static Future<Map<String, String>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "name": prefs.getString(_userNameKey) ?? "Farmer",
      "phone": prefs.getString(_userPhoneKey) ?? "",
      "location": prefs.getString(_userLocationKey) ?? "India",
    };
  }

  // LOGIC: Update User Profile
  static Future<void> updateProfile(String name, String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userLocationKey, location);
  }
}