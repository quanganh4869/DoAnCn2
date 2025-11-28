import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/admin_dashboard/controller/admin_controller.dart';

class AdminProductManagementScreen extends StatelessWidget {
  AdminProductManagementScreen({super.key});

  final AdminController controller = Get.find<AdminController>();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchAllAdminProducts();
    });

    final priceFormatter = NumberFormat("#,###", "vi_VN");

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (value == controller.currentSearchQuery.value) return;
                  controller.fetchAllAdminProducts(query: value);
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

          // 2. List Products
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.adminProductsList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.adminProductsList.isEmpty) {
                return const Center(child: Text("No products found."));
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: controller.adminProductsList.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = controller.adminProductsList[index];
                  return _buildProductTile(context, product, priceFormatter);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(
    BuildContext context,
    Products product,
    NumberFormat priceFormatter,
  ) {
    // Logic hiển thị tên Shop
    String shopName = "Unknown Shop";
    if (product.brand != null && product.brand!.isNotEmpty) {
      shopName = product.brand!;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Ảnh sản phẩm
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          image: product.imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(product.imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: product.imageUrl.isEmpty
            ? const Icon(Icons.image_not_supported, color: Colors.grey)
            : null,
      ),

      // Thông tin
      title: Text(
        product.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          // Nếu bị admin ẩn (is_active = false) thì gạch ngang tên
          decoration: product.isActive ? null : TextDecoration.lineThrough,
          color: product.isActive ? Colors.black : Colors.grey,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            "${priceFormatter.format(product.price)} VND",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.store, size: 14, color: Colors.blueGrey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  shopName,
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        ],
      ),

      // Hành động
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- FIX LỖI TẠI ĐÂY ---
          // Sử dụng đúng hàm toggleProductStatus để ẩn/hiện sản phẩm
          Switch(
            value: product.isActive, // Lấy trạng thái từ product
            activeColor: Colors.green,
            onChanged: (val) => controller.toggleProductStatus(product.id, val),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, product),
          ),
        ],
      ),

      onTap: () {
        // Logic xem chi tiết (nếu cần)
      },
    );
  }

  void _confirmDelete(BuildContext context, Products product) {
    Get.defaultDialog(
      title: "Delete Product",
      middleText:
          "Are you sure you want to permanently delete '${product.name}'?\nThis action cannot be undone.",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        controller.deleteAdminProduct(product.id);
      },
    );
  }
}