import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/controller/cart_controller.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/controller/address_controller.dart';
import 'package:ecomerceapp/supabase/order_supabase_services.dart';
import 'package:ecomerceapp/features/order_confirmation/screens/order_confirmation_screen.dart';

class OrderController extends GetxController {
  var allOrders = <Order>[].obs;
  var isLoading = false.obs;
  StreamSubscription<AuthState>? _authSubscription;
  final _supabase = Supabase.instance.client;

  List<Order> get activeOrders => allOrders
      .where(
        (o) =>
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled,
      )
      .toList();

  List<Order> get completedOrders =>
      allOrders.where((o) => o.status == OrderStatus.completed).toList();

  List<Order> get cancelledOrders =>
      allOrders.where((o) => o.status == OrderStatus.cancelled).toList();

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      if (session != null) {
        fetchOrders();
      }
    });
    if (_userId != null) {
      fetchOrders();
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  // Lấy danh sách đơn hàng
  Future<void> fetchOrders() async {
    if (_userId == null) return;
    try {
      isLoading.value = true;
      final orders = await OrderSupabaseService.getMyOrders(_userId!);
      allOrders.assignAll(orders);
    } catch (e) {
      print("Error fetching orders: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Hàm Đặt hàng (Gọi từ màn hình Checkout)
  Future<void> placeOrder() async {
    final userId = _userId;
    final cartController = Get.find<CartController>();
    final addressController = Get.find<AddressController>();

    // 1. Validation (Giữ nguyên)
    if (userId == null) {
      Get.snackbar("Error", "Please login to place order");
      return;
    }

    // 2. Lấy địa chỉ default
    final shippingAddress =
        addressController.addresses.firstWhereOrNull((e) => e.isDefault) ??
        addressController.addresses.first;

    try {
      isLoading.value = true; // Bắt đầu loading

      // Tạo mã đơn hàng
      final orderNumber =
          "ORD${DateTime.now().microsecondsSinceEpoch.toString().substring(8)}";
      final totalAmount = cartController.total.value;

      // 3. GỌI SERVICE (Đã fix lỗi Map CartItem)
      final success = await OrderSupabaseService.placeOrder(
        userId: userId,
        orderNumber: orderNumber,
        totalAmount: totalAmount,
        shippingAddress: shippingAddress,
        cartItems: cartController.cartItems,
      );

      // 4. XỬ LÝ KẾT QUẢ
      if (success) {
        // === TRƯỜNG HỢP THÀNH CÔNG ===

        // Dọn dẹp giỏ hàng
        await cartController.clearCart();

        // Refresh lại list đơn hàng bên tab My Orders
        fetchOrders();

        // Chuyển sang trang Xác nhận (Dùng Get.off để không quay lại được trang checkout)
        Get.off(
          () => OrderConfirmationScreen(
            orderNumber: orderNumber,
            totalAmount: totalAmount,
            isSuccess: true,
          ),
        );
      } else {
        Get.snackbar(
          "Order Failed",
          "Could not place your order. Please try again.",
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      // === TRƯỜNG HỢP LỖI CODE/CRASH ===
      print("Controller Error: $e");
      Get.snackbar(
        "Error",
        "Something went wrong: $e",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false; // Tắt loading dù thành công hay thất bại
    }
  }
}
