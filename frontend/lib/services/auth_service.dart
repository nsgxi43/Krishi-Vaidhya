import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  // Keys for storing data
  static const String _isLoggedInKey = "isLoggedIn";
  static const String _userNameKey = "userName";
  static const String _userPhoneKey = "userPhone";
  static const String _userLocationKey = "userLocation";
  static const String _userCropsKey = "userCrops";

  // LOGIC: Check if user is already logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // LOGIC: Check if this phone number is a returning user (already has a name saved)
  static Future<bool> isReturningUser(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString(_userPhoneKey) ?? '';
    final savedName = prefs.getString(_userNameKey) ?? '';
    return savedPhone == phone && savedName.isNotEmpty && savedName != 'Farmer';
  }

  // LOGIC: Login (Sync with Backend) — now accepts name and crops
  static Future<bool> login(String phone, String name, List<String> crops) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Call Backend with actual user-provided name and crops
    final result = await ApiService.login(
      phone, 
      name,
      "en", 
      crops,
    );

    // Always save locally (offline-first)
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userPhoneKey, phone);
    await prefs.setString(_userNameKey, name);
    await prefs.setStringList(_userCropsKey, crops);

    if (result != null) {
      return true; // Backend sync successful
    }
    
    return false; // Backend sync failed, but local data saved
  }

  // LOGIC: Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Wipes all data
  }

  // LOGIC: Get User Profile
  static Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "name": prefs.getString(_userNameKey) ?? "Farmer",
      "phone": prefs.getString(_userPhoneKey) ?? "",
      "location": prefs.getString(_userLocationKey) ?? "India",
      "crops": prefs.getStringList(_userCropsKey) ?? [],
    };
  }

  // LOGIC: Update User Profile
  static Future<void> updateProfile(String name, String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userLocationKey, location);
  }

  // LOGIC: Update crops in local storage
  static Future<void> updateCrops(List<String> crops) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_userCropsKey, crops);
  }

  // LOGIC: Get saved crops
  static Future<List<String>> getCrops() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_userCropsKey) ?? [];
  }
}