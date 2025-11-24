import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/features/notification/view/notification_screen.dart';
import 'package:ecomerceapp/seller_dasboard/view/order_seller/manage_orders_screen.dart';
import 'package:ecomerceapp/features/notification/controller/notification_controller.dart';
import 'package:ecomerceapp/seller_dasboard/view/product_seller/manage_products_screen.dart';

// Import Notification components

class SellerMainScreen extends StatelessWidget {
  const SellerMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    // Inject NotificationController to listen to unread counts
    final notificationController = Get.put(NotificationController());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kênh Người Bán"),
        centerTitle: true,
        actions: [
          // --- NOTIFICATION ICON WITH SELLER BADGE ---
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Navigate to Notification Screen with 'seller' filter
                  Get.to(() => NotificationScreen(filterRole: 'seller'));
                },
              ),
              // Badge for Seller Unread Count
              Obx(() {
                final count = notificationController.unreadSellerCount;
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
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Greeting
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(
                      authController.userProfile?.userImage ??
                      "https://cdn-icons-png.flaticon.com/512/1995/1995574.png"
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authController.userProfile?.storeName ?? "My Shop",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Chúc bạn buôn may bán đắt!",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text("Quản lý", style: AppTextStyles.h3),
            const SizedBox(height: 16),

            // Grid Menu
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildDashboardItem(
                  context,
                  icon: Icons.list_alt_rounded,
                  label: "Đơn hàng",
                  color: Colors.green,
                  onTap: () {
                    Get.to(() => ManageOrdersScreen());
                  },
                ),
                _buildDashboardItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  label: "Sản phẩm",
                  color: Colors.orange,
                  onTap: () {
                    Get.to(() => ManageProductsScreen());
                  },
                ),
                _buildDashboardItem(
                  context,
                  icon: Icons.analytics_outlined,
                  label: "Thống kê",
                  color: Colors.purple,
                  onTap: () {
                    // Get.to(() => AnalyticsScreen());
                  },
                ),
                _buildDashboardItem(
                  context,
                  icon: Icons.settings_outlined,
                  label: "Cài đặt Shop",
                  color: Colors.grey,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.logout),
                label: const Text("Quay lại chế độ Mua hàng"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: isDark ? Colors.white54 : Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}