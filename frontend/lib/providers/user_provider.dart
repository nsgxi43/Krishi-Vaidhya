import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  // Default Data
  String _name = "Farmer";
  String _phone = "";
  String _location = "India";
  List<String> _crops = [];

  // Getters (To read data)
  String get name => _name;
  String get phone => _phone;
  String get location => _location;
  List<String> get crops => _crops;
  
  UserProvider() {
    loadUserData();
  }

  Future<void> loadUserData() async {
    final profile = await AuthService.getProfile();
    _name = profile['name'] ?? "Farmer";
    _phone = profile['phone'] ?? "";
    _location = profile['location'] ?? "India";
    _crops = List<String>.from(profile['crops'] ?? []);
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

  // Function to Update Crops
  void updateCrops(List<String> newCrops) {
    _crops = newCrops;
    AuthService.updateCrops(newCrops);
    notifyListeners();
  }
}