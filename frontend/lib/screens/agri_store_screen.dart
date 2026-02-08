import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../models/product.dart';
import '../models/diagnosis_response.dart'; // For NearbyStore model
import '../services/api_service.dart';

class AgriStoreScreen extends StatefulWidget {
  const AgriStoreScreen({super.key});

  @override
  State<AgriStoreScreen> createState() => _AgriStoreScreenState();
}

class _AgriStoreScreenState extends State<AgriStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Nearby Stores Data
  List<NearbyStore> _nearbyStores = [];
  bool _isLoadingStores = true;

  // --- MOCK DATA FOR THE STORE (Existing) ---
  final List<Product> _allProducts = [
    // Fertilizers
    Product(
        id: '1',
        nameKey: 'Mancozeb 75% WP',
        imagePath: '',
        price: 450,
        category: 'fertilizers',
        sellerName: 'Raju Agri Works',
        sellerPhone: '9876543210'),
    Product(
        id: '2',
        nameKey: 'Neem Oil',
        imagePath: '',
        price: 200,
        category: 'fertilizers',
        sellerName: 'Green Earth Organics',
        sellerPhone: '1234567890'),
    Product(
        id: '3',
        nameKey: 'Urea 45kg',
        imagePath: '',
        price: 266,
        category: 'fertilizers',
        sellerName: 'Kisan Seva Kendra',
        sellerPhone: '9988776655'),

    // Seeds
    Product(
        id: '4',
        nameKey: 'Hybrid Tomato Seeds',
        imagePath: '',
        price: 800,
        category: 'seeds',
        sellerName: 'National Seeds Corp',
        sellerPhone: '1800112233'),
    Product(
        id: '5',
        nameKey: 'Potato Tubers (Kufri)',
        imagePath: '',
        price: 1200,
        category: 'seeds',
        sellerName: 'Punjab Potato Growers',
        sellerPhone: '9876500000'),

    // Tools
    Product(
        id: '6',
        nameKey: 'Knapsack Sprayer',
        imagePath: '',
        price: 2500,
        category: 'tools',
        sellerName: 'Agro Tech Tools',
        sellerPhone: '9898989898'),
    Product(
        id: '7',
        nameKey: 'Sickle (High Carbon)',
        imagePath: '',
        price: 150,
        category: 'tools',
        sellerName: 'Local Blacksmith',
        sellerPhone: '9000090000'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Increased to 4
    _fetchStores();
  }

  Future<void> _fetchStores() async {
    // TODO: Get real location. Using Bangalore default.
    final stores = await ApiService.fetchNearbyStores(12.9716, 77.5946);
    if (mounted) {
      setState(() {
        _nearbyStores = stores;
        _isLoadingStores = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LOGIC: Open Phone Dialer ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        debugPrint("Cannot launch dialer for $phoneNumber");
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
    }
  }

  // --- LOGIC: Launch Maps ---
  Future<void> _launchMaps(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.getText("E", 'store_title')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          isScrollable: true, // Allow scrolling for 4 tabs
          tabs: [
            Tab(text: "Nearby Stores"), // New Tab
            Tab(text: AppTranslations.getText(langCode, 'cat_fertilizers')),
            Tab(text: AppTranslations.getText(langCode, 'cat_seeds')),
            Tab(text: AppTranslations.getText(langCode, 'cat_tools')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNearbyStoresTab(), // New Tab View
          _buildProductList('fertilizers', langCode),
          _buildProductList('seeds', langCode),
          _buildProductList('tools', langCode),
        ],
      ),
    );
  }

  Widget _buildNearbyStoresTab() {
    if (_isLoadingStores) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_nearbyStores.isEmpty) {
      return const Center(
        child: Text("No nearby stores found.",
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nearbyStores.length,
      itemBuilder: (context, index) {
        final store = _nearbyStores[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.store, color: Colors.green),
            ),
            title: Text(
              store.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("${store.distanceKm} km away",
                    style: TextStyle(color: Colors.green.shade700)),
                const SizedBox(height: 2),
                Text(store.address, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.directions, color: Colors.blue),
              onPressed: () => _launchMaps(store.mapsUrl),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList(String category, String langCode) {
    final products = _allProducts.where((p) => p.category == category).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Product Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getCategoryIcon(category),
                      size: 30, color: _getCategoryColor(category)),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nameKey,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${AppTranslations.getText(langCode, 'price_rs')} ${product.price.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.sellerName,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                // Call Button
                IconButton(
                  onPressed: () => _makePhoneCall(product.sellerPhone),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                  ),
                  icon: const Icon(Icons.phone, color: Colors.white, size: 20),
                  tooltip: AppTranslations.getText(langCode, 'call_seller'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper for Icons
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'fertilizers':
        return Icons.science; // Chemical/Medicine
      case 'seeds':
        return Icons.grass; // Seeds
      case 'tools':
        return Icons.build; // Tools
      default:
        return Icons.shopping_bag;
    }
  }

  // Helper for Colors
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'fertilizers':
        return Colors.purple;
      case 'seeds':
        return Colors.green;
      case 'tools':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
