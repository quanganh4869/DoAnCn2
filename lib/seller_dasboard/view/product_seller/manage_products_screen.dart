import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/review.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/controller/review_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:ecomerceapp/seller_dasboard/controller/seller_controller.dart';
import 'package:ecomerceapp/seller_dasboard/view/product_seller/add_product_screen.dart';

class ManageProductsScreen extends StatelessWidget {
  const ManageProductsScreen({super.key});

  // Hàm phụ trợ lấy rating thực tế từ DB
  Future<Map<String, dynamic>> _fetchProductRating(String productId) async {
    final supabase = Supabase.instance.client;
    try {
      // Lấy tất cả review của sản phẩm này
      final response = await supabase
          .from('reviews')
          .select('rating')
          .eq('product_id', productId);

      final reviews = response as List;
      if (reviews.isEmpty) return {'rating': 0.0, 'count': 0};

      final total = reviews.fold(0, (sum, item) => sum + (item['rating'] as int));
      final avg = total / reviews.length;

      return {'rating': avg, 'count': reviews.length};
    } catch (e) {
      return {'rating': 0.0, 'count': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SellerController>();
    final authController = Get.find<AuthController>();
    final reviewController = Get.put(ReviewController());

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
                    reviewController,
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
    ReviewController reviewController,
    NumberFormat format,
  ) {
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

                      // Giá & Tồn kho
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

                      // --- PHẦN MỚI: HIỂN THỊ RATING THỰC TẾ (FutureBuilder) ---
                      FutureBuilder<Map<String, dynamic>>(
                        future: _fetchProductRating(product.id),
                        builder: (context, snapshot) {
                          // Mặc định dùng dữ liệu từ model nếu chưa load xong
                          double rating = product.rating;
                          int count = product.reviewCount;

                          if (snapshot.hasData) {
                            rating = snapshot.data!['rating'];
                            count = snapshot.data!['count'];
                          }

                          String ratingString = rating.toStringAsFixed(1).replaceAll('.', ',');

                          return Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                ratingString, // "3,6"
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "($count đánh giá)",
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          );
                        },
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
                // Nút Sửa
                TextButton.icon(
                  onPressed: () {
                    Get.to(() => AddProductScreen(productToEdit: product));
                  },
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  label: const Text("Sửa", style: TextStyle(color: Colors.blue)),
                ),

                // Nút Xem Đánh Giá
                TextButton.icon(
                  onPressed: () {
                    _showReviewsBottomSheet(context, product, reviewController);
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
  void _showReviewsBottomSheet(BuildContext context, Products product, ReviewController reviewController) {
    int? pid = int.tryParse(product.id);
    if (pid != null) {
      reviewController.fetchReviews(pid);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text("Đánh giá: ${product.name}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),

            Expanded(
              child: Obx(() {
                if (reviewController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (reviewController.reviews.isEmpty) {
                  return const Center(child: Text("Chưa có đánh giá nào.", style: TextStyle(color: Colors.grey)));
                }

                final reviews = List<Review>.from(reviewController.reviews);

                return ListView.separated(
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(review.createdAt);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: review.userAvatar.isNotEmpty
                                  ? NetworkImage(review.userAvatar)
                                  : null,
                              child: review.userAvatar.isEmpty
                                  ? const Icon(Icons.person, size: 16, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.userName.isNotEmpty ? review.userName : "Khách hàng",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Row(
                              children: List.generate(5, (starIndex) => Icon(
                                starIndex < review.rating ? Icons.star : Icons.star_border,
                                size: 14, color: Colors.amber,
                              )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (review.comment != null && review.comment!.isNotEmpty)
                          Text(review.comment!, style: TextStyle(color: Colors.grey[800], height: 1.4))
                        else
                          Text("(Khách hàng không để lại bình luận)", style: TextStyle(color: Colors.grey[400], fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    );
                  },
                );
              }),
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