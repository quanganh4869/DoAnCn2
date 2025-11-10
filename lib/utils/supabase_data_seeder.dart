import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client; 
const String _productsTable = 'products'; 

class SupabaseDataSeeder {

  /// Chức năng: Chạy tất cả các hàm seed dữ liệu
  static Future<void> seedAllData() async {
    print('Starting Supabase data seeding...');
    await seedProducts();
    print('Supabase data seeding complete. 🎉');
  }

  /// Chức năng: Thêm dữ liệu sản phẩm mẫu vào bảng 'products' trong Supabase
  static Future<void> seedProducts() async {
    // Dữ liệu mẫu phải sử dụng snake_case (primary_image, is_active, v.v.)
    // và không sử dụng FieldValue.serverTimestamp() vì Supabase/PostgreSQL 
    // tự động quản lý các trường timestamp (created_at, updated_at).
    final List<Map<String, dynamic>> sampleProducts = [
      {
        // ------------------ SẢN PHẨM 1: Nike Air Max 270 ------------------
        'name': 'Nike Air Max 270',
        'description': 'Comfortable running shoes with excellent cushioning and modern design. Perfect for daily wear and light exercise.',
        'category': 'Footwear',
        'subcategory': 'Running Shoes', // Dựa trên ảnh trước
        'price': 129.99,
        'old_price': 179.99, // snake_case
        'currency': 'USD',
        'images': ['https://example.com/shoe_1.jpg', 'https://example.com/shoe_2.jpg'], 
        'primary_image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQz50rIHINcVvWcnB6YJ1Ig2nO3rymRPhF1AQ&s', // snake_case
        'brand': 'Nike',
        'sku': 'NIKE-AM270-001',
        'stock': 25,
        'is_active': true, // snake_case
        'is_featured': true, // snake_case
        'is_on_sale': true, // snake_case
        'rating': 4.5,
        'review_count': 89, // snake_case
        'tags': ['popular', 'trending', 'comfortable'], 
        'specification': { // JSONB type in Supabase
          'color': 'White/Blue',
          'material': 'Synthetic',
          'weight': '0.8kg',
          'sizes': ['7', '8', '9', '10', '11']
        },
        'search_keywords': [ // snake_case
          'nike', 'air', 'max', '270', 'shoes', 'running', 'footwear', 'white', 'blue'
        ],
        'is_favourite': false, // Thêm trường isFavourite từ Model
      },
      {
        // ------------------ SẢN PHẨM 2: MacBook Pro 13" ------------------
        'name': 'MacBook Pro 13"',
        'description': 'High-performance laptop with M2 chip, perfect for professionals and creative work. Features stunning Retina display.',
        'category': 'Electronics',
        'subcategory': 'Laptops', // Hoàn thiện dữ liệu
        'price': 1299.00,
        'old_price': 1499.00,
        'currency': 'USD',
        'images': ['https://example.com/macbook_1.jpg', 'https://example.com/macbook_2.jpg'], 
        'primary_image': 'https://example.com/macbook_1.jpg',
        'brand': 'Apple',
        'sku': 'MBP13-M2-256',
        'stock': 10,
        'is_active': true,
        'is_featured': true,
        'is_on_sale': false,
        'rating': 4.9,
        'review_count': 210,
        'tags': ['premium', 'laptop', 'apple', 'm2'], 
        'specification': {
          'chip': 'Apple M2',
          'ram': '8GB',
          'storage': '256GB SSD',
          'display': '13.3-inch Retina',
        },
        'search_keywords': [
          'macbook', 'pro', 'apple', 'm2', 'laptop', 'electronics'
        ],
        'is_favourite': false, 
      }
      // Bạn có thể thêm nhiều sản phẩm mẫu khác ở đây
    ];

    try {
      if (sampleProducts.isEmpty) {
        print('No sample products to seed.');
        return;
      }
      
      // Chèn tất cả dữ liệu mẫu vào bảng 'products'
      final response = await supabase
          .from(_productsTable)
          .insert(sampleProducts)
          .select(); // Dùng .select() để trả về dữ liệu đã chèn

      if (response != null && response.isNotEmpty) {
        print('✅ Successfully seeded ${sampleProducts.length} products to Supabase.');
      } else {
        print('⚠️ Supabase insertion resulted in an empty return, check database constraints.');
      }

    } on PostgrestException catch (e) {
      print('❌ Supabase Error seeding products: ${e.message}');
      print('Details: ${e.details}');
    } catch (e) {
      print('❌ General Error seeding products: $e');
    }
  }
}