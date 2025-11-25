class Products {
  final String id;
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
  final String? sellerId;

  Products({
    required this.id,
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
    this.sellerId,
  });

  factory Products.fromSupabaseJson(Map<String, dynamic> data, String id) {
    String? extractedBrand;

    // Logic lấy Brand từ bảng sellers/users (quan hệ Joined)
    // Supabase trả về dạng: { ..., "sellers": { "brand_name": "Adidas" } }
    // Hoặc nếu bạn join với bảng users: { ..., "users": { "shop_name": "My Shop" } }
    if (data['sellers'] != null) {
      extractedBrand = data['sellers']['brand_name'] ?? data['sellers']['shop_name'];
    } else if (data['users'] != null) {
      extractedBrand = data['users']['shop_name'] ?? data['users']['full_name'];
    }

    return Products(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (data['old_price'] as num?)?.toDouble(),
      currency: data['currency'] ?? "VND",
      images: List<String>.from(data['images'] ?? []),
      primaryImage: data['primary_image'] ?? (data['images'] != null && (data['images'] as List).isNotEmpty ? data['images'][0] : ""),
      isFavourite: data['is_favourite'] ?? false,
      description: data['description'] ?? '',
      brand: extractedBrand ?? data['brand'] ?? "Unknown Brand",
      sku: data['sku'],
      stock: data['stock'] ?? 0,
      isActive: data['is_active'] ?? true,
      isFeatured: data['is_featured'] ?? false,
      isOnSale: data['is_on_sale'] ?? false,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['review_count'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      specification: data['specification'] != null ? Map<String, dynamic>.from(data['specification']) : {},
      createdAt: data['created_at'] != null ? DateTime.tryParse(data['created_at']) : null,
      updatedAt: data['updated_at'] != null ? DateTime.tryParse(data['updated_at']) : null,
      sellerId: data['seller_id'],
    );
  }

  factory Products.fromJson(Map<String, dynamic> json) {
     return Products.fromSupabaseJson(json, json['id']?.toString() ?? '');
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

  // Getters tiện ích
  String get imageUrl => primaryImage.isNotEmpty ? primaryImage : (images.isNotEmpty ? images[0] : '');

  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  int get discountPercentage {
    if (!hasDiscount) return 0;
    return (((oldPrice! - price) / oldPrice!) * 100).round();
  }

  bool get isInstock => stock > 0;

  String? get formattedOldPrice => oldPrice != null ? "\$${oldPrice!.toStringAsFixed(3)}" : null;
}