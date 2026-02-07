import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  // Default Data
  String _name = "Raju Kumar";
  String _phone = "+91 98765 43210";
  String _location = "Punjab, India";

  // Getters (To read data)
  String get name => _name;
  String get phone => _phone;
  String get location => _location;

  // Function to Update Data
  void updateProfile(String newName, String newPhone, String newLocation) {
    _name = newName;
    _phone = newPhone;
    _location = newLocation;
    notifyListeners(); // <--- This tells Home & Profile screens to refresh!
  }
}