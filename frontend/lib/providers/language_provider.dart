import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLocale = 'en'; // Default is English

  String get currentLocale => _currentLocale;

  // LOGIC: Load saved language when app starts
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLocale = prefs.getString('language_code') ?? 'en';
    notifyListeners(); // Update the UI
  }

  // LOGIC: Change language and save it
  Future<void> changeLanguage(String newLocale) async {
    if (_currentLocale == newLocale) return;
    
    _currentLocale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale);
    
    notifyListeners(); // This triggers the app to redraw with new text
  }

  // Backwards-compatible API: some screens call `setLanguage`.
  Future<void> setLanguage(String newLocale) async {
    return changeLanguage(newLocale);
  }
}