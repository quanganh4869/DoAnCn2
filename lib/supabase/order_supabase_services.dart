import 'package:ecomerceapp/models/cart_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/features/shippingaddress/models/address.dart';

class OrderSupabaseService {
  static final _supabase = Supabase.instance.client;

  // 1. TẠO ĐƠN HÀNG
  static Future<bool> placeOrder({
    required String userId,
    required String orderNumber,
    required double totalAmount,
    required Address shippingAddress,
    required List<CartItem> cartItems,
  }) async {
    try {
      // Tạo Order Master
      final orderRes = await _supabase.from('orders').insert({
        'user_id': userId,
        'order_number': orderNumber,
        'total_amount': totalAmount,
        'status': 'pending', // Mặc định là pending
        'shipping_address': shippingAddress.toJson(),
      }).select().single();

      final orderId = orderRes['id'];

      // Tạo Order Items
      final List<Map<String, dynamic>> itemsData = cartItems.map((item) {
        return {
          'order_id': orderId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price_at_purchase': item.product?.price ?? 0,
          'selected_size': item.selectedSize,
          'selected_color': item.selectedColor,
        };
      }).toList();

      await _supabase.from('order_items').insert(itemsData);
      return true;
    } catch (e) {
      print("Place Order Error: $e");
      return false;
    }
  }

  // 2. LẤY DANH SÁCH ĐƠN HÀNG CỦA USER
  static Future<List<Order>> getMyOrders(String userId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(quantity, products(name, images))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Order.fromSupabaseJson(e)).toList();
    } catch (e) {
      print("Get Orders Error: $e");
      return [];
    }
  }

  // 3. LẤY DANH SÁCH ĐƠN HÀNG CHO SELLER (Tất cả đơn hàng)
  // Trong thực tế, bạn cần lọc theo brand_id của seller trong bảng order_items
  static Future<List<Order>> getSellerOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(quantity, products(name, images))')
          .order('created_at', ascending: false);

      return (response as List).map((e) => Order.fromSupabaseJson(e)).toList();
    } catch (e) {
      print("Get Seller Orders Error: $e");
      return [];
    }
  }

  // 4. CẬP NHẬT TRẠNG THÁI ĐƠN HÀNG (Cho Seller)
  static Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      return true;
    } catch (e) {
      print("Update Status Error: $e");
      return false;
    }
  }
}