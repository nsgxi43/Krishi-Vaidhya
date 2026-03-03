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
import 'crop_calendar_screen.dart';
import 'agri_store_screen.dart';
import 'crop_select_screen.dart';
import 'profile_screen.dart';
import 'fertilizer_calculator_screen.dart';
import 'community_screen.dart';
import 'settings_screen.dart';
import 'predictive_analysis_screen.dart';
// --- FIXED IMPORTS END ---

class HomeScreen extends StatefulWidget {
  final List<CropItem>? initialCrops;
  const HomeScreen({super.key, this.initialCrops});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _notificationCount = 3;
  final _communityKey = GlobalKey<CommunityScreenState>();

  late List<CropItem> _myCrops;

  @override
  void initState() {
    super.initState();
    // Initialize crops from constructor or default dummy data
    _myCrops = widget.initialCrops ?? [
      CropItem(nameKey: 'Tomato', imagePath: 'assets/images/tomato.png', color: Colors.red.shade50, isSelected: true),
      CropItem(nameKey: 'Wheat', imagePath: 'assets/images/wheat.png', color: Colors.orange.shade50, isSelected: true),
    ];
  }

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
      CommunityScreen(key: _communityKey),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor:
          _selectedIndex == 1 ? const Color(0xFFF4F6F8) : Colors.white,

      // Dynamic App Bar (Only for Home)
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(langCode),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 13),
                  ),
                  Text(
                    userProvider.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                Stack(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.notifications_none,
                            color: Colors.white, size: 28),
                        onPressed: _showNotifications),
                    if (_notificationCount > 0)
                      Positioned(
                        right: 11,
                        top: 11,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6)),
                          constraints: const BoxConstraints(
                              minWidth: 14, minHeight: 14),
                          child: Text('$_notificationCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                        ),
                      )
                  ],
                ),
                const SizedBox(width: 10),
              ],
            )
          : null,

      body: pages[_selectedIndex],

      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _communityKey.currentState?.showPostDialog(),
              backgroundColor: Colors.green,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: Text(
                AppTranslations.getText(langCode, 'ask_community'),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              elevation: 3,
            )
          : null,

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

  String _greeting(String langCode) {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppTranslations.getText(langCode, 'good_morning');
    if (hour < 17) return AppTranslations.getText(langCode, 'good_afternoon');
    return AppTranslations.getText(langCode, 'good_evening');
  }

  Widget _buildHomeBody(String langCode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Weather Card ──────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: WeatherCard(),
          ),
          const SizedBox(height: 20),

          // ── Selected Crops ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppTranslations.getText(langCode, 'selected_crops'),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87),
                      ),
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => CropSelectScreen(
                                      initialCrops: _myCrops)));
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
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _myCrops.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _myCrops.length) {
                          return GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => CropSelectScreen(
                                          initialCrops: _myCrops)));
                              if (result != null && result is List<CropItem>) {
                                setState(() => _myCrops = result);
                              }
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  margin: const EdgeInsets.only(
                                      right: 16, bottom: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2))
                                    ],
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.grey, size: 30),
                                ),
                                const Text("Add",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey))
                              ],
                            ),
                          );
                        }
                        final crop = _myCrops[index];
                        return Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              margin:
                                  const EdgeInsets.only(right: 16, bottom: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipOval(
                                  child: Image.asset(
                                    crop.imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        Icon(Icons.grass, color: crop.color),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              AppTranslations.getText(
                                  langCode, crop.nameKey.toLowerCase()),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87),
                            )
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── AI Diagnosis Banner ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CameraScreen())),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.getText(langCode, 'take_picture'),
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Scan your crop to instantly detect diseases with AI.',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8)),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              AppTranslations.getText(
                                  langCode, 'scan_now'),
                              style: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 38),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Tools Grid ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppTranslations.getText(langCode, 'kisaan_tools'),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.5,
              children: [
                _buildToolCard(
                  AppTranslations.getText(langCode, 'store_title'),
                  Icons.store_mall_directory_rounded,
                  const Color(0xFFFFF3E0),
                  const Color(0xFFE65100),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AgriStoreScreen())),
                ),
                _buildToolCard(
                  AppTranslations.getText(langCode, 'calendar'),
                  Icons.calendar_month_rounded,
                  const Color(0xFFE3F2FD),
                  const Color(0xFF1565C0),
                  () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CropCalendarScreen(myCrops: _myCrops))),
                ),
                _buildToolCard(
                  AppTranslations.getText(langCode, 'fertilizer'),
                  Icons.calculate_rounded,
                  const Color(0xFFF3E5F5),
                  const Color(0xFF6A1B9A),
                  () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const FertilizerCalculatorScreen())),
                ),
                _buildToolCard(
                  AppTranslations.getText(langCode, 'pred_title'),
                  Icons.shield_rounded,
                  const Color(0xFFFFEBEE),
                  const Color(0xFFC62828),
                  () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const PredictiveAnalysisScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    String title,
    IconData icon,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: iconColor.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: iconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}