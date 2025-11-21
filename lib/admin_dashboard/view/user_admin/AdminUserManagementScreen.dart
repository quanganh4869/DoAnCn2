import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/models/user_profile.dart';
import 'package:ecomerceapp/admin_dashboard/controller/admin_controller.dart';
import 'package:ecomerceapp/admin_dashboard/view/user_admin/seller_request_card.dart';

class AdminUserManagementScreen extends StatelessWidget {
  AdminUserManagementScreen({super.key});
  final AdminController controller = Get.find<AdminController>();

  @override
  Widget build(BuildContext context) {
    // Refresh data khi vào màn hình để đảm bảo dữ liệu mới nhất
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchPendingSellers();
      controller.fetchUsers();
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (value) {
              // Debounce: Chờ 500ms sau khi gõ mới tìm kiếm
              Future.delayed(const Duration(milliseconds: 500), () {
                if (value == controller.currentSearchQuery.value) return;
                controller.fetchUsers(query: value);
              });
            },
            decoration: InputDecoration(
              labelText: "Search User by Name, Email, Phone",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),

        // 2. PENDING SELLERS REQUESTS (Ở trên cùng - Lướt ngang)
        Obx(() {
          // Nếu không có yêu cầu nào thì ẩn đi
          if (controller.pendingRequests.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Pending Seller Requests (${controller.pendingRequests.length})",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              // List ngang chứa các thẻ yêu cầu
              SizedBox(
                height: 160, // Chiều cao đủ cho thẻ
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: controller.pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = controller.pendingRequests[index];
                    return SizedBox(
                      width: 320,
                      child: SellerRequestsCard(),
                    );
                  },
                ),
              ),
              const Divider(thickness: 1, height: 24),
            ],
          );
        }),

        // 3. TIÊU ĐỀ DANH SÁCH & NÚT THÊM
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("All Users", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () {
                  Get.snackbar("Info", "Add User feature coming soon");
                },
                icon: const Icon(Icons.person_add),
                label: const Text("Add User"),
              )
            ],
          ),
        ),

        // 4. DANH SÁCH USER (Phần chính)
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

  // Widget hiển thị từng User
  Widget _buildUserTile(BuildContext context, UserProfile user) {
    final isActive = user.isActive ?? true;
    final isSeller = user.role?.toLowerCase() == 'seller'; // Kiểm tra role

    return ListTile(
      contentPadding: EdgeInsets.zero,
      // Avatar
      leading: CircleAvatar(
        backgroundColor: isSeller ? Colors.orange.shade100 : Colors.grey.shade200,
        backgroundImage: user.userImage != null ? NetworkImage(user.userImage!) : null,
        child: user.userImage == null
            ? Icon(isSeller ? Icons.store : Icons.person, color: isSeller ? Colors.orange : Colors.grey)
            : null,
      ),

      // Tên User + Badge Seller
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.fullName ?? user.email ?? 'Unknown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.black : Colors.grey,
                decoration: isActive ? null : TextDecoration.lineThrough, // Gạch ngang nếu bị ban
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // HIỂN THỊ BADGE SELLER NẾU CÓ
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
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          ]
        ],
      ),

      // Thông tin phụ
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

      // Sự kiện bấm vào User Card -> Xem sản phẩm (nếu là Seller)
      onTap: () => _showUserDetails(context, user),

      // Các nút hành động bên phải
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Switch Ban/Unban User
          Switch(
            value: isActive,
            activeColor: Colors.green,
            onChanged: (val) => controller.updateUserActiveStatus(user.id, val),
          ),
          // Menu Edit/Delete
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirmDelete(context, user.id);
              if (value == 'edit') Get.snackbar("Info", "Edit User coming soon");
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [Icon(Icons.edit, size: 20, color: Colors.blue), SizedBox(width: 8), Text('Edit')]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete')]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Hiển thị BottomSheet chứa danh sách sản phẩm của User
  void _showUserDetails(BuildContext context, UserProfile user) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, color: Colors.grey.shade300),
            ),
            const SizedBox(height: 16),
            Text("Products by ${user.fullName ?? 'User'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Load danh sách sản phẩm từ Controller
            Expanded(
              child: FutureBuilder<List<Products>>(
                future: controller.getUserProducts(user.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("This user has no products listed.", style: TextStyle(color: Colors.grey)),
                      ],
                    );
                  }

                  final products = snapshot.data!;
                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (ctx, i) {
                      final p = products[i];
                      final formatCurrency = NumberFormat("#,###", "vi_VN");
                      return ListTile(
                        leading: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            image: p.imageUrl.isNotEmpty
                                ? DecorationImage(image: NetworkImage(p.imageUrl), fit: BoxFit.cover)
                                : null
                          ),
                        ),
                        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text("Price: ${formatCurrency.format(p.price)} đ | Stock: ${p.stock}"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _confirmDelete(BuildContext context, String userId) {
    Get.defaultDialog(
      title: "Delete User",
      middleText: "Are you sure you want to delete this user? This action cannot be undone.",
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