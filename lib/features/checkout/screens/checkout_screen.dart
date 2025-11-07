import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/address_card.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/order_summary_card.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/checkout_bottom_bar.dart';
import 'package:ecomerceapp/features/checkout/screens/widgets/payment_method_card.dart';
import 'package:ecomerceapp/features/order_confirmation/screens/order_confirmation_screen.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          "CheckOut",
          style: AppTextStyles.withColor(
            AppTextStyles.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, "Shipping Address"),
            const SizedBox(height: 16),
            AddressCard(),
            const SizedBox(height: 24),
            _buildSectionTitle(context, "Payment Method"),
            PaymentMethodCard(),
            const SizedBox(height: 24),
            _buildSectionTitle(context, "Order Sumary"),
            const SizedBox(height: 16),
            OrderSummaryCard(),
            const SizedBox(height: 16),
            OrderSummaryCard(),
          ],
        ),
      ),
      bottomNavigationBar: CheckoutBottomBar(
        totalAmount: 40.32,
        onPlaceOrder: (){
          final orderNumber = "ORD${DateTime.now().microsecondsSinceEpoch.toString().substring(7)}";
          Get.to(()=> OrderConfirmationScreen(
            orderNumber: orderNumber,
            totalAmount: 36.36,
          ));
        },
      ),
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
}
