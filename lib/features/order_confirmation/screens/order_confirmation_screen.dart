import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/features/myorders/view/my_order_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderNumber;
  final double totalAmount;
  final bool isSuccess;

  const OrderConfirmationScreen({
    super.key,
    required this.orderNumber,
    required this.totalAmount,
    this.isSuccess = true
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset(
                  "assets/animations/order_success.json",
                  width: 200,
                  height: 200,
                  repeat: false,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      isSuccess ? Icons.check_circle : Icons.error,
                      size: 150,
                      color: isSuccess ? Colors.green : Colors.red,
                    );
                  },
                ),

                const SizedBox(height: 32),

                Text(
                  isSuccess ? "Order confirmed" : "Order Failed",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.withColor(
                    AppTextStyles.h2,
                    isDark ? Colors.white : Colors.black,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  isSuccess
                    ? "Your order #$orderNumber has been successfully placed."
                    : "Something went wrong. Please try again.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.withColor(
                    AppTextStyles.bodyLarge,
                    isDark ? Colors.grey[400]! : Colors.grey[600]!,
                  ),
                ),

                const SizedBox(height: 48),

                ElevatedButton(
                  onPressed: () {
                    if (isSuccess) {
                      Get.off(() => MyOrderScreen());
                    } else {
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Theme.of(context).primaryColor : Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isSuccess ? "Track Order" : "Try Again",
                    style: AppTextStyles.withColor(
                      AppTextStyles.buttonMedium,
                      Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Nút Continue Shopping (FIX LỖI MẤT NAV BAR)
                TextButton(
                  onPressed: () {
                    // FIX: Dùng Get.until để back về trang gốc (MainScreen) thay vì tạo mới HomeScreen
                    // route.isFirst nghĩa là back cho đến khi gặp màn hình đầu tiên trong stack
                    Get.until((route) => route.isFirst);
                  },
                  child: Text(
                    "Continue Shopping",
                    style: AppTextStyles.withColor(
                      AppTextStyles.buttonMedium,
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}