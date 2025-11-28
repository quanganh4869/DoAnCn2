import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/features/view/chat_screen.dart';
import 'package:ecomerceapp/features/view/cart_screen.dart';
import 'package:ecomerceapp/controller/cart_controller.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/controller/theme_controller.dart';
import 'package:ecomerceapp/controller/product_controller.dart';
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
  final NotificationController notificationController = Get.put(
    NotificationController(),
  );
  final ProductController productController = Get.put(ProductController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Obx(() {
                      final avatarUrl =
                          authController.userAvatar.value.isNotEmpty
                          ? authController.userAvatar.value
                          : AuthController.defaultAvatar;
                      return CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(avatarUrl),
                      );
                    }),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Obx(() {
                        final name = authController.userName.value.isNotEmpty
                            ? authController.userName.value
                            : "...";
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Xin chào $name",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              "Chúc một ngày tốt lành",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      }),
                    ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildNotificationIcon(),
                        _buildCartIcon(),
                        _buildThemeIcon(),
                      ],
                    ),
                  ],
                ),
              ),

              const CustomSearchBar(),
              const CategoryChips(),
              const SaleBanner(),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(
                      () => Text(
                        productController.isPersonalized.value
                            ? "Đề xuất cho bạn"
                            : "Sản phẩm thịnh hành",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.to(() => AllProductsScreen()),
                      child: const Text("Xem tất cả"),
                    ),
                  ],
                ),
              ),

              const ProductGrid(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => AIChatScreen()),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        IconButton(
          onPressed: () => Get.to(() => NotificationScreen(filterRole: 'user')),
          icon: const Icon(Icons.notifications_outlined),
        ),
        Obx(() {
          final count = notificationController.unreadUserCount;
          return count > 0
              ? Positioned(right: 8, top: 8, child: _buildBadge(count))
              : const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildCartIcon() {
    return Stack(
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
                  child: _buildBadge(cartController.cartItems.length),
                ),
        ),
      ],
    );
  }

  Widget _buildThemeIcon() {
    return GetBuilder<ThemeController>(
      builder: (controller) => IconButton(
        onPressed: () => controller.toggleTheme(),
        icon: Icon(controller.isDarkMode ? Icons.light_mode : Icons.dark_mode),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
    );
  }
}
