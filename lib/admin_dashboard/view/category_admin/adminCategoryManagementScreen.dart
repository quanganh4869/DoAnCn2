import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/category.dart';
import 'package:ecomerceapp/admin_dashboard/controller/admin_controller.dart';

class AdminCategoryManagementScreen extends StatelessWidget {
  AdminCategoryManagementScreen({super.key});

  final AdminController controller = Get.find<AdminController>();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchCategories();
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context, null),
        label: const Text("Tạo danh mục"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  controller.fetchCategories(query: value);
                });
              },
              decoration: InputDecoration(
                labelText: "Tìm kiếm",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.categoriesList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.categoriesList.isEmpty) {
                return const Center(child: Text("No categories found"));
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: controller.categoriesList.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final category = controller.categoriesList[index];
                  return _buildCategoryTile(context, category);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, Category category) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          image: category.iconUrl != null && category.iconUrl!.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(category.iconUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: category.iconUrl == null || category.iconUrl!.isEmpty
            ? const Icon(Icons.category, color: Colors.grey)
            : null,
      ),
      title: Text(
        category.displayName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text("ID: ${category.name} | Order: ${category.sortOrder}"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: category.isActive,
            activeColor: Colors.green,
            onChanged: (val) {
              controller.updateCategory(category.copyWith(isActive: val));
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showCategoryDialog(context, category),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context, category),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, Category? category) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final displayController = TextEditingController(
      text: category?.displayName ?? '',
    );
    final iconController = TextEditingController(text: category?.iconUrl ?? '');
    final orderController = TextEditingController(
      text: category?.sortOrder.toString() ?? '0',
    );
    final isEdit = category != null;

    Get.dialog(
      AlertDialog(
        title: Text(isEdit ? "Edit Category" : "New Category"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: displayController,
                decoration: const InputDecoration(
                  labelText: "Tên hiển thị",
                  hintText: "Ví dụ: Books",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: "Hình ảnh",
                  hintText: "https://...",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(labelText: "Sort Order"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (displayController.text.isEmpty ||
                  nameController.text.isEmpty) {
                Get.snackbar(
                  "Lỗi",
                  "Tên và ID không được để trống",
                  backgroundColor: Colors.red.withOpacity(0.1),
                  colorText: Colors.red,
                );
                return;
              }

              if (isEdit) {
                controller.updateCategory(
                  category!.copyWith(
                    displayName: displayController.text,
                    iconUrl: iconController.text,
                    sortOrder: int.tryParse(orderController.text) ?? 0,
                  ),
                );
              } else {
                controller.addCategory(
                  name: nameController.text,
                  displayName: displayController.text,
                  iconUrl: iconController.text,
                  sortOrder: int.tryParse(orderController.text) ?? 0,
                );
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? "Update" : "Create"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    Get.defaultDialog(
      title: "Delete Category",
      middleText:
          "Are you sure you want to delete '${category.displayName}'?\nThis action might affect products in this category.",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        controller.deleteCategory(category.id);
      },
    );
  }
}
