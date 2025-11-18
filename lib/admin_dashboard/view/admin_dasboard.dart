import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/features/view/signin_screen.dart'; 
import 'package:ecomerceapp/admin_dashboard/view/adminHomePage.dart'; 
import 'package:ecomerceapp/admin_dashboard/controller/admin_controller.dart'; 
import 'package:ecomerceapp/admin_dashboard/view/AdminProductSalesScreen.dart'; 
import 'package:ecomerceapp/admin_dashboard/view/AdminUserManagementScreen.dart'; 
import 'package:ecomerceapp/admin_dashboard/view/adminCategoryManagementScreen.dart'; 



class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Khởi tạo Controller
    final AdminController controller = Get.put(AdminController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          _getPageTitle(controller.currentPage.value, controller),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Get.find<AuthController>().logout();
              Get.offAll(() => SigninScreen());
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, controller),
      
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return _getPageContent(controller.currentPage.value);
      }),
    );
  }

  Widget _getPageContent(AdminPage page) {
    switch (page) {
      case AdminPage.dashboard:
        return Adminhomepage(); 
      case AdminPage.userManagement:
        return AdminUserManagementScreen();
      case AdminPage.productManagement:
        return AdminProductSalesScreen();
      case AdminPage.categoryManagement:
        return Admincategorymanagementscreen(); 
      case AdminPage.settings:
        return  AdminSettingsScreen(); 
      default:
        return  Center(child: Text("Welcome, Admin!"));
    }
  }

  // --- HÀM XÁC ĐỊNH TIÊU ĐỀ (Giữ nguyên logic) ---
  String _getPageTitle(AdminPage page, AdminController controller) {
    switch (page) {
      case AdminPage.dashboard: return "Dashboard Overview";
      case AdminPage.sellerRequests: 
        return "Seller Applications (${controller.pendingRequests.length})";
      case AdminPage.userManagement: return "User Management";
      case AdminPage.productManagement: return "Product Management";
      case AdminPage.categoryManagement: return "Category Management";
      case AdminPage.settings: // <--- ĐÃ FIX LỖI Ở ĐÂY
        return "Settings";
      default: return "Admin Panel";
    }
  }

  // --- XÂY DỰNG THANH DRAWER MENU (Đã fix lỗi Settings) ---
  Widget _buildDrawer(BuildContext context, AdminController controller) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.redAccent),
            child: Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          _buildDrawerItem(controller, AdminPage.dashboard, Icons.dashboard),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
            child: Text("ECOMMERCE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          _buildDrawerItem(controller, AdminPage.productManagement, Icons.inventory),
          _buildDrawerItem(controller, AdminPage.categoryManagement, Icons.category),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
            child: Text("USERS & OTHERS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          _buildDrawerItem(controller, AdminPage.userManagement, Icons.people),
          
          // Mục duyệt người bán (Có badge thông báo)
          Obx(() => _buildDrawerItem(
            controller, 
            AdminPage.sellerRequests, 
            Icons.store_mall_directory,
            badgeCount: controller.pendingRequests.length,
          )),
          
          const Divider(),
          _buildDrawerItem(controller, AdminPage.settings, Icons.settings), // Mục Settings đã được fix
        ],
      ),
    );
  }

  // --- WIDGET RIÊNG CHO TỪNG ITEM TRONG DRAWER (Giữ nguyên) ---
  Widget _buildDrawerItem(AdminController controller, AdminPage page, IconData icon, {int badgeCount = 0}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(_getPageTitle(page, controller).split('(').first.trim()),
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : null,
      selected: controller.currentPage.value == page,
      onTap: () {
        controller.navigateTo(page);
        Get.back(); // Đóng drawer sau khi chọn
      },
    );
  }
}

// Giả lập class SettingsScreen để code compile
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Admin Settings"));
  }
}