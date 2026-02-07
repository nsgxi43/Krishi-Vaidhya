class Product {
  final String id;
  final String nameKey;    // The translation key or raw name
  final String imagePath;  // Path to asset image
  final double price;
  final String category;   // 'fertilizers', 'seeds', 'tools'
  final String sellerName;
  final String sellerPhone;

  Product({
    required this.id,
    required this.nameKey,
    required this.imagePath,
    required this.price,
    required this.category,
    required this.sellerName,
    required this.sellerPhone,
  });
}