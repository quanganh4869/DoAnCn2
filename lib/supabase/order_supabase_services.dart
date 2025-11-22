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
      print("START: Bắt đầu tạo đơn hàng...");

      // BƯỚC 1: Tạo Order Master (Bảng orders)
      final orderRes = await _supabase.from('orders').insert({
        'user_id': userId,
        'order_number': orderNumber,
        'total_amount': totalAmount,
        'status': 'pending',
        'shipping_address': shippingAddress.toJson(),
      }).select().single();

      final orderId = orderRes['id'];
      print("SUCCESS: Đã tạo Order ID: $orderId");

      // BƯỚC 2: Chuẩn bị dữ liệu cho Order Items
      // --- ĐÂY LÀ ĐOẠN BẠN ĐANG THIẾU HOẶC SAI ---
      // Chúng ta phải chuyển List<CartItem> -> List<Map<String, dynamic>>

      final List<Map<String, dynamic>> itemsData = cartItems.map((item) {
        return {
          'order_id': orderId, // Quan trọng: Phải có ID của đơn hàng vừa tạo
          'product_id': item.productId,
          'quantity': item.quantity,
          'price_at_purchase': item.product?.price ?? 0, // Lưu giá tại thời điểm mua
          'selected_size': item.selectedSize,
          'selected_color': item.selectedColor,
        };
      }).toList();

      // BƯỚC 3: Insert Order Items (Bảng order_items)
      // Truyền vào itemsData (là List Map) chứ KHÔNG truyền cartItems
      await _supabase.from('order_items').insert(itemsData);

      print("SUCCESS: Đã tạo xong Order Items");
      return true;

    } catch (e) {
      print("❌ LỖI NGHIÊM TRỌNG: $e");
      return false;
    }
  }

  // 2. LẤY DANH SÁCH ĐƠN HÀNG CỦA USER
  static Future<List<Order>> getMyOrders(String userId) async {
    try {
      // Thêm id, product_id, price, size, color vào câu select
final response = await _supabase
      .from('orders')
      .select('''
        *,
        order_items (
          id,
          product_id,
          quantity,
          price_at_purchase,
          selected_size,
          selected_color,
          products (
            name,
            images
          )
        )
      ''')
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