import 'package:supabase_flutter/supabase_flutter.dart';
// ignore_for_file: avoid_print


// Model hứng dữ liệu từ hàm RPC (Database function)
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
      // Chuyển đổi giờ UTC từ server về giờ địa phương ngay lập tức
      orderDate: DateTime.parse(json['order_date']).toLocal(),
      status: json['order_status'] ?? 'pending',
      productName: json['product_name'] ?? 'Unknown',
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
    );
  }
}

class StatsSupabaseService {
  static final _supabase = Supabase.instance.client;

  /// Gọi hàm RPC 'get_seller_stats_orders' trong Database
  /// Hàm này giúp bypass RLS (quyền truy cập) để lấy dữ liệu thống kê chính xác
  static Future<List<StatOrderItem>> getSellerStats(String sellerId) async {
    try {
      print("📊 Đang gọi RPC get_seller_stats_orders cho Seller: $sellerId");

      // Gọi function trong Postgres
      final List<dynamic> response = await _supabase
          .rpc('get_seller_stats_orders', params: {'_seller_id': sellerId});

      print("✅ RPC Thành công! Số dòng dữ liệu: ${response.length}");

      if (response.isNotEmpty) {
        print("   Mẫu dữ liệu đầu tiên: ${response[0]}");
      } else {
        print("   ⚠️ RPC trả về rỗng. Kiểm tra lại đơn hàng hoặc seller_id.");
      }

      return response.map((e) => StatOrderItem.fromJson(e)).toList();
    } catch (e) {
      print("❌ Lỗi RPC Thống kê: $e");
      return [];
    }
  }
}