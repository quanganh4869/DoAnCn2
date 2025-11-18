import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/seller_dasboard/controller/seller_controller.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SellerController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.currentSeller.value?.shopName ?? "Seller Dashboard")),
        actions: [
          // Nút chuyển về chế độ người mua
          TextButton.icon(
            onPressed: () {
              controller.toggleSellerMode();
              Get.back(); // Quay lại AccountScreen hoặc MainScreen
            },
            icon: const Icon(Icons.person_outline),
            label: const Text("Switch to Buyer"),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
             _buildDashboardCard(context, Icons.add_box, "Add Product", Colors.blue, () {}),
             _buildDashboardCard(context, Icons.list_alt, "My Products", Colors.orange, () {}),
             _buildDashboardCard(context, Icons.attach_money, "Earnings", Colors.green, () {}),
             _buildDashboardCard(context, Icons.local_shipping, "Orders", Colors.purple, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0,2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.h3),
          ],
        ),
      ),
    );
  }
}