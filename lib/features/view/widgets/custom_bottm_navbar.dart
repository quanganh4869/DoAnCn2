import 'package:ecomerceapp/controller/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class CustomBottmNavbar extends StatelessWidget {
  const CustomBottmNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navigationController = Get.find<NavigationController>();
    return Obx(
      () => BottomNavigationBar(
        currentIndex: navigationController.currentIndex.value,
        onTap: (index) => navigationController.changeIndex(index),
        items:[
          BottomNavigationBarItem(icon: Icon(
            Icons.home_max_outlined),
            label:"Home",
          ),
          BottomNavigationBarItem(icon: Icon(
            Icons.shopping_bag_outlined),
            label:"Shopping",
          ),
          BottomNavigationBarItem(icon: Icon(
            Icons.favorite_outline),
            label:"Wishlist",
          ),
          BottomNavigationBarItem(icon: Icon(
            Icons.person_outline),
            label:"Account",
          ),
      ]
      )
    );
  }
}