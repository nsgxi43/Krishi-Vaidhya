import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- FIXED IMPORTS START ---
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../utils/translations.dart';
import '../models/crop_item.dart';
import '../widgets/weather_card.dart';

// Screens (These are in the same folder, so just use the filename)
import 'camera_screen.dart';
import 'calendar_screen.dart';
import 'agri_store_screen.dart';
import 'crop_select_screen.dart';
import 'profile_screen.dart';
import 'fertilizer_calculator_screen.dart';
import 'community_screen.dart';
import 'settings_screen.dart';
// --- FIXED IMPORTS END ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _notificationCount = 3;

  // Initial dummy data for testing. 
  // Ideally, this list should come from UserProvider so it persists across screens.
  List<CropItem> _myCrops = [
    CropItem(nameKey: 'Apple', imagePath: 'assets/images/apple.png', color: Colors.red.shade50, isSelected: true),
    CropItem(nameKey: 'Wheat', imagePath: 'assets/images/wheat.png', color: Colors.orange.shade50, isSelected: true),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showNotifications() {
    final langCode = Provider.of<LanguageProvider>(context, listen: false).currentLocale;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppTranslations.getText(langCode, 'notifications_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _notificationCount = 0);
                    },
                    child: Text(AppTranslations.getText(langCode, 'clear_all')),
                  )
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud, color: Colors.blue),
                      title: Text(AppTranslations.getText(langCode, 'rain_alert')),
                      subtitle: Text(AppTranslations.getText(langCode, 'rain_desc')),
                    ),
                    ListTile(
                      leading: const Icon(Icons.store, color: Colors.orange),
                      title: Text(AppTranslations.getText(langCode, 'mandi_update')),
                      subtitle: Text(AppTranslations.getText(langCode, 'mandi_desc')),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;
    final userProvider = Provider.of<UserProvider>(context);

    // Body Switcher
    final List<Widget> pages = [
      _buildHomeBody(langCode),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,

      // Dynamic App Bar (Only for Home)
      appBar: _selectedIndex == 0 ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppTranslations.getText(langCode, 'welcome'), style: const TextStyle(color: Colors.grey, fontSize: 14)),
            Text(userProvider.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black, size: 28), onPressed: _showNotifications),
              if (_notificationCount > 0)
                Positioned(
                  right: 11, top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text('$_notificationCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                )
            ],
          ),
          const SizedBox(width: 10),
        ],
      ) : null,

      body: pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: AppTranslations.getText(langCode, 'home')),
          BottomNavigationBarItem(icon: const Icon(Icons.people), label: AppTranslations.getText(langCode, 'community')),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: AppTranslations.getText(langCode, 'profile')),
        ],
      ),
    );
  }

  Widget _buildHomeBody(String langCode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WeatherCard(),
          const SizedBox(height: 24),

          // --- SELECTED CROPS ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5), // Light Grey Card
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.getText(langCode, 'selected_crops'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    InkWell(
                      onTap: () async {
                        // Open selection screen
                        final result = await Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => CropSelectScreen(initialCrops: _myCrops)
                          )
                        );
                        // Update crops if result is returned
                        if (result != null && result is List<CropItem>) {
                          setState(() => _myCrops = result);
                        }
                      },
                      child: const Icon(Icons.edit, size: 20, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 90, // Height to fit text below circle
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _myCrops.length + 1, // +1 for the "Add" button
                    itemBuilder: (context, index) {
                      // 1. The "Add New" Button (Last Item)
                      if (index == _myCrops.length) {
                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => CropSelectScreen(initialCrops: _myCrops)
                              )
                            );
                            if (result != null && result is List<CropItem>) {
                              setState(() => _myCrops = result);
                            }
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 60, height: 60,
                                margin: const EdgeInsets.only(right: 16, bottom: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                                ),
                                child: const Icon(Icons.add, color: Colors.grey, size: 30),
                              ),
                              const Text("Add", style: TextStyle(fontSize: 12, color: Colors.grey))
                            ],
                          ),
                        );
                      }

                      // 2. The Actual Crop Items
                      final crop = _myCrops[index];
                      return Column(
                        children: [
                          Container(
                            width: 60, height: 60,
                            margin: const EdgeInsets.only(right: 16, bottom: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipOval(
                                child: Image.asset(
                                  crop.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Icon(Icons.grass, color: crop.color),
                                ),
                              ),
                            ),
                          ),
                          // Crop Name Text
                          Text(
                            AppTranslations.getText(langCode, crop.nameKey.toLowerCase()),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                          )
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // AI Camera Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9), // Light Green
              borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: Colors.green.shade200)
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.getText(langCode, 'take_picture'), 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppTranslations.getText(langCode, 'detect_disease') == 'Key not found' 
                            ? "Detect diseases instantly." 
                            : AppTranslations.getText(langCode, 'detect_disease'),
                        style: const TextStyle(fontSize: 12, color: Colors.black54)
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    shape: const CircleBorder(), 
                    padding: const EdgeInsets.all(14)
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tools Grid
          Text(AppTranslations.getText(langCode, 'kisaan_tools'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2, 
            shrinkWrap: true, 
            physics: const NeverScrollableScrollPhysics(), 
            crossAxisSpacing: 16, 
            mainAxisSpacing: 16, 
            childAspectRatio: 1.5,
            children: [
              _buildToolCard(context, AppTranslations.getText(langCode, 'store_title'), Icons.store_mall_directory, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AgriStoreScreen()))),
              _buildToolCard(context, AppTranslations.getText(langCode, 'calendar'), Icons.calendar_today, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarScreen()))),
              _buildToolCard(context, AppTranslations.getText(langCode, 'fertilizer'), Icons.calculate, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FertilizerCalculatorScreen()))),
              _buildToolCard(context, AppTranslations.getText(langCode, 'alerts'), Icons.notifications_active, Colors.red, () => _showNotifications()),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1), 
              radius: 24, 
              child: Icon(icon, color: color, size: 28)
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}