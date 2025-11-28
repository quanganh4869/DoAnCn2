import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/features/view/signin_screen.dart';
import 'package:ecomerceapp/features/view/setting_screen.dart';
import 'package:ecomerceapp/seller_dasboard/view/seller_signup.dart';
import 'package:ecomerceapp/features/myorders/view/my_order_screen.dart';
import 'package:ecomerceapp/seller_dasboard/view/seller_main_screen.dart';
import 'package:ecomerceapp/seller_dasboard/controller/seller_controller.dart';
import 'package:ecomerceapp/admin_dashboard/view/dashboard_admin/admin_dasboard.dart';
import 'package:ecomerceapp/features/edit_profile/views/screens/edit_profile_screen.dart';
import 'package:ecomerceapp/features/shippingaddress/widgets/shipping_address_screen.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({super.key});

  final SellerController sellerController = Get.put(SellerController());
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Cài đặt người dùng",
          style: AppTextStyles.withColor(
            AppTextStyles.bodyLarge,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => SettingScreen()),
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await authController.loadUserFromSession();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileSection(context),
              const SizedBox(height: 24),
              _buildMenuSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final user = authController.userProfile;
      String displayName = user?.fullName ?? "User Name";
      final status = user?.sellerStatus ?? 'none';
      if (status == 'active' || status == 'approved') {
        displayName += " (Seller)";
      } else if (status == 'pending') {
        displayName += " (Pending)";
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.grey[200],
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: (user?.userImage != null && user!.userImage!.isNotEmpty)
                  ? NetworkImage(user!.userImage!)
                  : const AssetImage('assets/images/user_avatar.jpg') as ImageProvider,
            ),
            const SizedBox(height: 16),

            Text(
              displayName,
              textAlign: TextAlign.center,
              style: AppTextStyles.withColor(
                AppTextStyles.h2,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              user?.email ?? "email@example.com",
              style: AppTextStyles.withColor(
                AppTextStyles.bodySmall,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Get.to(() => EditProfileScreen()),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                side: BorderSide(color: isDark ? Colors.white70 : Colors.black12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                "Edit Profile",
                style: AppTextStyles.withColor(
                  AppTextStyles.buttonMedium,
                  Theme.of(context).textTheme.bodyLarge!.color!,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMenuSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            Icons.shopping_bag_outlined,
            "My Orders",
            () => Get.to(() => MyOrderScreen()),
          ),
          _buildMenuItem(
            context,
            Icons.location_on_outlined,
            "Shipping Addresses",
            () => Get.to(() => ShippingAddressScreen()),
          ),

          Obx(() {
            final user = authController.userProfile;
            final status = user?.sellerStatus ?? 'none';

            switch (status) {
              case 'active':
              case 'approved':
                return _buildCustomMenuItem(
                  context,
                  Icons.store_mall_directory,
                  "Switch to Seller Mode",
                  () {
                    sellerController.toggleSellerMode();
                    Get.to(() => const SellerMainScreen());
                  },
                  textColor: Colors.green,
                );

              case 'pending':
                return _buildCustomMenuItem(
                  context,
                  Icons.hourglass_top_rounded,
                  "Application Pending",
                  () => Get.snackbar(
                    "Đang chờ duyệt",
                    "Hồ sơ của bạn đang được Admin xem xét.",
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    colorText: Colors.deepOrange
                  ),
                  textColor: Colors.orange,
                );

              case 'none':
              case 'rejected':
              default:
                return _buildCustomMenuItem(
                  context,
                  Icons.storefront,
                  "Register as Seller",
                  () {
                     if (status == 'rejected') {
                        Get.snackbar(
                          "Thông báo",
                          "Đơn đăng ký trước đó đã bị từ chối. Vui lòng cập nhật lại thông tin.",
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                          colorText: Colors.red
                        );
                     }
                     Get.to(() => const SellerSignup());
                  },
                );
            }
          }),

          // Kiểm tra quyền Admin
          GetBuilder<AuthController>(
            builder: (controller) {
              if (controller.userProfile?.role?.trim().toLowerCase() == 'admin') {
                return _buildMenuItem(
                  context,
                  Icons.admin_panel_settings,
                  "Admin Dashboard",
                  () => Get.to(() => AdminDashboardScreen()),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          _buildMenuItem(
            context,
            Icons.logout,
            "Logout",
            () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return _buildCustomMenuItem(context, icon, title, onTap);
  }

  Widget _buildCustomMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color? textColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? Theme.of(context).primaryColor),
        title: Text(
          title,
          style: AppTextStyles.withColor(
            AppTextStyles.bodyMedium,
            textColor ?? Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout, size: 32, color: isDark ? Colors.redAccent : Colors.red),
            ),
            const SizedBox(height: 24),
            Text(
              "Are you sure you want to logout?",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final AuthController authController = Get.find<AuthController>();
                      authController.logout();
                      sellerController.resetState();
                      Get.offAll(() => SigninScreen());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Logout", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}