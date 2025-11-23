import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/features/view/cart_screen.dart';
import 'package:ecomerceapp/controller/cart_controller.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/controller/theme_controller.dart';
import 'package:ecomerceapp/features/view/widgets/sale_banner.dart';
import 'package:ecomerceapp/features/view/widgets/product_grid.dart';
import 'package:ecomerceapp/features/view/widgets/category_chips.dart';
import 'package:ecomerceapp/features/view/widgets/custom_search_bar.dart';
import 'package:ecomerceapp/features/view/widgets/all_products_screen.dart';
import 'package:ecomerceapp/features/notification/view/notification_screen.dart';
import 'package:ecomerceapp/features/notification/controller/notification_controller.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final AuthController authController = Get.put(AuthController());
  final CartController cartController = Get.put(CartController());
  // 1. Inject Notification Controller để lấy số lượng unread
  final NotificationController notificationController = Get.put(NotificationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Obx(() {
                    final avatarUrl = authController.userAvatar.value.isNotEmpty
                        ? authController.userAvatar.value
                        : AuthController.defaultAvatar;
                    return CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(avatarUrl),
                    );
                  }),
                  const SizedBox(width: 12),

                  // Greeting
                  Obx(() {
                    final name = authController.userName.value.isNotEmpty
                        ? authController.userName.value
                        : "...";
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello $name",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          "Have a good day",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }),
                  const Spacer(),

                  // --- 2. NOTIFICATION ICON WITH BADGE ---
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () => Get.to(() => NotificationScreen()),
                        icon: const Icon(Icons.notifications_outlined),
                      ),
                      // Lắng nghe số lượng chưa đọc
                      Obx(() {
                        final count = notificationController.unreadCount.value;
                        return count > 0
                            ? Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      count > 99 ? '99+' : count.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }),
                    ],
                  ),

                  // --- CART ICON WITH BADGE ---
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () => Get.to(() => CartScreen()),
                        icon: const Icon(Icons.shopping_bag_outlined),
                      ),
                      Obx(
                        () => cartController.cartItems.isEmpty
                            ? const SizedBox.shrink()
                            : Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      cartController.cartItems.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),

                  // 3. Icon Theme
                  GetBuilder<ThemeController>(
                    builder: (controller) => IconButton(
                      onPressed: () => controller.toggleTheme(),
                      icon: Icon(
                        controller.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const CustomSearchBar(),
            const CategoryChips(),
            const SaleBanner(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Popular Product",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Get.to(() => AllProductsScreen()),
                    child: const Text("See all"),
                  ),
                ],
              ),
            ),
            const Expanded(child: ProductGrid()),
          ],
        ),
      ),
    );
  }
}