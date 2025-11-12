import 'package:ecomerceapp/models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductSupabaseServices {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _productTable = "products";

  ///  Lấy toàn bộ sản phẩm đang active (is_active = true)
  static Future<List<Products>> getAllProducts() async {
    try {
      final response = await _supabase
          .from(_productTable)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      return data
          .map(
            (item) => Products.fromSupabaseJson(
              Map<String, dynamic>.from(item),
              item['id'].toString(),
            ),
          )
          .toList();
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }

  ///  Lấy sản phẩm theo ID
  static Future<Products?> getProductById(String productId) async {
    try {
      final response = await _supabase
          .from(_productTable)
          .select()
          .eq('id', productId)
          .maybeSingle();

      if (response == null) return null;

      return Products.fromSupabaseJson(
        Map<String, dynamic>.from(response),
        response['id'].toString(),
      );
    } catch (e) {
      print("Error fetching product by ID: $e");
      return null;
    }
  }

  ///  Stream realtime sản phẩm (Supabase Realtime)
  static Stream<List<Products>> getProductsStream() {
    return _supabase
        .from(_productTable)
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at')
        .map(
          (events) => events
              .map(
                (item) => Products.fromSupabaseJson(
                  Map<String, dynamic>.from(item),
                  item['id'].toString(),
                ),
              )
              .toList(),
        );
  }

  ///  Lấy sản phẩm trong khoảng giá
  static Future<List<Products>> getProductsByPriceRange({
    required double minPrice,
    required double maxPrice,
  }) async {
    try {
      final response = await _supabase
          .from(_productTable)
          .select()
          .gte('price', minPrice)
          .lte('price', maxPrice)
          .eq('is_active', true)
          .order('price', ascending: true);

      final List<dynamic> data = response;
      return data
          .map(
            (item) => Products.fromSupabaseJson(
              Map<String, dynamic>.from(item),
              item['id'].toString(),
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching products by price range: $e');
      return [];
    }
  }

  ///  Lấy toàn bộ danh mục (category) duy nhất
  static Future<List<String>> getAllCategories() async {
    try {
      final response = await _supabase
          .from(_productTable)
          .select('category')
          .eq('is_active', true);

      final List<dynamic> data = response;
      final categories = <String>{};

      for (var item in data) {
        if (item['category'] != null) {
          categories.add(item['category'] as String);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  ///  Lấy sản phẩm theo danh mục
  static Future<List<Products>> getProductsByCategory(String category) async {
    try {
      final response = await _supabase
          .from(_productTable)
          .select()
          .eq('is_active', true)
          .eq('category', category)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      return data
          .map(
            (item) => Products.fromSupabaseJson(
              Map<String, dynamic>.from(item),
              item['id'].toString(),
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching products by category: $e');
      return [];
    }
  }

  ///  Lấy sản phẩm nổi bật (is_featured = true)
  static Future<List<Products>> getFeaturedProducts() async {
    try {
      final response = await _supabase
          .from(_productTable)
          .select()
          .eq('is_active', true)
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(10);

      final List<dynamic> data = response;
      return data
          .map(
            (item) => Products.fromSupabaseJson(
              Map<String, dynamic>.from(item),
              item['id'].toString(),
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching featured products: $e');
      return [];
    }
  }

  ///  Lấy sản phẩm đang giảm giá (is_on_sale = true)
  static Future<List<Products>> getSaleProducts() async {
    try {
      final response = await _supabase
          .from(_productTable)
          .select()
          .eq('is_active', true)
          .eq('is_on_sale', true)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      return data
          .map(
            (item) => Products.fromSupabaseJson(
              Map<String, dynamic>.from(item),
              item['id'].toString(),
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching sale products: $e');
      return [];
    }
  }

  ///  Tìm kiếm sản phẩm theo tên hoặc từ khóa
  static Future<List<Products>> searchProducts(String searchTerm) async {
    try {
      final response = await _supabase
          .from(_productTable)
          .select()
          .ilike('name', '%$searchTerm%')
          .eq('is_active', true);

      final List<dynamic> data = response;
      return data
          .map(
            (item) => Products.fromSupabaseJson(
              Map<String, dynamic>.from(item),
              item['id'].toString(),
            ),
          )
          .toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }
}
