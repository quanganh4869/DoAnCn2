import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client; 
const String _productsTable = 'products'; 
const String _categoriesTable = 'categories';

class SupabaseDataSeeder {

  static Future<void> seedAllData() async {
    print('Starting Supabase data seeding...');
    await seedCategories(); 
    await seedProducts();
    print('Supabase data seeding complete. 🎉');
  }

  static Future<void> seedCategories() async {
    final List<Map<String, dynamic>> sampleCategories = [
      {
        'name': 'Electronics',
        'displayName': 'Electronics',
        'description': 'Devices, gadgets, and electronic items',
        'iconUrl': 'https://example.com/icons/electronics.png',
        'imageUrl': 'https://example.com/images/electronics.jpg',
        'is_active': true,
        'sortOrder': 1,
        'subcategories': ['Laptops', 'Phones', 'Accessories'],
        'metadata': {'department': 'Tech'},
      },
      {
        'name': 'Footwear',
        'displayName': 'Footwear',
        'description': 'Shoes, sneakers, boots, and sandals',
        'iconUrl': 'https://example.com/icons/footwear.png',
        'imageUrl': 'https://example.com/images/footwear.jpg',
        'is_active': true,
        'sortOrder': 2,
        'subcategories': ['Running Shoes', 'Casual Shoes'],
        'metadata': {},
      },
      {
        'name': 'Clothing',
        'displayName': 'Clothing',
        'description': 'Apparel, fashion, and garments',
        'iconUrl': 'https://example.com/icons/clothing.png',
        'imageUrl': 'https://example.com/images/clothing.jpg',
        'is_active': true,
        'sortOrder': 3,
        'subcategories': ['T-Shirts', 'Jeans', 'Jackets'],
        'metadata': {},
      },
      {
        'name': 'Accessories',
        'displayName': 'Accessories',
        'description': 'Bags, watches, jewelry, and other accessories',
        'iconUrl': 'https://example.com/icons/accessories.png',
        'imageUrl': 'https://example.com/images/accessories.jpg',
        'is_active': true,
        'sortOrder': 4,
        'subcategories': ['Bags', 'Watches', 'Jewelry'],
        'metadata': {},
      },
      {
        'name': 'Sports',
        'displayName': 'Sports',
        'description': 'Sports equipment and activewear',
        'iconUrl': 'https://example.com/icons/sports.png',
        'imageUrl': 'https://example.com/images/sports.jpg',
        'is_active': true,
        'sortOrder': 5,
        'subcategories': ['Gym', 'Outdoor', 'Team Sports'],
        'metadata': {},
      },
    ];

    try {
      final response = await supabase
          .from(_categoriesTable)
          .insert(sampleCategories)
          .select();

      if (response != null && response.isNotEmpty) {
        print('Successfully seeded ${sampleCategories.length} categories to Supabase.');
      } else {
        print(' Supabase insertion of categories returned empty.');
      }
    } on PostgrestException catch (e) {
      print('Supabase Error seeding categories: ${e.message}');
    } catch (e) {
      print(' General Error seeding categories: $e');
    }
  }

  static Future<void> seedProducts() async {
    final List<Map<String, dynamic>> sampleProducts = [
      {
        'name': 'Nike Air Max 270',
        'description': 'Comfortable running shoes with excellent cushioning.',
        'category': 'Footwear',
        'subcategory': 'Running Shoes', 
        'price': 129.99,
        'old_price': 179.99,
        'currency': 'USD',
        'images': ['https://example.com/shoe_1.jpg'],
        'primary_image': 'https://example.com/shoe_1.jpg',
        'brand': 'Nike',
        'sku': 'NIKE-AM270-001',
        'stock': 25,
        'is_active': true,
        'is_featured': true,
        'is_on_sale': true,
        'rating': 4.5,
        'review_count': 89,
        'tags': ['popular', 'trending', 'comfortable'], 
        'specification': {
          'color': 'White/Blue',
          'material': 'Synthetic',
          'sizes': ['7', '8', '9', '10', '11']
        },
        'search_keywords': ['nike', 'air', 'max', '270', 'shoes'],
        'is_favourite': false,
      },
      {
        'name': 'MacBook Pro 13"',
        'description': 'High-performance laptop with M2 chip.',
        'category': 'Electronics',
        'subcategory': 'Laptops',
        'price': 1299.00,
        'old_price': 1499.00,
        'currency': 'USD',
        'images': ['https://example.com/macbook_1.jpg'],
        'primary_image': 'https://example.com/macbook_1.jpg',
        'brand': 'Apple',
        'sku': 'MBP13-M2-256',
        'stock': 10,
        'is_active': true,
        'is_featured': true,
        'is_on_sale': false,
        'rating': 4.9,
        'review_count': 210,
        'tags': ['premium', 'laptop', 'apple'], 
        'specification': {
          'chip': 'Apple M2',
          'ram': '8GB',
          'storage': '256GB SSD',
        },
        'search_keywords': ['macbook', 'pro', 'apple', 'm2'],
        'is_favourite': false,
      },
    ];

    try {
      final response = await supabase
          .from(_productsTable)
          .insert(sampleProducts)
          .select();

      if (response != null && response.isNotEmpty) {
        print(' Successfully seeded ${sampleProducts.length} products to Supabase.');
      } else {
        print(' Supabase insertion of products returned empty.');
      }
    } on PostgrestException catch (e) {
      print(' Supabase Error seeding products: ${e.message}');
    } catch (e) {
      print(' General Error seeding products: $e');
    }
  }
}
