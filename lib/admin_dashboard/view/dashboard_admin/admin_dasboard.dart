import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/features/view/signin_screen.dart';
import 'package:ecomerceapp/admin_dashboard/view/adminSetting.dart';
import 'package:ecomerceapp/admin_dashboard/view/adminHomePage.dart';
import 'package:ecomerceapp/admin_dashboard/controller/admin_controller.dart';
import 'package:ecomerceapp/admin_dashboard/view/user_admin/AdminUserManagementScreen.dart';
import 'package:ecomerceapp/admin_dashboard/view/product_admin/AdminProductManagementScreen.dart';
import 'package:ecomerceapp/admin_dashboard/view/category_admin/adminCategoryManagementScreen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.put(AdminController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            _getPageTitle(controller.currentPage.value, controller),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              if (Get.isRegistered<AuthController>()) {
                Get.find<AuthController>().logout();
              }
              Get.offAll(() => SigninScreen());
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, controller),
      body: Obx(() {
        return _getPageContent(controller.currentPage.value);
      }),
    );
  }

  Widget _getPageContent(AdminPage page) {
    switch (page) {
      case AdminPage.dashboard:
        return AdminHomePage();
      case AdminPage.userManagement:
        return AdminUserManagementScreen();
      case AdminPage.productManagement:
        return Adminproductmanagementscreen();
      case AdminPage.categoryManagement:
        return AdminCategoryManagementScreen();
      case AdminPage.settings:
        return AdminSettingsScreen();
      default:
        return Center(child: Text("Welcome, Admin!"));
    }
  }

  String _getPageTitle(AdminPage page, AdminController controller) {
    switch (page) {
      case AdminPage.dashboard:
        return "Dashboard Overview";
      case AdminPage.userManagement:
        return "User Management";
      case AdminPage.productManagement:
        return "Product Management";
      case AdminPage.categoryManagement:
        return "Category Management";
      case AdminPage.settings:
        return "Settings";
      default:
        return "Admin Panel";
    }
  }

  Widget _buildDrawer(BuildContext context, AdminController controller) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          _buildDrawerItem(
            context,
            controller,
            AdminPage.dashboard,
            Icons.dashboard,
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
            child: Text(
              "MANAGEMENT",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          _buildDrawerItem(
            context,
            controller,
            AdminPage.productManagement,
            Icons.inventory,
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            controller,
            AdminPage.categoryManagement,
            Icons.category,
          ),

          const Divider(),
          _buildDrawerItem(
            context,
            controller,
            AdminPage.userManagement,
            Icons.people,
          ),

          const Divider(),
          _buildDrawerItem(
            context,
            controller,
            AdminPage.settings,
            Icons.settings,
          ),
        ],
      ),
    );
  }

  // FIX: Ensure the first parameter is explicitly `BuildContext`
  Widget _buildDrawerItem(
    BuildContext context,
    AdminController controller,
    AdminPage page,
    IconData icon, {
    int badgeCount = 0,
    bool highlightBadge = false,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(_getPageTitle(page, controller).split('(').first.trim()),
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: highlightBadge ? Colors.red : Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : null,
      selected: controller.currentPage.value == page,
      // Uses Theme.of(context) which requires BuildContext
      selectedColor: Theme.of(context).primaryColor,
      onTap: () {
        controller.navigateTo(page);
        Get.back(); // Close drawer
      },
    );
  }
}
