import 'package:ecomerceapp/models/cart_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/features/shippingaddress/models/address.dart';

class OrderSupabaseService {
  static final _supabase = Supabase.instance.client;

  // --- 1. TẠO ĐƠN HÀNG ---
  static Future<bool> placeOrder({
    required String userId,
    required String orderNumber,
    required double totalAmount,
    required Address shippingAddress,
    required List<CartItem> cartItems,
  }) async {
    try {
      print("START: Bắt đầu tạo đơn hàng...");

      // B1: Tạo Order Master
      final orderRes = await _supabase.from('orders').insert({
        'user_id': userId,
        'order_number': orderNumber,
        'total_amount': totalAmount,
        'status': 'pending',
        'shipping_address': shippingAddress.toJson(),
      }).select().single();

      final orderId = orderRes['id'];
      print("SUCCESS: Đã tạo Order ID: $orderId");

      // B2: Map dữ liệu từ CartItem (Model của bạn) sang JSON để lưu DB
      final List<Map<String, dynamic>> itemsData = cartItems.map((item) {
        return {
          'order_id': orderId,
          'product_id': item.productId, // String nhưng DB tự ép kiểu sang BigInt nếu chuỗi là số
          'quantity': item.quantity,
          'price_at_purchase': item.product?.price ?? 0,
          'selected_size': item.selectedSize,
          'selected_color': item.selectedColor,
        };
      }).toList();

      // B3: Lưu chi tiết đơn hàng
      await _supabase.from('order_items').insert(itemsData);

      print("SUCCESS: Đã tạo xong Order Items");
      return true;

    } catch (e) {
      print("❌ LỖI NGHIÊM TRỌNG: $e");
      return false;
    }
  }

  // --- 2. LẤY DANH SÁCH ĐƠN HÀNG (Của User) ---
  static Future<List<Order>> getMyOrders(String userId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items (
              id, product_id, quantity, price_at_purchase, selected_size, selected_color,
              products ( name, images )
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

  // --- 3. LẤY DANH SÁCH ĐƠN HÀNG (Cho Seller) ---
  static Future<List<Order>> getSellerOrders(String sellerId) async {
    try {
      // 1. Query lấy Orders có chứa sản phẩm của Seller này
      // Dùng !inner để chỉ lấy những đơn hàng nào CÓ sản phẩm của shop
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items!inner (
              id, product_id, quantity, price_at_purchase, selected_size, selected_color,
              products!inner (
                name, images, stock, seller_id
              )
            )
          ''')
          .eq('order_items.products.seller_id', sellerId) // Lọc từ phía DB
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      // 2. Xử lý dữ liệu đầu ra
      // Mặc dù DB đã lọc orders, nhưng danh sách order_items trả về có thể vẫn chứa món của shop khác (do cơ chế join).
      // Ta cần lọc thủ công list items một lần nữa trong Dart.

      List<Order> sellerOrders = [];

      for (var orderJson in data) {
        // Parse Order từ JSON
        Order order = Order.fromSupabaseJson(orderJson);

        // Lọc danh sách items: Chỉ giữ lại item nào có seller_id trùng với seller đang đăng nhập
        // Lưu ý: Logic này yêu cầu ta phải check seller_id từ dữ liệu raw JSON hoặc cập nhật Model OrderItem
        // Ở đây ta sẽ lọc trực tiếp từ JSON 'order_items' trước khi map vào Model Order nếu có thể,
        // hoặc lọc trên list items của object Order.

        // Cách đơn giản nhất: Lọc dựa trên dữ liệu raw json order_items
        final rawItems = orderJson['order_items'] as List;
        final myItemsJson = rawItems.where((item) {
          final product = item['products'];
          return product != null && product['seller_id'] == sellerId;
        }).toList();

        // Tạo lại order json với danh sách items đã lọc
        final filteredOrderJson = Map<String, dynamic>.from(orderJson);
        filteredOrderJson['order_items'] = myItemsJson;

        // Parse lại thành Object Order hoàn chỉnh chỉ chứa sản phẩm của Shop
        sellerOrders.add(Order.fromSupabaseJson(filteredOrderJson));
      }

      return sellerOrders;
    } catch (e) {
      print("Get Seller Orders Error: $e");
      return [];
    }
  }

  // ... (Giữ nguyên updateOrderStatus và updateProductStock)

  // 4. CẬP NHẬT TRẠNG THÁI
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

  // 5. TRỪ TỒN KHO
  static Future<bool> updateProductStock(List<OrderItem> items) async {
    try {
      for (var item in items) {
        final productRes = await _supabase
            .from('products')
            .select('stock')
            .eq('id', item.productId)
            .single();

        final int currentStock = productRes['stock'] ?? 0;
        final int newStock = currentStock - item.quantity;

        if (newStock >= 0) {
          await _supabase
              .from('products')
              .update({'stock': newStock})
              .eq('id', item.productId);
        } else {
          print("Sản phẩm ID ${item.productId} không đủ hàng!");
          return false;
        }
      }
      return true;
    } catch (e) {
      print("Stock Update Error: $e");
      return false;
    }
  }
}