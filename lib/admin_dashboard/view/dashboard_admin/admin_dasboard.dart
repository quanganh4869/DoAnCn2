import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/features/view/signin_screen.dart';
import 'package:ecomerceapp/admin_dashboard/controller/admin_controller.dart';
import 'package:ecomerceapp/admin_dashboard/view/dashboard_admin/adminHomePage.dart';
import 'package:ecomerceapp/admin_dashboard/view/user_admin/AdminUserManagementScreen.dart';
import 'package:ecomerceapp/admin_dashboard/view/product_admin/AdminProductManagementScreen.dart';
import 'package:ecomerceapp/admin_dashboard/view/category_admin/adminCategoryManagementScreen.dart';


class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.put(AdminController());
    final AuthController authController = Get.find<AuthController>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Obx(() => Text(
          _getPageTitle(controller.currentPage.value),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        )),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              tooltip: "Đăng xuất",
              onPressed: () => _handleLogout(),
            ),
          ),
        ],
      ),

      drawer: _buildModernDrawer(context, controller, authController),

      body: Obx(() {
        return Container(
          padding: const EdgeInsets.all(0),
          child: _getPageContent(controller.currentPage.value),
        );
      }),
    );
  }

  Widget _getPageContent(AdminPage page) {
    switch (page) {
      case AdminPage.dashboard: return AdminHomePage();
      case AdminPage.userManagement: return AdminUserManagementScreen();
      case AdminPage.productManagement: return AdminProductManagementScreen();
      case AdminPage.categoryManagement: return AdminCategoryManagementScreen();
      default: return const Center(child: Text("Page not found"));
    }
  }

  String _getPageTitle(AdminPage page) {
    switch (page) {
      case AdminPage.dashboard: return "Màn hình chính";
      case AdminPage.userManagement: return "Quản lí người dùng";
      case AdminPage.productManagement: return "Quản lí sản phẩm";
      case AdminPage.categoryManagement: return "Quản lí danh mục";
      default: return "Admin Panel";
    }
  }

  void _handleLogout() {
    Get.defaultDialog(
      title: "Logout",
      middleText: "Are you sure you want to logout?",
      textConfirm: "Logout",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().logout();
        }
        Get.offAll(() => SigninScreen());
      },
    );
  }


  Widget _buildModernDrawer(BuildContext context, AdminController controller, AuthController authController) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Drawer(
      elevation: 0,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: NetworkImage(
                    authController.userAvatar.value.isNotEmpty
                        ? authController.userAvatar.value
                        : "https://cdn-icons-png.flaticon.com/512/2304/2304226.png"
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authController.userName.value,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        "Quản trị viên",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              children: [
                _buildDrawerItem(context, controller, page: AdminPage.dashboard, icon: Icons.dashboard_rounded, label: "Tổng quan"),
                _buildSectionTitle("Quản lý"),
                _buildDrawerItem(context, controller, page: AdminPage.productManagement, icon: Icons.inventory_2_rounded, label: "Sản phẩm"),
                _buildDrawerItem(context, controller, page: AdminPage.categoryManagement, icon: Icons.category_rounded, label: "Danh mục"),
                Obx(() {
                  int pendingCount = controller.pendingRequests.length;
                  return _buildDrawerItem(context, controller, page: AdminPage.userManagement, icon: Icons.people_alt_rounded, label: "Người dùng", badgeCount: pendingCount);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    AdminController controller, {
    required AdminPage page,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    return Obx(() {
      final bool isSelected = controller.currentPage.value == page;
      final primaryColor = Theme.of(context).primaryColor;

      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: () {
            controller.navigateTo(page);
            Get.back();
          },
          leading: Icon(icon, color: isSelected ? primaryColor : Colors.grey[600], size: 22),
          title: Text(label, style: TextStyle(color: isSelected ? primaryColor : Colors.grey[800], fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 14)),
          trailing: badgeCount > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  child: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              : (isSelected ? Icon(Icons.arrow_right, color: primaryColor) : null),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      );
    });
  }
}