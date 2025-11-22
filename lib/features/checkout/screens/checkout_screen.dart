import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/cart_controller.dart';
import 'package:ecomerceapp/controller/address_controller.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/order_summary_card.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/checkout_bottom_bar.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/payment_method_card.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/checkout_address_card.dart';
import 'package:ecomerceapp/controller/order_controller.dart'; // <--- 1. Import OrderController

class CheckoutScreen extends StatelessWidget {
  CheckoutScreen({super.key});

  final CartController cartController = Get.find<CartController>();
  final AddressController addressController = Get.put(AddressController());
  final OrderController orderController = Get.put(OrderController()); // <--- 2. Khởi tạo Controller

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sử dụng Stack để hiển thị Loading đè lên màn hình khi đang xử lý
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            ),
            title: Text(
              "Checkout",
              style: AppTextStyles.withColor(
                AppTextStyles.h3,
                isDark ? Colors.white : Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, "Shipping Address"),
                const SizedBox(height: 16),
                CheckoutAddressCard(),
                const SizedBox(height: 24),

                _buildSectionTitle(context, "Payment Method"),
                const SizedBox(height: 16),
                const PaymentMethodCard(),
                const SizedBox(height: 24),

                _buildSectionTitle(context, "Order Summary"),
                const SizedBox(height: 16),
                OrderSummaryCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Bottom Bar
          bottomNavigationBar: Obx(() => CheckoutBottomBar(
            totalAmount: cartController.total.value,
            // Khi đang loading thì không cho bấm nút (hoặc bạn có thể truyền biến isLoading vào widget này nếu nó hỗ trợ)
            onPlaceOrder: orderController.isLoading.value
                ? () {} // Nếu đang load thì disable nút bấm
                : () => _handlePlaceOrder(),
          )),
        ),

        // <--- 3. Màn hình Loading Overlay
        Obx(() {
          if (orderController.isLoading.value) {
            return Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: AppTextStyles.withColor(
        AppTextStyles.h3,
        isDark ? Colors.white : Colors.black,
      ),
    );
  }

  void _handlePlaceOrder() {
    // Validation Address
    if (addressController.addresses.isEmpty) {
      Get.snackbar(
        "Missing Address",
        "Please add a shipping address before placing order.",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.TOP
      );
      return;
    }

    // Validation Cart
    if (cartController.cartItems.isEmpty) {
      Get.snackbar(
        "Empty Cart",
        "Your cart is empty.",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    orderController.placeOrder();
  }
}