import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart'; // <--- IMPORTANT: Import this
import '../utils/translations.dart';
import 'language_screen.dart';
import 'login_screen.dart';
// import 'edit_profile_screen.dart'; // Uncomment when created
// import 'help_support_screen.dart'; // Uncomment when created

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification state stays local for now (until you build a NotificationProvider)
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    // 1. Access Providers
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      // Dynamic Background Color based on Theme
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppTranslations.getText(langCode, 'settings'),
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontWeight: FontWeight.bold
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
            context,
            icon: Icons.language,
            iconColor: Colors.purple,
            title: AppTranslations.getText(langCode, 'change_language'),
            subtitle: _getLanguageName(langCode),
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const LanguageScreen(fromSettings: true))
              );
            },
          ),
          
          _buildSwitchTile(
            context,
            icon: Icons.notifications,
            iconColor: Colors.orange,
            title: AppTranslations.getText(langCode, 'enable_notifications'),
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
            },
          ),

          // --- DARK MODE SWITCH (CONNECTED) ---
          _buildSwitchTile(
            context,
            icon: Icons.dark_mode,
            iconColor: Colors.grey.shade800,
            title: AppTranslations.getText(langCode, 'dark_mode'),
            value: themeProvider.isDarkMode, // Read from Provider
            onChanged: (val) {
              themeProvider.toggleTheme(val); // Update Provider
            },
          ),

          const SizedBox(height: 20),

          // ==========================
          // 2. ACCOUNT SECTION
          // ==========================
          _buildSectionHeader(langCode, 'account'),
          
          _buildSettingsTile(
            context,
            icon: Icons.person,
            iconColor: Colors.blue,
            title: AppTranslations.getText(langCode, 'edit_profile'),
            onTap: () {
               // Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            },
          ),
          
          _buildSettingsTile(
            context,
            icon: Icons.phone,
            iconColor: Colors.green,
            title: AppTranslations.getText(langCode, 'change_number'),
            onTap: () {},
          ),

          const SizedBox(height: 20),

          // ==========================
          // 3. SUPPORT SECTION
          // ==========================
          _buildSectionHeader(langCode, 'help_support'),
          
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            iconColor: Colors.teal,
            title: AppTranslations.getText(langCode, 'help_support'),
            onTap: () {
              // Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
            },
          ),
          
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            iconColor: Colors.grey,
            title: AppTranslations.getText(langCode, 'about_app'),
            subtitle: "v1.0.0",
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

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    // Dynamic Card Color for Dark Mode
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Card(
      color: cardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), 
        side: BorderSide(color: Colors.grey.withOpacity(0.2))
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Card(
      color: cardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), 
        side: BorderSide(color: Colors.grey.withOpacity(0.2))
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
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
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(AppTranslations.getText(langCode, 'logout')),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); 
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