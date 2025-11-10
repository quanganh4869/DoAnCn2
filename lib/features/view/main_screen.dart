import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:ecomerceapp/features/view/home_screen.dart';
import 'package:ecomerceapp/controller/theme_controller.dart';
import 'package:ecomerceapp/features/view/account_screen.dart';
import 'package:ecomerceapp/features/view/shopping_screen.dart';
import 'package:ecomerceapp/features/view/wishlist_screen.dart';
import 'package:ecomerceapp/controller/navigation_controller.dart';
import 'package:ecomerceapp/features/view/widgets/custom_bottm_navbar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navigationController = Get.find<NavigationController>();
    return GetBuilder<ThemeController>(
      builder: (ThemeController)=> Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Obx(
            ()=> IndexedStack(
              key: ValueKey(navigationController.currentIndex.value),
              index: navigationController.currentIndex.value,
              children: [
                HomeScreen(),
                ShoppingScreen(),
                WishlistScreen(products: [],),
                AccountScreen(),
              ],
            )
          ),
          ),
          bottomNavigationBar: CustomBottmNavbar(),
      ),
      
    );
  }
}