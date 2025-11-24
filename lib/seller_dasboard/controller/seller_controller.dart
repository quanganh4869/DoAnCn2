import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/controller/product_controller.dart';
import 'package:ecomerceapp/supabase/order_supabase_services.dart';
import 'package:ecomerceapp/features/notification/models/notification_type.dart';
import 'package:ecomerceapp/features/notification/controller/notification_controller.dart';


class SellerController extends GetxController {
  final _supabase = Supabase.instance.client;
  final AuthController _authController = Get.find<AuthController>();

  var isSellerMode = false.obs;
  var isLoading = false.obs;
  var myProducts = <Products>[].obs;
  var orders = <Order>[].obs;

  StreamSubscription<List<Map<String, dynamic>>>? _shopStatusSubscription;
  RealtimeChannel? _ordersSubscription;

  @override
  void onInit() {
    super.onInit();
    // Automatically setup listeners when user profile loads
    ever(_authController.userProfileRx, (UserProfile? profile) {
      if (profile != null) {
        _setupShopStatusListener(profile.id);
        if (isSellerMode.value) {
          _setupOrderRealtimeListener();
        }
      } else {
        resetState();
      }
    });

    // Initial check
    if (_authController.userProfile != null) {
      _setupShopStatusListener(_authController.userProfile!.id);
    }
  }

  @override
  void onClose() {
    _shopStatusSubscription?.cancel();
    _ordersSubscription?.unsubscribe();
    super.onClose();
  }

  void resetState() {
    isSellerMode.value = false;
    myProducts.clear();
    orders.clear();
    isLoading.value = false;
    _shopStatusSubscription?.cancel();
    _ordersSubscription?.unsubscribe();
  }

  // --- 1. LISTEN FOR SHOP APPROVAL ---
  void _setupShopStatusListener(String userId) {
    _shopStatusSubscription?.cancel();
    _shopStatusSubscription = _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((List<Map<String, dynamic>> data) {
      if (data.isNotEmpty) {
        final updatedProfile = UserProfile.fromJson(data.first);
        final newStatus = updatedProfile.sellerStatus;
        final oldStatus = _authController.userProfile?.sellerStatus;

        // If shop is just approved/active
        if (oldStatus != 'active' && (newStatus == 'active' || newStatus == 'approved')) {
          _showSuccessSnackbar("Congratulations!", "Your shop has been approved.");
          isSellerMode.value = true;

          // Load data immediately
          fetchSellerProducts();
          fetchSellerOrders();
          _setupOrderRealtimeListener();
        }
        _authController.updateLocalProfile(updatedProfile);
      }
    });
  }

  // --- 2. LISTEN FOR NEW ORDERS (REALTIME) ---
  void _setupOrderRealtimeListener() {
    if (_ordersSubscription != null) {
      _supabase.removeChannel(_ordersSubscription!);
    }

    // Listen to 'order_items' table since that's where seller products appear
    _ordersSubscription = _supabase.channel('public:order_items').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'order_items',
      callback: (payload) {
        print("♻️ New order activity detected! Refreshing orders...");
        fetchSellerOrders();
      },
    ).subscribe();
  }

  // --- 3. SELLER REGISTRATION & MODE TOGGLE ---

  Future<bool> registerSeller({
    required String storeName, required String description,
    required String businessEmail, required String shopPhone, required String shopAddress
  }) async {
    final user = _authController.userProfile;
    if (user == null) return false;

    isLoading.value = true;
    try {
      final updateData = {
        'shop_name': storeName, 'shop_description': description,
        'business_email': businessEmail, 'shop_phone': shopPhone,
        'shop_address': shopAddress, 'seller_status': 'pending',
      };
      await _supabase.from('users').update(updateData).eq('id', user.id);

      final updatedProfile = user.copyWith(
        storeName: storeName, storeDescription: description, businessEmail: businessEmail,
        shopPhone: shopPhone, shopAddress: shopAddress, sellerStatus: 'pending',
      );

      await _authController.updateLocalProfile(updatedProfile);
      _showSuccessSnackbar("Success", "Shop registration submitted!");
      return true;
    } catch (e) {
      _showErrorSnackbar("Error", "An error occurred: $e");
      return false;
    } finally { isLoading.value = false; }
  }

  void toggleSellerMode() {
    final user = _authController.userProfile;
    if (user == null || user.sellerStatus == 'none' || user.sellerStatus == null) {
       _showErrorSnackbar("Error", "You haven't registered as a seller."); return;
    }
    if (user.sellerStatus == 'pending') {
      _showErrorSnackbar("Pending", "Your application is under review."); return;
    }
    if (user.sellerStatus == 'rejected') {
      _showErrorSnackbar("Rejected", "Your application was rejected."); return;
    }

    if (user.sellerStatus == 'active' || user.sellerStatus == 'approved') {
      isSellerMode.value = !isSellerMode.value;
      if (isSellerMode.value) {
        fetchSellerProducts();
        fetchSellerOrders();
        _setupOrderRealtimeListener();
        _showInfoSnackbar("Mode", "Seller Dashboard");
      } else {
        _ordersSubscription?.unsubscribe();
        _ordersSubscription = null;
        _showInfoSnackbar("Mode", "Shopping");
      }
    }
  }

  // --- 4. PRODUCT MANAGEMENT ---
  Future<void> fetchSellerProducts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await _supabase.from('products').select()
          .eq('seller_id', userId).eq('is_active', true).order('created_at', ascending: false);
      myProducts.value = (response as List).map((e) => Products.fromSupabaseJson(e, e['id'].toString())).toList();
    } catch (e) { debugPrint("Error fetching products: $e"); }
  }

  Future<bool> addProduct({required String name, required String description, required double price, required String category, required int stock, String? imageUrl, double? oldPrice, Map<String, dynamic>? specification}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      isLoading.value = true;
      await _supabase.from('products').insert({
        'name': name, 'description': description, 'price': price, 'old_price': oldPrice,
        'category': category, 'stock': stock, 'images': imageUrl != null ? [imageUrl] : [],
        'seller_id': userId, 'is_featured': false, 'is_active': true, 'specification': specification ?? {},
      });
      await fetchSellerProducts(); _refreshGlobalProducts(); _showSuccessSnackbar("Success", "Product added!"); return true;
    } catch (e) { _showErrorSnackbar("Error", "Failed to add product: $e"); return false; } finally { isLoading.value = false; }
  }

  Future<bool> updateProduct({required String productId, required String name, required String description, required double price, required String category, required int stock, String? imageUrl, double? oldPrice, Map<String, dynamic>? specification}) async {
    try {
      isLoading.value = true;
      await _supabase.from('products').update({
        'name': name, 'description': description, 'price': price, 'old_price': oldPrice,
        'category': category, 'stock': stock, 'images': imageUrl != null ? [imageUrl] : [],
        'specification': specification ?? {},
      }).eq('id', productId);
      await fetchSellerProducts(); _refreshGlobalProducts(); _showSuccessSnackbar("Success", "Product updated!"); return true;
    } catch (e) { _showErrorSnackbar("Error", "Update failed: $e"); return false; } finally { isLoading.value = false; }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      try { await _supabase.from('products').delete().eq('id', productId); }
      catch (fkError) { await _supabase.from('products').update({'is_active': false}).eq('id', productId); }
      myProducts.removeWhere((p) => p.id == productId); _refreshGlobalProducts(); _showSuccessSnackbar("Deleted", "Product deleted successfully.");
    } catch (e) { _showErrorSnackbar("Error", "Cannot delete: $e"); }
  }

  void _refreshGlobalProducts() { if (Get.isRegistered<ProductController>()) { Get.find<ProductController>().loadProducts(); } }

  // --- 5. ORDER MANAGEMENT (WITH FILTERING & NOTIFICATIONS) ---

  void fetchSellerOrders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. Get all orders containing this shop's products
      final result = await OrderSupabaseService.getSellerOrders(userId);

      // 2. FILTER: Only show orders where the BUYER is NOT the current SELLER
      // This separates "User Mode" orders from "Seller Mode" incoming orders
      final customerOrders = result.where((order) => order.userId != userId).toList();

      orders.value = customerOrders;
    } catch (e) {
      debugPrint("Error fetching orders: $e");
    }
  }

  Future<void> changeOrderStatus(Order order, OrderStatus nextStatus) async {
    try {
      isLoading.value = true;

      // Stock deduction logic
      if (order.status == OrderStatus.pending && nextStatus == OrderStatus.confirmed) {
        final stockUpdated = await OrderSupabaseService.updateProductStock(order.items);
        if (!stockUpdated) {
          Get.snackbar("Out of Stock", "Not enough stock to confirm this order!", backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red, snackPosition: SnackPosition.TOP);
          isLoading.value = false;
          return;
        }
      }

      final success = await OrderSupabaseService.updateOrderStatus(order.id, nextStatus.name);

      if (success) {
        _showSuccessSnackbar("Success", "Order status updated to: ${nextStatus.name}");
        fetchSellerOrders();

        // --- SEND NOTIFICATION TO USER ---
        String msg = "";
        String title = "Order Update 🔔";
        NotificationType type = NotificationType.order;

        switch (nextStatus) {
          case OrderStatus.confirmed: msg = "Your order #${order.orderNumber} has been confirmed by the shop."; break;
          case OrderStatus.shipping: msg = "Order #${order.orderNumber} has been handed over to the carrier 🚚."; type = NotificationType.delivery; break;
          case OrderStatus.delivering: msg = "Shipper is delivering order #${order.orderNumber}."; type = NotificationType.delivery; break;
          case OrderStatus.completed: msg = "Order completed! Thank you for shopping with us."; type = NotificationType.delivery; break;
          case OrderStatus.cancelled: msg = "Order #${order.orderNumber} has been cancelled."; break;
          default: return;
        }

        // Prepare metadata list for all items in the order
        final itemsMetadata = order.items.map((item) => {
          'productName': item.productName,
          'productImage': item.productImage,
          'price': "\$${item.price}",
          'quantity': item.quantity,
          'size': item.selectedSize,
          'color': item.selectedColor,
        }).toList();

        // Send notification with product details
        NotificationController.sendNotification(
          receiverId: order.userId,
          title: title,
          message: msg,
          type: type,
          metadata: {
            'orderId': order.orderNumber,
            'items': itemsMetadata, // Send list of items for detail view
          },
        );

      } else {
        _showErrorSnackbar("Error", "Failed to update status");
      }
    } catch (e) {
      debugPrint("Error changing order status: $e");
      _showErrorSnackbar("Error", "Exception: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- SNACKBAR HELPERS ---
  void _showSuccessSnackbar(String t, String m) => Get.rawSnackbar(title: t, message: m, backgroundColor: Colors.green, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(10), borderRadius: 10, icon: const Icon(Icons.check_circle, color: Colors.white));
  void _showErrorSnackbar(String t, String m) => Get.rawSnackbar(title: t, message: m, backgroundColor: Colors.red, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(10), borderRadius: 10, icon: const Icon(Icons.error, color: Colors.white));
  void _showInfoSnackbar(String t, String m) => Get.rawSnackbar(title: t, message: m, backgroundColor: Colors.blue, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(10), borderRadius: 10, icon: const Icon(Icons.info, color: Colors.white));
}