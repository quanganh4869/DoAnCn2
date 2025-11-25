import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/review.dart';
import 'package:ecomerceapp/controller/review_controller.dart';

class ProductReview extends StatefulWidget {
  final int productId;

  const ProductReview({super.key, required this.productId});

  @override
  State<ProductReview> createState() => _ProductReviewState();
}

class _ProductReviewState extends State<ProductReview> {
  final ReviewController controller = Get.put(ReviewController());

  @override
  void initState() {
    super.initState();
    // Gọi API lấy review khi widget được build
    controller.fetchReviews(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header: Tiêu đề & Nút Thêm ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() => Text(
              "Reviews (${controller.reviews.length})",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            )),
            TextButton.icon(
              onPressed: () => _showAddReviewDialog(context),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text("Viết đánh giá"),
            ),
          ],
        ),

        // --- Summary: Điểm trung bình ---
        Obx(() {
           if (controller.reviews.isEmpty) return const SizedBox.shrink();
           return Row(
             children: [
               Text(
                 controller.averageRating.value.toStringAsFixed(1),
                 style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
               ),
               const SizedBox(width: 8),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   _buildStarRating(controller.averageRating.value, size: 16),
                   Text(
                     "Based on ${controller.reviews.length} reviews",
                     style: TextStyle(color: Colors.grey[600], fontSize: 12),
                   ),
                 ],
               )
             ],
           );
        }),

        const SizedBox(height: 16),

        // --- List Reviews ---
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.reviews.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text("Chưa có đánh giá nào. Hãy là người đầu tiên!"),
            );
          }

          return ListView.separated(
            shrinkWrap: true, // Quan trọng để nằm trong Column
            physics: const NeverScrollableScrollPhysics(), // Disable scroll riêng
            itemCount: controller.reviews.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final review = controller.reviews[index];
              return _buildReviewItem(review);
            },
          );
        }),
      ],
    );
  }

  Widget _buildReviewItem(Review review) {
    final dateStr = DateFormat('dd/MM/yyyy').format(review.createdAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 20,
          backgroundImage: review.userAvatar.isNotEmpty
              ? NetworkImage(review.userAvatar)
              : null,
          child: review.userAvatar.isEmpty
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildStarRating(review.rating.toDouble(), size: 14),
              const SizedBox(height: 8),
              Text(
                review.comment!,
                style: TextStyle(color: Colors.grey[800], height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget hiển thị sao (Star)
  Widget _buildStarRating(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating) {
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.grey[300], size: size);
        }
      }),
    );
  }

  // Dialog thêm đánh giá
  void _showAddReviewDialog(BuildContext context) {
    final commentController = TextEditingController();
    // Dùng ValueNotifier để update sao khi bấm
    final selectedRating = ValueNotifier<int>(5);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đánh giá sản phẩm"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Bạn cảm thấy sản phẩm thế nào?"),
            const SizedBox(height: 16),
            // Star Selector
            ValueListenableBuilder<int>(
              valueListenable: selectedRating,
              builder: (context, value, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () => selectedRating.value = index + 1,
                      icon: Icon(
                        index < value ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: "Viết cảm nhận của bạn...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.isEmpty) return;

              final success = await controller.addReview(
                productId: widget.productId,
                rating: selectedRating.value,
                comment: commentController.text,
              );

              if (success) Navigator.pop(ctx);
            },
            child: const Text("Gửi"),
          ),
        ],
      ),
    );
  }
}