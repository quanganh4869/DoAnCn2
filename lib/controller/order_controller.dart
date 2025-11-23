import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/controller/cart_controller.dart';
import 'package:ecomerceapp/controller/address_controller.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/supabase/order_supabase_services.dart';
import 'package:ecomerceapp/features/order_confirmation/screens/order_confirmation_screen.dart';


class OrderController extends GetxController {
  final _supabase = Supabase.instance.client;

  var allOrders = <Order>[].obs;
  var isLoading = false.obs;

  StreamSubscription<AuthState>? _authSubscription;

  String? get _userId => _supabase.auth.currentUser?.id;

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

  Future<void> placeOrder() async {
    final userId = _userId;
    final cartController = Get.find<CartController>();
    final addressController = Get.isRegistered<AddressController>()
        ? Get.find<AddressController>()
        : Get.put(AddressController());

    if (userId == null) {
      Get.snackbar("Error", "Please login to place order");
      return;
    }

    if (cartController.cartItems.isEmpty) {
      Get.snackbar("Error", "Cart is empty");
      return;
    }

    if (addressController.addresses.isEmpty) {
      Get.snackbar("Error", "Please add shipping address");
      return;
    }

    final shippingAddress = addressController.addresses.firstWhereOrNull((e) => e.isDefault)
                            ?? addressController.addresses.first;

    try {
      isLoading.value = true;
      final orderNumber = "ORD${DateTime.now().microsecondsSinceEpoch.toString().substring(8)}";
      final totalAmount = cartController.total.value;

      final success = await OrderSupabaseService.placeOrder(
        userId: userId,
        orderNumber: orderNumber,
        totalAmount: totalAmount,
        shippingAddress: shippingAddress,
        cartItems: cartController.cartItems,
      );

      if (success) {
        await cartController.clearCart();
        await fetchOrders();
        Get.off(() => OrderConfirmationScreen(
          orderNumber: orderNumber,
          totalAmount: totalAmount,
          isSuccess: true,
        ));
      } else {
        Get.to(() => OrderConfirmationScreen(
          orderNumber: "ERR",
          totalAmount: 0,
          isSuccess: false,
        ));
      }
    } catch (e) {
      print("Place order error: $e");
      Get.snackbar("Error", "Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- TÍNH NĂNG MỚI: XÓA ĐƠN HÀNG ---
  Future<void> deleteOrder(String orderId) async {
    try {
      isLoading.value = true;

      // Xóa trong Database
      // Lưu ý: Do có khóa ngoại (FK) ở order_items, bạn cần chắc chắn DB set "ON DELETE CASCADE"
      // Nếu chưa set cascade, bạn phải xóa order_items trước.
      // Ở đây giả định Supabase đã config cascade hoặc ta xóa bảng cha.

      // Xóa items trước cho an toàn (nếu DB chưa config cascade)
      await _supabase.from('order_items').delete().eq('order_id', orderId);
      // Xóa order master
      await _supabase.from('orders').delete().eq('id', orderId);

      // Cập nhật UI Local
      allOrders.removeWhere((order) => order.id == orderId);

      Get.snackbar(
        "Success",
        "Order deleted successfully",
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        snackPosition: SnackPosition.TOP
      );
    } catch (e) {
      print("Delete order error: $e");
      Get.snackbar(
        "Error",
        "Failed to delete order. Please try again.",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }
}