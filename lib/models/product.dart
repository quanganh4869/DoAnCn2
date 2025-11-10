
class Product {
  final String name;
  final String category;
  final double price;
  final double? oldPrice;
  final String currency;
  final bool isFavourite;
  final String description;
  final List<String> images;
  final String? brand;
  final String primaryImage;
  final String? sku;
  final int stock;
  final bool isActive;
  final bool isFeatured;
  final bool isOnSale;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final Map<String, dynamic> specification; 
  final DateTime? createdAt;
  final DateTime? updatedAt; 

  const Product({
    required this.name,
    required this.category,
    required this.price,
    this.oldPrice,
    this.currency = "VND",
    required this.isFavourite,
    required this.description,
    required this.images,
    this.brand,
    this.primaryImage = '',
    this.sku,
    this.stock = 0,
    this.isActive = true,
    this.isFeatured = false,
    this.isOnSale = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.tags = const [],
    this.specification = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromSupabaseJson(Map<String, dynamic> data) {
   

    return Product(
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (data['oldPrice'] as num?)?.toDouble(),
      currency: data['currency'] ?? "VND",
      images: List<String>.from(data['images'] ?? []), 
      primaryImage: data['primary_image'] ?? (data['images']?.isNotEmpty == true ? data['images'][0] : ""),
      isFavourite: data['is_favourite'] ?? false,
      description: data['description'] ?? '',
      brand: data['brand'],
      sku: data['sku'],
      stock: data['stock'] ?? 0,
      isActive: data['is_active'] ?? true,
      isFeatured: data['is_featured'] ?? false,
      isOnSale: data['is_on_sale'] ?? false,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['review_count'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      specification: Map<String, dynamic>.from(data['specification'] ?? {}), 
      // Chuyển đổi chuỗi ISO 8601 thành DateTime
      createdAt: data['created_at'] != null ? DateTime.parse(data['created_at']) : null,
      updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'old_price': oldPrice,
      'currency': currency,
      'is_favourite': isFavourite,
      'description': description,
      'images': images,
      'brand': brand,
      'primary_image': primaryImage,
      'sku': sku,
      'stock': stock,
      'is_active': isActive,
      'is_featured': isFeatured,
      'is_on_sale': isOnSale,
      'rating': rating,
      'review_count': reviewCount,
      'tags': tags,
      'specification': specification, 
      
    };
  }
  // final List<products> products =[];
}