import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/seller_dasboard/controller/seller_controller.dart';
import 'package:ecomerceapp/seller_dasboard/view/product_seller/add_product_screen.dart';

class ManageProductsScreen extends StatelessWidget {
  const ManageProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng SellerController đã gộp (chứa cả myProducts và logic xóa)
    final controller = Get.find<SellerController>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat("#,###", "vi_VN");

    // Gọi hàm fetch sản phẩm khi vào màn hình này để đảm bảo dữ liệu mới nhất
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchSellerProducts();
    });

    return Scaffold(
      // Nút chuyển sang trang Thêm sản phẩm (Không truyền tham số product)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => const AddProductScreen());
        },
        label: const Text("Add New"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.myProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text("No products yet. Start selling!", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.myProducts.length,
          itemBuilder: (context, index) {
            final product = controller.myProducts[index];
            return _buildProductItem(context, product, controller, currencyFormat);
          },
        );
      }),
    );
  }

  Widget _buildProductItem(BuildContext context, Products product, SellerController controller, NumberFormat format) {
    // Bọc toàn bộ thẻ sản phẩm bằng GestureDetector để bấm vào là sửa
    return GestureDetector(
      onTap: () {
        Get.to(() => AddProductScreen(productToEdit: product));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: (product.images != null && product.images.isNotEmpty)
                  ? DecorationImage(image: NetworkImage(product.images[0]), fit: BoxFit.cover)
                  : null,
              ),
              child: (product.images == null || product.images.isEmpty)
                  ? const Icon(Icons.image, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.h3.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Stock: ${product.stock ?? 0} | Category: ${product.category}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${format.format(product.price)} VND",
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                // NÚT EDIT: Chuyển sang trang AddProductScreen với productToEdit
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Get.to(() => AddProductScreen(productToEdit: product));
                  },
                ),
                // Nút Xóa
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, product.id, controller),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String productId, SellerController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteProduct(productId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }
}