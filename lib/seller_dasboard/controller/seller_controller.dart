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

  // Đổi tên biến cho khớp với tên hàm để dễ quản lý
  StreamSubscription<List<Map<String, dynamic>>>? _shopStatusSubscription;
  RealtimeChannel? _ordersSubscription;

  @override
  void onInit() {
    super.onInit();
    // Lắng nghe Auth để tự động bật tính năng Seller
    ever(_authController.userProfileRx, (UserProfile? profile) {
      if (profile != null) {
        _setupShopStatusListener(profile.id);
        // Nếu đang ở chế độ Seller thì bật lắng nghe đơn hàng luôn
        if (isSellerMode.value) {
          _setupOrderRealtimeListener();
        }
      } else {
        resetState();
      }
    });

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

  // --- 1. LẮNG NGHE TRẠNG THÁI SHOP (DUYỆT/TỪ CHỐI) ---
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

        if (oldStatus != 'active' && (newStatus == 'active' || newStatus == 'approved')) {
          _showSuccessSnackbar("Chúc mừng!", "Cửa hàng của bạn đã được duyệt.");
          isSellerMode.value = true;

          // Load dữ liệu ngay khi được duyệt
          fetchSellerProducts();
          fetchSellerOrders();
          _setupOrderRealtimeListener();
        }
        _authController.updateLocalProfile(updatedProfile);
      }
    });
  }

  // --- 2. LẮNG NGHE ĐƠN HÀNG MỚI (REALTIME) ---
  void _setupOrderRealtimeListener() {
    if (_ordersSubscription != null) {
      _supabase.removeChannel(_ordersSubscription!);
    }

    // Lắng nghe bảng 'order_items' vì khi có đơn mới, bảng này sẽ được insert
    _ordersSubscription = _supabase.channel('public:order_items').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'order_items',
      callback: (payload) {
        print("♻️ Có thay đổi trong đơn hàng! Đang tải lại danh sách...");
        fetchSellerOrders();
      },
    ).subscribe();
  }

  // --- 3. CÁC CHỨC NĂNG KHÁC ---

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
      _showSuccessSnackbar("Thành công", "Đã gửi hồ sơ đăng ký shop!");
      return true;
    } catch (e) {
      _showErrorSnackbar("Lỗi", "Có lỗi xảy ra: $e");
      return false;
    } finally { isLoading.value = false; }
  }

  void toggleSellerMode() {
    final user = _authController.userProfile;
    if (user == null || user.sellerStatus == 'none' || user.sellerStatus == null) {
       _showErrorSnackbar("Lỗi", "Bạn chưa đăng ký người bán."); return;
    }
    if (user.sellerStatus == 'pending') {
      _showErrorSnackbar("Chờ duyệt", "Hồ sơ đang được xét duyệt."); return;
    }
    if (user.sellerStatus == 'rejected') {
      _showErrorSnackbar("Từ chối", "Hồ sơ bị từ chối."); return;
    }

    // Chuyển chế độ
    if (user.sellerStatus == 'active' || user.sellerStatus == 'approved') {
      isSellerMode.value = !isSellerMode.value;
      if (isSellerMode.value) {
        fetchSellerProducts();
        fetchSellerOrders();
        _setupOrderRealtimeListener(); // Bật lắng nghe
        _showInfoSnackbar("Chế độ", "Dashboard Người bán");
      } else {
        _ordersSubscription?.unsubscribe(); // Tắt lắng nghe
        _ordersSubscription = null;
        _showInfoSnackbar("Chế độ", "Mua hàng");
      }
    }
  }

  // --- PRODUCT ---
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
      await fetchSellerProducts(); _refreshGlobalProducts(); _showSuccessSnackbar("Thành công", "Đã thêm sản phẩm!"); return true;
    } catch (e) { _showErrorSnackbar("Lỗi", "Thêm sản phẩm thất bại: $e"); return false; } finally { isLoading.value = false; }
  }

  Future<bool> updateProduct({required String productId, required String name, required String description, required double price, required String category, required int stock, String? imageUrl, double? oldPrice, Map<String, dynamic>? specification}) async {
    try {
      isLoading.value = true;
      await _supabase.from('products').update({
        'name': name, 'description': description, 'price': price, 'old_price': oldPrice,
        'category': category, 'stock': stock, 'images': imageUrl != null ? [imageUrl] : [],
        'specification': specification ?? {},
      }).eq('id', productId);
      await fetchSellerProducts(); _refreshGlobalProducts(); _showSuccessSnackbar("Thành công", "Đã cập nhật sản phẩm!"); return true;
    } catch (e) { _showErrorSnackbar("Lỗi", "Cập nhật thất bại: $e"); return false; } finally { isLoading.value = false; }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      try { await _supabase.from('products').delete().eq('id', productId); }
      catch (fkError) { await _supabase.from('products').update({'is_active': false}).eq('id', productId); }
      myProducts.removeWhere((p) => p.id == productId); _refreshGlobalProducts(); _showSuccessSnackbar("Đã xóa", "Sản phẩm đã được xóa thành công.");
    } catch (e) { _showErrorSnackbar("Lỗi", "Không thể xóa: $e"); }
  }

  void _refreshGlobalProducts() { if (Get.isRegistered<ProductController>()) { Get.find<ProductController>().loadProducts(); } }

  // --- 4. QUẢN LÝ ĐƠN HÀNG (LOGIC LỌC ĐƠN) ---

  void fetchSellerOrders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Gọi Service lấy danh sách
      final result = await OrderSupabaseService.getSellerOrders(userId);

      // LỌC: Chỉ lấy đơn của người khác đặt (userId của đơn != userId của mình)
      final customerOrders = result.where((order) => order.userId != userId).toList();

      orders.value = customerOrders;
    } catch (e) {
      debugPrint("Error fetching orders: $e");
    }
  }

  Future<void> changeOrderStatus(Order order, OrderStatus nextStatus) async {
    try {
      isLoading.value = true;

      // Logic trừ kho
      if (order.status == OrderStatus.pending && nextStatus == OrderStatus.confirmed) {
        final stockUpdated = await OrderSupabaseService.updateProductStock(order.items);
        if (!stockUpdated) {
          Get.snackbar("Hết hàng", "Không đủ tồn kho để xác nhận đơn này!", backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red, snackPosition: SnackPosition.TOP);
          isLoading.value = false;
          return;
        }
      }

      final success = await OrderSupabaseService.updateOrderStatus(order.id, nextStatus.name);

      if (success) {
        _showSuccessSnackbar("Thành công", "Đã cập nhật trạng thái: ${nextStatus.name}");
        fetchSellerOrders();

        // Gửi thông báo cho User
        String msg = "";
        String title = "Cập nhật đơn hàng 🔔";
        NotificationType type = NotificationType.order;

        switch (nextStatus) {
          case OrderStatus.confirmed: msg = "Shop đã xác nhận đơn hàng #${order.orderNumber}. Đang đóng gói..."; break;
          case OrderStatus.shipping: msg = "Đơn hàng #${order.orderNumber} đã được giao vận chuyển 🚚."; type = NotificationType.delivery; break;
          case OrderStatus.delivering: msg = "Shipper đang giao đơn hàng #${order.orderNumber}."; type = NotificationType.delivery; break;
          case OrderStatus.completed: msg = "Giao hàng thành công! Cảm ơn bạn đã mua sắm."; type = NotificationType.delivery; break;
          case OrderStatus.cancelled: msg = "Đơn hàng #${order.orderNumber} đã bị hủy."; break;
          default: return;
        }

        NotificationController.sendNotification(
          receiverId: order.userId,
          title: title,
          message: msg,
          type: type,
        );

      } else {
        _showErrorSnackbar("Lỗi", "Cập nhật thất bại");
      }
    } catch (e) {
      debugPrint("Error changing order status: $e");
      _showErrorSnackbar("Lỗi", "Exception: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- HELPERS ---
  void _showSuccessSnackbar(String t, String m) => Get.rawSnackbar(title: t, message: m, backgroundColor: Colors.green, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(10), borderRadius: 10, icon: const Icon(Icons.check_circle, color: Colors.white));
  void _showErrorSnackbar(String t, String m) => Get.rawSnackbar(title: t, message: m, backgroundColor: Colors.red, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(10), borderRadius: 10, icon: const Icon(Icons.error, color: Colors.white));
  void _showInfoSnackbar(String t, String m) => Get.rawSnackbar(title: t, message: m, backgroundColor: Colors.blue, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(10), borderRadius: 10, icon: const Icon(Icons.info, color: Colors.white));
}