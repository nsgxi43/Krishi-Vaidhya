import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import 'language_screen.dart';
import 'login_screen.dart';
// import 'edit_profile_screen.dart'; // Uncomment when you create these files
// import 'help_support_screen.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local state for switches (In a real app, save these in SharedPreferences)
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          AppTranslations.getText(langCode, 'settings'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==========================
          // 1. GENERAL SECTION
          // ==========================
          _buildSectionHeader(langCode, 'general'),
          
          _buildSettingsTile(
            icon: Icons.language,
            iconColor: Colors.purple,
            title: AppTranslations.getText(langCode, 'change_language'),
            subtitle: _getLanguageName(langCode),
            onTap: () {
              // Pass fromSettings: true so it shows the back button
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const LanguageScreen(fromSettings: true))
              );
            },
          ),
          
          _buildSwitchTile(
            icon: Icons.notifications,
            iconColor: Colors.orange,
            title: AppTranslations.getText(langCode, 'enable_notifications'),
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
              // TODO: Save preference logic here
            },
          ),

          _buildSwitchTile(
            icon: Icons.dark_mode,
            iconColor: Colors.black,
            title: AppTranslations.getText(langCode, 'dark_mode'),
            value: _darkModeEnabled,
            onChanged: (val) {
              setState(() => _darkModeEnabled = val);
              // TODO: Implement Theme Switching logic
            },
          ),

          const SizedBox(height: 20),

          // ==========================
          // 2. ACCOUNT SECTION
          // ==========================
          _buildSectionHeader(langCode, 'account'),
          
          _buildSettingsTile(
            icon: Icons.person,
            iconColor: Colors.blue,
            title: AppTranslations.getText(langCode, 'edit_profile'),
            onTap: () {
               // Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            },
          ),
          
          _buildSettingsTile(
            icon: Icons.phone,
            iconColor: Colors.green,
            title: AppTranslations.getText(langCode, 'change_number'),
            onTap: () {
              // Handle change number logic
            },
          ),

          const SizedBox(height: 20),

          // ==========================
          // 3. SUPPORT SECTION
          // ==========================
          _buildSectionHeader(langCode, 'help_support'),
          
          _buildSettingsTile(
            icon: Icons.help_outline,
            iconColor: Colors.teal,
            title: AppTranslations.getText(langCode, 'help_support'),
            onTap: () {
              // Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
            },
          ),
          
          _buildSettingsTile(
            icon: Icons.info_outline,
            iconColor: Colors.grey,
            title: AppTranslations.getText(langCode, 'about_app'),
            subtitle: "v1.0.0",
            onTap: () {},
          ),
          
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.indigo,
            title: AppTranslations.getText(langCode, 'privacy_policy'),
            onTap: () {},
          ),

          const SizedBox(height: 30),

          // ==========================
          // 4. LOGOUT BUTTON
          // ==========================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showLogoutDialog(context, langCode);
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text(
                AppTranslations.getText(langCode, 'logout'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSectionHeader(String langCode, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        AppTranslations.getText(langCode, key).toUpperCase(),
        style: TextStyle(
          fontSize: 13, 
          fontWeight: FontWeight.bold, 
          color: Colors.grey.shade600, 
          letterSpacing: 1.2
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        value: value,
        activeColor: Colors.green,
        onChanged: onChanged,
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'hi': return 'हिंदी';
      case 'ta': return 'தமிழ்';
      case 'te': return 'తెలుగు';
      default: return 'English';
    }
  }

  void _showLogoutDialog(BuildContext context, String langCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppTranslations.getText(langCode, 'logout')),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close Dialog
              // Navigate to Login and clear history
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}