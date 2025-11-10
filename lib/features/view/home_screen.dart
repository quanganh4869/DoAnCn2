import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:ecomerceapp/features/view/cart_screen.dart';
import 'package:ecomerceapp/controller/theme_controller.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:ecomerceapp/features/view/widgets/sale_banner.dart';
import 'package:ecomerceapp/features/view/widgets/product_grid.dart';
import 'package:ecomerceapp/features/view/widgets/category_chips.dart';
import 'package:ecomerceapp/features/view/widgets/custom_search_bar.dart';
import 'package:ecomerceapp/features/view/widgets/all_products_screen.dart';
import 'package:ecomerceapp/features/notification/utils/notification_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage("assets/images/intro1.png"),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello ...",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        "Good Moring",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Get.to(() => NotificationScreen()),
                    icon: Icon(Icons.notification_add_outlined),
                  ),
                  IconButton(
                    onPressed: () => Get.to(() => CartScreen(cartItems: [])),
                    icon: Icon(Icons.shopping_bag_outlined),
                  ),

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
                  Text(
                    "Popular Product",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Get.to(() => AllProductsScreen()),
                    child: const Text("See all", style: TextStyle()),
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
