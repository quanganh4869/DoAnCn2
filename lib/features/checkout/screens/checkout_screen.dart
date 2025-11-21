import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/cart_controller.dart';
import 'package:ecomerceapp/controller/address_controller.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/order_summary_card.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/checkout_bottom_bar.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/payment_method_card.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/checkout_address_card.dart';
import 'package:ecomerceapp/features/order_confirmation/screens/order_confirmation_screen.dart';
// Import Controllers
// Import Screens & Widgets

class CheckoutScreen extends StatelessWidget {
  CheckoutScreen({super.key});

  final CartController cartController = Get.find<CartController>();
  final AddressController addressController = Get.put(AddressController());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
            // 1. Shipping Address
            _buildSectionTitle(context, "Shipping Address"),
            const SizedBox(height: 16),
            CheckoutAddressCard(), // Đã rewrite

            const SizedBox(height: 24),

            // 2. Payment Method
            _buildSectionTitle(context, "Payment Method"),
            const SizedBox(height: 16),
            const PaymentMethodCard(), // Đã rewrite

            const SizedBox(height: 24),

            // 3. Order Summary (Tổng hợp tiền)
            _buildSectionTitle(context, "Order Summary"),
            const SizedBox(height: 16),
            OrderSummaryCard(), // Đã rewrite

            // Có thể thêm list item rút gọn ở đây nếu muốn
            // ...

            const SizedBox(height: 40), // Padding bottom tránh bị che
          ],
        ),
      ),

      // 4. Bottom Bar
      bottomNavigationBar: Obx(() => CheckoutBottomBar(
        totalAmount: cartController.total.value,
        onPlaceOrder: () => _handlePlaceOrder(),
      )),
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
    // Kiểm tra xem user đã có địa chỉ chưa
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

    // Kiểm tra giỏ hàng có trống không
    if (cartController.cartItems.isEmpty) {
      Get.snackbar(
        "Empty Cart",
        "Your cart is empty.",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    // Tạo mã đơn hàng
    final orderNumber = "ORD${DateTime.now().microsecondsSinceEpoch.toString().substring(8)}";

    // Chuyển sang trang xác nhận
    Get.to(() => OrderConfirmationScreen(
      orderNumber: orderNumber,
      totalAmount: cartController.total.value,
    ));
  }
}