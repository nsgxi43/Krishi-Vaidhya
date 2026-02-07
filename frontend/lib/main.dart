import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart'; // <--- 1. Import this
import 'screens/login_screen.dart'; 

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // <--- 2. Add Provider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Listen to ThemeProvider
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Krishi Vaidhya',
              
              // --- THEME CONFIGURATION ---
              themeMode: themeProvider.themeMode, 
              theme: ThemeData(
                brightness: Brightness.light,
                primarySwatch: Colors.green,
                scaffoldBackgroundColor: Colors.white,
                useMaterial3: true,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                primarySwatch: Colors.green,
                scaffoldBackgroundColor: const Color(0xFF121212), // Dark Grey
                useMaterial3: true,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF1F1F1F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                cardColor: const Color(0xFF1F1F1F),
              ),
              // ---------------------------

              home: const LoginScreen(), 
            );
          },
        );
      },
    );
  }
}