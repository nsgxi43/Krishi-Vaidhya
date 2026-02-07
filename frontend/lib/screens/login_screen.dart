import 'dart:math'; // For Random OTP
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart'; // Import Provider
import '../utils/translations.dart'; // Import Translations
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // Simulate authentication delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Generate Random OTP
    int generatedOtp = Random().nextInt(9000) + 1000; 

    setState(() => _loading = false);

    // Show OTP (Translating "OTP Sent" using generic fallback if key missing, or English)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP: $generatedOtp'), 
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );

    // Navigate to OTP verification screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          mobileNumber: _phoneController.text,
          generatedOtp: generatedOtp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get the current language code
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // 2. Translate App Bar Title
        title: Text(AppTranslations.getText(langCode, 'login'), style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.agriculture, // Changed to agriculture icon
                    size: 60,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // 3. Translate Welcome Text
              Text(
                AppTranslations.getText(langCode, 'welcome'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // 4. Translate Subtitle
              Text(
                AppTranslations.getText(langCode, 'enter_mobile'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              
              const SizedBox(height: 40),
              
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  prefixText: '+91 ',
                  // 5. Translate Label
                  labelText: AppTranslations.getText(langCode, 'enter_mobile'),
                  hintText: '00000 00000',
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Required';
                  }
                  String pattern = r'^[6-9]\d{9}$';
                  RegExp regExp = RegExp(pattern);
                  if (!regExp.hasMatch(v)) {
                    return 'Invalid Number'; 
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          // 6. Translate Button Text
                          AppTranslations.getText(langCode, 'get_otp'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}