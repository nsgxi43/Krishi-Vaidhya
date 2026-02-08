import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
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
  String? _locationError;

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
    _tabController = TabController(length: 4, vsync: this); 
    _initLocationAndFetchStores();
  }

  Future<void> _initLocationAndFetchStores() async {
    setState(() {
      _isLoadingStores = true;
      _locationError = null;
    });

    try {
      Position position = await _determinePosition();
      final stores = await ApiService.fetchNearbyStores(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _nearbyStores = stores;
          _isLoadingStores = false;
        });
      }
    } catch (e) {
      debugPrint("Location error, using fallback: $e");
      // FALLBACK: Use Bangalore coordinates if GPS fails
      final stores = await ApiService.fetchNearbyStores(12.9716, 77.5946);
      
      if (mounted) {
        setState(() {
          _nearbyStores = stores;
          _isLoadingStores = false;
          _locationError = "Could not get your precise location. Showing results for Bangalore (Default).";
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Using default location: GPS access failed.")),
        );
      }
    }
  }

  Future<Position> _determinePosition() async {
    // NOTE: Many geolocator methods throw MissingPluginException on Web 
    // if not served over HTTPS or if the plugin isn't fully registered.
    if (kIsWeb) {
      try {
        // On web, often we can just call getCurrentPosition and the browser handles the prompt.
        return await Geolocator.getCurrentPosition();
      } catch (e) {
        return Future.error('Location error: $e. Try refreshing or ensuring you are on a secure (HTTPS) connection.');
      }
    }

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    } 

    return await Geolocator.getCurrentPosition();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initLocationAndFetchStores,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          isScrollable: true, 
          tabs: [
            Tab(text: "Nearby Stores"), 
            Tab(text: AppTranslations.getText(langCode, 'cat_fertilizers')),
            Tab(text: AppTranslations.getText(langCode, 'cat_seeds')),
            Tab(text: AppTranslations.getText(langCode, 'cat_tools')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNearbyStoresTab(), 
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

    return Column(
      children: [
        if (_locationError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationError!,
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
                TextButton(
                  onPressed: _initLocationAndFetchStores,
                  child: const Text("Retry GPS", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        Expanded(
          child: _nearbyStores.isEmpty
              ? const Center(
                  child: Text("No nearby stores found.",
                      style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _nearbyStores.length,
                  itemBuilder: (context, index) {
                    final store = _nearbyStores[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("${store.distanceKm} km away",
                                style: TextStyle(color: Colors.green.shade700)),
                            const SizedBox(height: 2),
                            Text(store.address,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.directions, color: Colors.blue),
                          onPressed: () => _launchMaps(store.mapsUrl),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
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
