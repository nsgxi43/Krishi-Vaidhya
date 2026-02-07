import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors extracted from your image
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreenBg = Color(0xFFE8F5E9); // For Camera Section
  static const Color cardGreen = Color(0xFFC8E6C9);    // For Tools
  static const Color weatherBlue = Color(0xFF90CAF9);
  static const Color almostWhite = Color(0xFFFAFAFA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: primaryGreen,
      // Apply Poppins font globally
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}