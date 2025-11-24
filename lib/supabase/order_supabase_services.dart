import 'package:ecomerceapp/models/cart_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/features/shippingaddress/models/address.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart' as order_model;
import 'package:ecomerceapp/features/notification/models/notification_type.dart';
import 'package:ecomerceapp/features/notification/controller/notification_controller.dart';

class OrderSupabaseService {
  static final _supabase = Supabase.instance.client;

  // --- 1. CREATE ORDER & SEND NOTIFICATIONS ---
  static Future<bool> placeOrder({
    required String userId,
    required String orderNumber,
    required double totalAmount,
    required Address shippingAddress,
    required List<CartItem> cartItems,
  }) async {
    try {
      print("START: Placing order...");

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

      // --- SEND NOTIFICATIONS (REALTIME) ---

      for (var sellerId in sellerIdsToNotify) {
        final sellerItems = cartItems.where((item) => item.product?.sellerId == sellerId).toList();

        final itemsMetadata = sellerItems.map((item) => {
          'productName': item.product?.name ?? 'Product',
          'productImage': item.product?.primaryImage ?? '',
          'price': item.product?.price,
          'quantity': item.quantity,
          'size': item.selectedSize,
          'color': item.selectedColor,
        }).toList();

        NotificationController.sendNotification(
          receiverId: sellerId,
          title: "New Order 📦",
          message: "You have a new order #$orderNumber containing ${sellerItems.length} items.",
          type: NotificationType.order,
          metadata: {
            'orderId': orderNumber,
            'role': 'seller',
            'items': itemsMetadata,
          },
        );
      }

      // B. Notify Buyer (User)
      final allItemsMetadata = cartItems.map((item) => {
        'productName': item.product?.name ?? 'Product',
        'productImage': item.product?.primaryImage ?? '',
        'price': item.product?.price,
        'quantity': item.quantity,
        'size': item.selectedSize,
        'color': item.selectedColor,
      }).toList();

      NotificationController.sendNotification(
        receiverId: userId,
        title: "Order Successful ✅",
        message: "Your order #$orderNumber has been placed successfully.",
        type: NotificationType.order,
        metadata: {
          'orderId': orderNumber,
          'role': 'user', // Mark as user notification
          'items': allItemsMetadata,
        },
      );

      print("SUCCESS: Order created and notifications sent.");
      return true;

    } catch (e) {
      print("❌ CRITICAL ERROR: $e");
      return false;
    }
  }

  // --- 2. GET USER ORDERS ---
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

  // --- 3. GET SELLER ORDERS ---
  // Logic: Fetches orders containing this seller's products, then filters the items list locally
  static Future<List<order_model.Order>> getSellerOrders(String sellerId) async {
    try {
      // Query: Get orders joined with order_items (where product belongs to sellerId)
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
        // 1. Get raw items list from JSON
        final rawItems = orderJson['order_items'] as List;

        // 2. MANUAL FILTER: Keep only items that belong to this seller
        final myItemsJson = rawItems.where((item) {
          final product = item['products'];
          return product != null && product['seller_id'] == sellerId;
        }).toList();

        // 3. Create a new JSON map with the filtered items list
        final filteredOrderJson = Map<String, dynamic>.from(orderJson);
        filteredOrderJson['order_items'] = myItemsJson;

        // 4. Parse into Order object
        sellerOrders.add(order_model.Order.fromSupabaseJson(filteredOrderJson));
      }
      return sellerOrders;
    } catch (e) {
      print("Get Seller Orders Error: $e");
      return [];
    }
  }

  // --- 4. UPDATE ORDER STATUS ---
  static Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase.from('orders').update({'status': newStatus}).eq('id', orderId);
      return true;
    } catch (e) {
      print("Update Status Error: $e");
      return false;
    }
  }

  // --- 5. DEDUCT STOCK ---
  static Future<bool> updateProductStock(List<order_model.OrderItem> items) async {
    try {
      for (var item in items) {
        // Get current stock
        final productRes = await _supabase
            .from('products')
            .select('stock')
            .eq('id', item.productId)
            .single();

        final int currentStock = productRes['stock'] ?? 0;
        final int newStock = currentStock - item.quantity;

        // Check if stock is sufficient
        if (newStock >= 0) {
          await _supabase
              .from('products')
              .update({'stock': newStock})
              .eq('id', item.productId);
        } else {
          print("Product ID ${item.productId} out of stock!");
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