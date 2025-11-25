import 'package:supabase_flutter/supabase_flutter.dart';
class StatOrderItem {
  final String orderNumber;
  final DateTime orderDate;
  final String status;
  final String productName;
  final int quantity;
  final double price;

  StatOrderItem({
    required this.orderNumber,
    required this.orderDate,
    required this.status,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory StatOrderItem.fromJson(Map<String, dynamic> json) {
    return StatOrderItem(
      orderNumber: json['order_number'] ?? '',
      orderDate: DateTime.parse(json['order_date']).toLocal(),
      status: json['order_status'] ?? 'pending',
      productName: json['product_name'] ?? 'Unknown',
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
    );
  }
}

class StatReviewItem {
  final int rating;
  final DateTime createdAt;

  StatReviewItem({required this.rating, required this.createdAt});

  factory StatReviewItem.fromJson(Map<String, dynamic> json) {
    return StatReviewItem(
      rating: (json['rating'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}

class StatsSupabaseService {
  static final _supabase = Supabase.instance.client;

  static Future<List<StatOrderItem>> getSellerStats(String sellerId) async {
    try {
      final List<dynamic> response = await _supabase
          .rpc('get_seller_stats_orders', params: {'_seller_id': sellerId});
      return response.map((e) => StatOrderItem.fromJson(e)).toList();
    } catch (e) {
      print(" Lỗi RPC Thống kê: $e");
      return [];
    }
  }

  static Future<List<StatReviewItem>> getSellerReviews(String sellerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('rating, created_at, products!inner(seller_id)')
          .eq('products.seller_id', sellerId)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((e) => StatReviewItem.fromJson(e)).toList();
    } catch (e) {
      print(" Lỗi lấy Review Stats: $e");
      return [];
    }
  }
}