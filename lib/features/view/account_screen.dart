import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/features/view/signin_screen.dart';
import 'package:ecomerceapp/features/view/setting_screen.dart';
import 'package:ecomerceapp/seller_dasboard/view/seller_signup.dart';
import 'package:ecomerceapp/admin_dashboard/view/admin_dasboard.dart';
import 'package:ecomerceapp/seller_dasboard/view/seller_dasboard_screen.dart';
import 'package:ecomerceapp/seller_dasboard/controller/seller_controller.dart';
import 'package:ecomerceapp/features/myorders/view/screens/my_order_screen.dart';
import 'package:ecomerceapp/features/edit_profile/views/screens/edit_profile_screen.dart';
import 'package:ecomerceapp/features/shippingaddress/widgets/shipping_address_screen.dart';
class AccountScreen extends StatelessWidget {
  AccountScreen({super.key});
  
  final SellerController sellerController = Get.put(SellerController());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Account settings",
          style: AppTextStyles.withColor(
            AppTextStyles.h3,
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileSection(context),
            const SizedBox(height: 24),
            _buildMenuSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Lấy thông tin từ AuthController để hiển thị dynamic
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = authController.userProfile;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.grey[200],
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Column(
          children: [
             CircleAvatar(
              radius: 50,
              backgroundImage: user?.userImage != null 
                  ? NetworkImage(user!.userImage!) 
                  : const AssetImage('assets/images/user_avatar.jpg') as ImageProvider,
            ),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? "User Name",
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMenuItem(context, Icons.shopping_bag_outlined, "My Orders", 
              () => Get.to(() => MyOrderScreen())),
              
          _buildMenuItem(context, Icons.location_on_outlined, "Shipping Addresses", 
              () => Get.to(() => ShippingAddressScreen())),
          
          // NGƯỜI BÁN
          Obx(() {
            final seller = sellerController.currentSeller.value;
            
            // Mặc định: Chưa đăng ký
            String title = "Register as Seller";
            IconData icon = Icons.storefront;
            VoidCallback onTap = () => Get.to(() => SellerRegistrationScreen());
            Color? textColor;

            if (seller != null) {
              if (seller.status == 'pending') {
                title = "Application Pending";
                icon = Icons.hourglass_empty;
                textColor = Colors.orange;
                onTap = () => Get.snackbar("Info", "Your application is under review by admin.");
              } else if (seller.status == 'approved') {
                title = "Switch to Seller Mode";
                icon = Icons.store;
                textColor = Colors.green;
                onTap = () {
                  sellerController.toggleSellerMode();
                  Get.to(() => const SellerDashboardScreen());
                };
              } else if (seller.status == 'rejected') {
                title = "Application Rejected";
                icon = Icons.error_outline;
                textColor = Colors.red;
                onTap = () => Get.snackbar("Info", "Your application was rejected. Please contact support.");
              }
            }

            return _buildCustomMenuItem(context, icon, title, onTap, textColor: textColor);
          }),

          GetBuilder<AuthController>(
            builder: (controller) {
              final role = controller.userProfile?.role;
              
              if (role == 'admin') {
                return _buildMenuItem(
                  context, 
                  Icons.admin_panel_settings, 
                  "Admin Dashboard", 
                  () => Get.to(() => AdminDashboardScreen())
                );
              }
              return const SizedBox.shrink(); 
            },
          ),
          

          _buildMenuItem(context, Icons.logout, "Logout", 
              () => _showLogoutDialog(context)),
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
        // boxShadow: [
        //   BoxShadow(https://www.facebook.com/marketplace/?ref=bookmark
        //     color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        //     blurRadius: 8,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
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
        trailing: Icon(Icons.chevron_right, color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, size: 32, color: isDark ? Colors.white : Colors.red),
            ),
            const SizedBox(height: 24),
            Text(
              "Are you sure you want to logout?",
              textAlign: TextAlign.center,
              style: AppTextStyles.withColor(AppTextStyles.bodyMedium, isDark ? Colors.grey[400]! : Colors.grey[600]!),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Cancel", style: AppTextStyles.withColor(AppTextStyles.buttonMedium, Theme.of(context).textTheme.bodyLarge!.color!)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final AuthController authController = Get.find<AuthController>();
                      authController.logout();
                      Get.offAll(() => SigninScreen());
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Logout", style: AppTextStyles.withColor(AppTextStyles.buttonMedium, Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}