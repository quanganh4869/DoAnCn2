import 'package:ecomerceapp/models/cart_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/features/shippingaddress/models/address.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart' as order_model;
import 'package:ecomerceapp/features/notification/models/notification_type.dart';
import 'package:ecomerceapp/features/notification/controller/notification_controller.dart';

class OrderSupabaseService {
  static final _supabase = Supabase.instance.client;

  //  TẠO ĐƠN HÀNG & GỬI THÔNG BÁO
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

      // B2: Map dữ liệu chi tiết & Lấy danh sách Seller cần báo
      final Set<String> sellerIdsToNotify = {};

      final List<Map<String, dynamic>> itemsData = cartItems.map((item) {
        // Lưu lại sellerId để gửi thông báo
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

      // B3: Insert Order Items
      await _supabase.from('order_items').insert(itemsData);

      // --- GỬI THÔNG BÁO (REALTIME) ---

      // 1. Thông báo cho Người Bán (Sellers)
      for (var sellerId in sellerIdsToNotify) {
        // Bỏ qua nếu tự mua hàng của chính mình
        if (sellerId == userId) continue;

        NotificationController.sendNotification(
          receiverId: sellerId,
          title: "Đơn hàng mới 📦",
          message: "Bạn nhận được đơn hàng mới #$orderNumber. Hãy vào kiểm tra ngay!",
          type: NotificationType.order,
        );
      }

      // 2. Thông báo xác nhận cho Người Mua (Buyer)
      NotificationController.sendNotification(
        receiverId: userId,
        title: "Đặt hàng thành công ✅",
        message: "Đơn hàng #$orderNumber của bạn đã được ghi nhận. Chờ Shop xác nhận nhé!",
        type: NotificationType.order,
      );
      // --------------------------------

      print("SUCCESS: Đã tạo đơn và gửi thông báo");
      return true;

    } catch (e) {
      print("❌ LỖI NGHIÊM TRỌNG: $e");
      return false;
    }
  }

  // --- 2. LẤY DANH SÁCH ĐƠN HÀNG CỦA USER ---
  static Future<List<order_model.Order>> getMyOrders(String userId) async {
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

      return (response as List).map((e) => order_model.Order.fromSupabaseJson(e)).toList();
    } catch (e) {
      print("Get Orders Error: $e");
      return [];
    }
  }

  // --- 3. LẤY DANH SÁCH ĐƠN HÀNG CHO SELLER ---
  // Chỉ lấy những đơn có chứa sản phẩm của Seller này
  static Future<List<order_model.Order>> getSellerOrders(String sellerId) async {
    try {
      // Query: Lấy Order có join với order_items, và order_items join với products
      // Điều kiện: products.seller_id == sellerId
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items!inner (
              id, product_id, quantity, price_at_purchase, selected_size, selected_color,
              products!inner ( name, images, stock, seller_id )
            )
          ''')
          .eq('order_items.products.seller_id', sellerId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      List<order_model.Order> sellerOrders = [];

      for (var orderJson in data) {
        // Parse Order từ JSON
        order_model.Order order = order_model.Order.fromSupabaseJson(orderJson);

        // --- LỌC ITEM ---
        // Một đơn hàng có thể chứa sp của nhiều Shop.
        // Ta phải lọc list 'items' trong object Order để Seller chỉ thấy sp của mình.
        final rawItems = orderJson['order_items'] as List;

        final myItemsJson = rawItems.where((item) {
          final product = item['products'];
          return product != null && product['seller_id'] == sellerId;
        }).toList();

        // Hack: Tạo lại JSON với list items đã lọc để parse lại
        final filteredOrderJson = Map<String, dynamic>.from(orderJson);
        filteredOrderJson['order_items'] = myItemsJson;

        sellerOrders.add(order_model.Order.fromSupabaseJson(filteredOrderJson));
      }
      return sellerOrders;
    } catch (e) {
      print("Get Seller Orders Error: $e");
      return [];
    }
  }

  // --- 4. CẬP NHẬT TRẠNG THÁI ---
  // Việc gửi thông báo cho User khi cập nhật trạng thái được xử lý ở SellerController
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

  // --- 5. TRỪ TỒN KHO ---
  static Future<bool> updateProductStock(List<order_model.OrderItem> items) async {
    try {
      for (var item in items) {
        // Lấy tồn kho hiện tại
        final productRes = await _supabase
            .from('products')
            .select('stock')
            .eq('id', item.productId)
            .single();

        final int currentStock = productRes['stock'] ?? 0;
        final int newStock = currentStock - item.quantity;

        // Check không âm
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