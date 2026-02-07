import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../utils/translations.dart';
import 'login_screen.dart'; // <--- FIXED: Added Import
import 'edit_profile_screen.dart'; // Assuming you have this
import 'settings_screen.dart'; // Assuming you have this
import 'help_support_screen.dart'; // Assuming you have this

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green.shade100,
                    child: Icon(Icons.person, size: 50, color: Colors.green.shade700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userProvider.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    userProvider.phone,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Options List
            _buildProfileOption(
              context, 
              icon: Icons.edit, 
              title: AppTranslations.getText(langCode, 'edit_profile'), 
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    currentName: userProvider.name,
                    currentPhone: userProvider.phone,
                    currentLocation: userProvider.location,
                  ),
                ),
              )
            ),
            
            _buildProfileOption(
              context, 
              icon: Icons.settings, 
              title: AppTranslations.getText(langCode, 'settings'), 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))
            ),

            _buildProfileOption(
              context, 
              icon: Icons.help_outline, 
              title: AppTranslations.getText(langCode, 'help_support'), 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()))
            ),

            const Divider(),

            // Logout Button
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              onTap: () {
                // FIXED: Navigation Logic
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()), // Removed 'const'
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.green),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}