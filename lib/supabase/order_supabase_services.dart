import 'package:ecomerceapp/models/cart_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/features/shippingaddress/models/address.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart' as order_model;
import 'package:ecomerceapp/features/notification/models/notification_type.dart';
import 'package:ecomerceapp/features/notification/controller/notification_controller.dart';


class OrderSupabaseService {
  static final _supabase = Supabase.instance.client;

  // --- 1. TẠO ĐƠN HÀNG & GỬI THÔNG BÁO (KÈM LIST SẢN PHẨM) ---
  static Future<bool> placeOrder({
    required String userId,
    required String orderNumber,
    required double totalAmount,
    required Address shippingAddress,
    required List<CartItem> cartItems,
  }) async {
    try {
      print("START: Bắt đầu tạo đơn hàng...");

      final orderRes = await _supabase.from('orders').insert({
        'user_id': userId,
        'order_number': orderNumber,
        'total_amount': totalAmount,
        'status': 'pending',
        'shipping_address': shippingAddress.toJson(),
      }).select().single();

      final orderId = orderRes['id'];
      final Set<String> sellerIdsToNotify = {};

      final List<Map<String, dynamic>> itemsData = cartItems.map((item) {
        if (item.product?.sellerId != null) {
          sellerIdsToNotify.add(item.product!.sellerId!);
        }
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

      // --- GỬI THÔNG BÁO CHO SELLER (KÈM LIST SP CỦA HỌ) ---
      for (var sellerId in sellerIdsToNotify) {
        if (sellerId == userId) continue;

        // Lọc ra các sản phẩm thuộc về Seller này
        final sellerItems = cartItems.where((item) => item.product?.sellerId == sellerId).toList();

        // Tạo list metadata chi tiết
        final itemsMetadata = sellerItems.map((item) => {
          'productName': item.product?.name ?? 'Sản phẩm',
          'productImage': item.product?.primaryImage ?? '',
          'price': "${item.product?.price}",
          'quantity': item.quantity,
          'size': item.selectedSize,
          'color': item.selectedColor,
        }).toList();

        NotificationController.sendNotification(
          receiverId: sellerId,
          title: "Đơn hàng mới 📦",
          message: "Bạn có đơn hàng mới #$orderNumber gồm ${sellerItems.length} sản phẩm.",
          type: NotificationType.order,
          metadata: {
            'orderId': orderNumber,
            'items': itemsMetadata, // Gửi danh sách items
          },
        );
      }

      // --- GỬI THÔNG BÁO CHO USER (KÈM TOÀN BỘ SP) ---
      final allItemsMetadata = cartItems.map((item) => {
        'productName': item.product?.name ?? 'Sản phẩm',
        'productImage': item.product?.primaryImage ?? '',
        'price': "\$${item.product?.price}",
        'quantity': item.quantity,
        'size': item.selectedSize,
        'color': item.selectedColor,
      }).toList();

      NotificationController.sendNotification(
        receiverId: userId,
        title: "Đặt hàng thành công ✅",
        message: "Đơn hàng #$orderNumber của bạn đã được ghi nhận.",
        type: NotificationType.order,
        metadata: {
          'orderId': orderNumber,
          'items': allItemsMetadata, // Gửi danh sách items
        },
      );

      print("SUCCESS: Đã tạo đơn và gửi thông báo");
      return true;

    } catch (e) {
      print("❌ LỖI NGHIÊM TRỌNG: $e");
      return false;
    }
  }

  // ... (Giữ nguyên các hàm getMyOrders, getSellerOrders, updateOrderStatus, updateProductStock)

  static Future<List<order_model.Order>> getMyOrders(String userId) async {
    try {
      final response = await _supabase.from('orders').select(''' *, order_items ( id, product_id, quantity, price_at_purchase, selected_size, selected_color, products ( name, images ) ) ''').eq('user_id', userId).order('created_at', ascending: false);
      return (response as List).map((e) => order_model.Order.fromSupabaseJson(e)).toList();
    } catch (e) { return []; }
  }

  static Future<List<order_model.Order>> getSellerOrders(String sellerId) async {
    try {
      final response = await _supabase.from('orders').select(''' *, order_items!inner ( id, product_id, quantity, price_at_purchase, selected_size, selected_color, products!inner ( name, images, stock, seller_id ) ) ''').eq('order_items.products.seller_id', sellerId).order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      List<order_model.Order> sellerOrders = [];
      for (var orderJson in data) {
        order_model.Order order = order_model.Order.fromSupabaseJson(orderJson);
        final rawItems = orderJson['order_items'] as List;
        final myItemsJson = rawItems.where((item) {
          final product = item['products'];
          return product != null && product['seller_id'] == sellerId;
        }).toList();
        final filteredOrderJson = Map<String, dynamic>.from(orderJson);
        filteredOrderJson['order_items'] = myItemsJson;
        sellerOrders.add(order_model.Order.fromSupabaseJson(filteredOrderJson));
      }
      return sellerOrders;
    } catch (e) { return []; }
  }

  static Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try { await _supabase.from('orders').update({'status': newStatus}).eq('id', orderId); return true; } catch (e) { return false; }
  }

  static Future<bool> updateProductStock(List<order_model.OrderItem> items) async {
    try {
      for (var item in items) {
        final productRes = await _supabase.from('products').select('stock').eq('id', item.productId).single();
        final int currentStock = productRes['stock'] ?? 0;
        final int newStock = currentStock - item.quantity;
        if (newStock >= 0) { await _supabase.from('products').update({'stock': newStock}).eq('id', item.productId); } else { return false; }
      }
      return true;
    } catch (e) { return false; }
  }
}