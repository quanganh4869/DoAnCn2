import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/cart_controller.dart';
import 'package:ecomerceapp/controller/order_controller.dart';
import 'package:ecomerceapp/controller/address_controller.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/order_summary_card.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/checkout_bottom_bar.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/payment_method_card.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/checkout_address_card.dart';

class CheckoutScreen extends StatelessWidget {
  CheckoutScreen({super.key});

  final CartController cartController = Get.find<CartController>();
  final AddressController addressController = Get.put(AddressController());
  final OrderController orderController = Get.put(OrderController());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            ),
            title: Text(
              "Thanh toán",
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
                _buildSectionTitle(context, "Địa chỉ"),
                const SizedBox(height: 16),
                CheckoutAddressCard(),
                const SizedBox(height: 24),

                _buildSectionTitle(context, "Phương thúc thanh toán"),
                const SizedBox(height: 16),
                const PaymentMethodCard(),
                const SizedBox(height: 24),

                _buildSectionTitle(context, "Tổng sản phẩm"),
                const SizedBox(height: 16),
                OrderSummaryCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          bottomNavigationBar: Obx(() => CheckoutBottomBar(
            totalAmount: cartController.total.value,
            onPlaceOrder: orderController.isLoading.value
                ? () {}
                : () => _handlePlaceOrder(),
          )),
        ),
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
    if (addressController.addresses.isEmpty) {
      Get.snackbar(
        "Thiếu địa chỉ",
        "Vui lòng thêm địa chỉ",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.TOP
      );
      return;
    }

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