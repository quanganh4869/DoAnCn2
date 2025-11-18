import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/admin_dashboard/controller/admin_controller.dart';

class AdminUserManagementScreen extends StatelessWidget {
  AdminUserManagementScreen({super.key});
  final AdminController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Thanh Search (Tìm kiếm)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (value) {
              // Debounce search (tìm kiếm sau khi gõ xong)
              Future.delayed(const Duration(milliseconds: 500), () {
                if (value == controller.currentSearchQuery.value) return; // Nếu không thay đổi
                controller.fetchUsers(query: value);
              });
            },
            decoration: const InputDecoration(
              labelText: "Search User by Name, Email or Phone",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        
        // Danh sách User
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.usersList.isEmpty) {
              return const Center(child: Text("No users found."));
            }
            
            return ListView.builder(
              itemCount: controller.usersList.length,
              itemBuilder: (context, index) {
                final user = controller.usersList[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.userImage ?? ''),
                  ),
                  title: Text(user.fullName ?? user.email ?? 'No Name'),
                  subtitle: Text("Role: ${user.role ?? 'N/A'} | Status: ${user.phone}"),
                  trailing: Switch(
                    value: user.isActive ?? true, // Giả sử model UserProfile đã được update is_active
                    onChanged: (bool newValue) {
                      controller.updateUserActiveStatus(user.id, newValue);
                    },
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}