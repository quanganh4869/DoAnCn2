import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/features/view/widgets/product_review.dart';
import 'package:ecomerceapp/seller_dasboard/controller/seller_controller.dart';
import 'package:ecomerceapp/seller_dasboard/view/product_seller/add_product_screen.dart';


class ManageProductsScreen extends StatelessWidget {
  const ManageProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SellerController>();
    final authController = Get.find<AuthController>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat("#,###", "vi_VN");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchSellerProducts();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          authController.userProfile?.storeName ?? "My Shop",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => const AddProductScreen());
        },
        label: const Text("Thêm mới"),
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
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Chưa có sản phẩm nào. Bắt đầu bán ngay!",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "Danh sách sản phẩm",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.myProducts.length,
                itemBuilder: (context, index) {
                  final product = controller.myProducts[index];
                  return _buildProductItem(
                    context,
                    product,
                    controller,
                    currencyFormat,
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    Products product,
    SellerController controller,
    NumberFormat format,
  ) {
    // Format rating: 3.6 -> "3,6"
    String ratingString = product.rating.toStringAsFixed(1).replaceAll('.', ',');

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
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ẢNH SẢN PHẨM
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: (product.images.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(product.images[0]),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (product.images.isEmpty)
                      ? const Icon(Icons.image, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),

                // 2. THÔNG TIN CHI TIẾT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: AppTextStyles.h3.copyWith(fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Hàng hiển thị: Giá | Tồn kho
                      Row(
                        children: [
                          Text(
                            "${format.format(product.price)} đ",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Kho: ${product.stock}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // --- PHẦN MỚI: HIỂN THỊ RATING & COMMENT COUNT ---
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            ratingString, // "4,5"
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "(${product.reviewCount} đánh giá)",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(),

            // 3. CÁC NÚT HÀNH ĐỘNG
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Nút Edit
                TextButton.icon(
                  onPressed: () {
                    Get.to(() => AddProductScreen(productToEdit: product));
                  },
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  label: const Text("Sửa", style: TextStyle(color: Colors.blue)),
                ),

                // Nút Xem Đánh Giá (Mới)
                TextButton.icon(
                  onPressed: () {
                    _showReviewsBottomSheet(context, product);
                  },
                  icon: const Icon(Icons.comment, color: Colors.orange, size: 20),
                  label: const Text("Xem Đánh giá", style: TextStyle(color: Colors.orange)),
                ),

                // Nút Xóa
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, product.id, controller),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  label: const Text("Xóa", style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Hàm hiện BottomSheet chứa danh sách đánh giá
  void _showReviewsBottomSheet(BuildContext context, Products product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Để bottom sheet có thể full chiều cao
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Thanh nắm kéo
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Text("Đánh giá cho: ${product.name}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),

            Expanded(
              child: SingleChildScrollView(
                child: ProductReview(
                  productId: int.tryParse(product.id) ?? 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String productId, SellerController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text("Xóa sản phẩm"),
        content: const Text("Bạn có chắc chắn muốn xóa sản phẩm này không?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteProduct(productId);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}