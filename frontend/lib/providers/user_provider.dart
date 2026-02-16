import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  // Default Data
  String _name = "Farmer";
  String _phone = "";
  String _location = "India";

  // Getters (To read data)
  String get name => _name;
  String get phone => _phone;
  String get location => _location;
  
  UserProvider() {
    loadUserData();
  }

  Future<void> loadUserData() async {
    final profile = await AuthService.getProfile();
    _name = profile['name'] ?? "Farmer";
    _phone = profile['phone'] ?? "";
    _location = profile['location'] ?? "India";
    notifyListeners();
  }

  // Function to Update Data
  void updateProfile(String newName, String newPhone, String newLocation) {
    _name = newName;
    _phone = newPhone;
    _location = newLocation;
    
    // Sync with local storage (and ideally backend)
    AuthService.updateProfile(newName, newLocation);
    
    notifyListeners(); 
  }
}