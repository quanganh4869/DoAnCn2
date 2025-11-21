import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/controller/cart_controller.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/controller/address_controller.dart';
import 'package:ecomerceapp/supabase/order_supabase_services.dart';


class OrderController extends GetxController {
  // Sử dụng Order thay vì Order cũ
  var allOrders = <Order>[].obs;
  var isLoading = false.obs;

  // Active: Bao gồm Pending, Confirmed, Shipping, Delivering (Tất cả chưa hoàn thành/hủy)
  List<Order> get activeOrders =>
      allOrders.where((o) =>
        o.status != OrderStatus.completed &&
        o.status != OrderStatus.cancelled
      ).toList();

  // Completed: Chỉ đơn giao thành công
  List<Order> get completedOrders =>
      allOrders.where((o) => o.status == OrderStatus.completed).toList();

  // Cancelled: Đơn hủy hoặc thất bại
  List<Order> get cancelledOrders =>
      allOrders.where((o) => o.status == OrderStatus.cancelled).toList();

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  // Lấy danh sách đơn hàng
  Future<void> fetchOrders() async {
    if (_userId == null) return;
    try {
      isLoading.value = true;
      // Gọi hàm từ OrderSupabaseService
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

    // 1. Validation cơ bản
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

    // 2. Lấy địa chỉ (Ưu tiên Default, nếu không thì lấy cái đầu tiên)
    final shippingAddress = addressController.addresses.firstWhereOrNull((e) => e.isDefault)
                            ?? addressController.addresses.first;

    try {
      isLoading.value = true;

      // Tạo mã đơn hàng: ORD + timestamp
      final orderNumber = "ORD${DateTime.now().microsecondsSinceEpoch.toString().substring(8)}";

      // 3. Gọi Service đặt hàng
      final success = await OrderSupabaseService.placeOrder(
        userId: userId,
        orderNumber: orderNumber,
        totalAmount: cartController.total.value,
        shippingAddress: shippingAddress,
        cartItems: cartController.cartItems,
      );

      if (success) {
        // 4. Xử lý sau khi thành công
        await cartController.clearCart(); // Xóa giỏ hàng local/db
        await fetchOrders(); // Refresh lại list đơn hàng để thấy đơn mới ở tab Active

        Get.snackbar("Success", "Order placed successfully!");

        // Chuyển hướng (Tùy chọn: Về trang chủ hoặc trang xác nhận)
        // Get.offAllNamed('/home');
      } else {
        Get.snackbar("Error", "Failed to place order. Please try again.");
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }
}