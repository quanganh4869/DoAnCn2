import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/models/user_profile.dart';
import 'package:ecomerceapp/admin_dashboard/controller/admin_controller.dart';
import 'package:ecomerceapp/admin_dashboard/view/user_admin/user_detail_screen.dart';
import 'package:ecomerceapp/admin_dashboard/view/user_admin/seller_request_card.dart';

class AdminUserManagementScreen extends StatelessWidget {
  AdminUserManagementScreen({super.key});
  final AdminController controller = Get.find<AdminController>();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchPendingSellers();
      controller.fetchUsers();
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (value) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (value == controller.currentSearchQuery.value) return;
                controller.fetchUsers(query: value);
              });
            },
            decoration: InputDecoration(
              labelText: "Tìm kiếm",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),

        Obx(() {
          if (controller.pendingRequests.isEmpty)
            return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Pending Seller Requests (${controller.pendingRequests.length})",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: controller.pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = controller.pendingRequests[index];
                    return SizedBox(width: 320, child: SellerRequestsCard());
                  },
                ),
              ),
              const Divider(thickness: 1, height: 24),
            ],
          );
        }),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tất cả người dùng",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.usersList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.usersList.isEmpty) {
              return const Center(child: Text("No users found."));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (ctx, i) => const Divider(),
              itemCount: controller.usersList.length,
              itemBuilder: (context, index) {
                final user = controller.usersList[index];
                return _buildUserTile(context, user);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildUserTile(BuildContext context, UserProfile user) {
    final isActive = user.isActive ?? true;
    final isSeller = user.role?.toLowerCase() == 'seller';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isSeller
            ? Colors.orange.shade100
            : Colors.grey.shade200,
        backgroundImage: user.userImage != null
            ? NetworkImage(user.userImage!)
            : null,
        child: user.userImage == null
            ? Icon(
                isSeller ? Icons.store : Icons.person,
                color: isSeller ? Colors.orange : Colors.grey,
              )
            : null,
      ),

      title: Row(
        children: [
          Flexible(
            child: Text(
              user.fullName ?? user.email ?? 'Unknown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.black : Colors.grey,
                decoration: isActive
                    ? null
                    : TextDecoration.lineThrough,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (isSeller) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "SELLER",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),

      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email ?? "No Email", style: const TextStyle(fontSize: 12)),
          Text(
            "Phone: ${user.phone ?? 'N/A'}",
            style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
          ),
        ],
      ),

      onTap: () {
        Get.to(() => AdminUserDetailScreen(user: user));
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: isActive,
            activeColor: Colors.green,
            onChanged: (val) => controller.updateUserActiveStatus(user.id, val),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirmDelete(context, user.id);
              if (value == 'edit')
                Get.snackbar("Info", "Edit User coming soon");
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String userId) {
    Get.defaultDialog(
      title: "Delete User",
      middleText:
          "Are you sure you want to delete this user? This action cannot be undone.",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        controller.deleteUser(userId);
      },
    );
  }
}
