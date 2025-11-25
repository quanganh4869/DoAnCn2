import 'dart:ui';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ecomerceapp/models/review.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/cart_controller.dart';
import 'package:ecomerceapp/controller/review_controller.dart';
import 'package:ecomerceapp/controller/wishlist_controller.dart';
import 'package:ecomerceapp/features/view/widgets/size_selector.dart';
import 'package:ecomerceapp/features/view/widgets/shop_detail_screen.dart';
import 'package:ecomerceapp/features/checkout/screens/checkout_screen.dart';


class ProductDetailsScreen extends StatefulWidget {
  final Products product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? _selectedSize;
  int _userRating = 5;
  final TextEditingController _reviewController = TextEditingController();

  late final CartController cartController;
  late final WishlistController wishlistController;
  final ReviewController reviewController = Get.put(ReviewController());

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CartController>()) {
      cartController = Get.find<CartController>();
    } else {
      cartController = Get.put(CartController());
    }

    if (Get.isRegistered<WishlistController>()) {
      wishlistController = Get.find<WishlistController>();
    } else {
      wishlistController = Get.put(WishlistController());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      int? productId = int.tryParse(widget.product.id);
      if (productId != null) {
        reviewController.fetchReviews(productId);
      }
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  List<String> _getAvailableSizes() {
    if (widget.product.specification.containsKey("sizes")) {
      final sizes = widget.product.specification["sizes"];
      if (sizes is List) {
        return List<String>.from(sizes);
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceFormatter = NumberFormat("#,###", "vi_VN");

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: CircleAvatar(
            backgroundColor: isDark ? Colors.black54 : Colors.white,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 20),
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: CircleAvatar(
              backgroundColor: isDark ? Colors.black54 : Colors.white,
              child: IconButton(
                onPressed: () => _shareProduct(context),
                icon: const Icon(Icons.share, size: 20),
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageHeader(size, isDark),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildWishlistButton(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    double displayRating = widget.product.rating;
                    int displayCount = widget.product.reviewCount;
                    if (reviewController.reviews.isNotEmpty) {
                      displayRating = reviewController.averageRating.value;
                      displayCount = reviewController.reviews.length;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "${displayRating.toStringAsFixed(1)} ($displayCount reviews)",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${priceFormatter.format(widget.product.price)} VND",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (widget.product.oldPrice != null)
                        Text(
                          "${priceFormatter.format(widget.product.oldPrice)} VND",
                          style: TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.stock > 0
                        ? "Còn hàng (${widget.product.stock} sản phẩm)"
                        : "Hết hàng",
                    style: TextStyle(
                      color: widget.product.stock > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- CATEGORY & BRAND (THÊM MỚI TẠI ĐÂY) ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.product.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),

                      if (widget.product.brand != null && widget.product.brand!.isNotEmpty) ...[
                        const SizedBox(width: 24),
                        Text("| Brand: ", style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),

                        InkWell(
                          onTap: () {
                            Get.to(() => ShopDetailScreen(brandName: widget.product.brand!));
                          },
                          child: Row(
                            children: [
                              Icon(Icons.store, size: 16, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                widget.product.brand!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  if (_getAvailableSizes().isNotEmpty) ...[
                    const Text("Chọn kích thước", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    SizeSelector(
                      sizes: _getAvailableSizes(),
                      selectedSize: _selectedSize,
                      onSizeSelected: (size) {
                        setState(() {
                          _selectedSize = size;
                        });
                      },
                    ),
                    if (_selectedSize == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "* Vui lòng chọn kích thước",
                          style: TextStyle(color: Colors.red[400], fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                  const Text("Mô tả sản phẩm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(thickness: 4),
                  const SizedBox(height: 20),
                  const Text("Đánh giá & Nhận xét", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Viết nhận xét của bạn", style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Row(
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () => setState(() => _userRating = index + 1),
                              child: Icon(
                                index < _userRating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _reviewController,
                          decoration: InputDecoration(
                            hintText: "Chất lượng sản phẩm thế nào?...",
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _submitReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Gửi đánh giá"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(() {
                    if (reviewController.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (reviewController.reviews.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("Chưa có đánh giá nào.", style: TextStyle(color: Colors.grey)),
                        ),
                      );
                    }
                    final sortedReviews = List<Review>.from(reviewController.reviews)
                      ..sort((a, b) => b.rating.compareTo(a.rating));
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedReviews.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final review = sortedReviews[index];
                        return _buildReviewItem(review, isDark);
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, isDark),
    );
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      Get.snackbar("Thông báo", "Vui lòng nhập nội dung đánh giá", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    int? pid = int.tryParse(widget.product.id);
    if (pid == null) return;
    try {
      final success = await reviewController.addReview(
        productId: pid,
        rating: _userRating,
        comment: _reviewController.text.trim(),
      );
      if (success) {
        _reviewController.clear();
        setState(() => _userRating = 5);
        Get.snackbar("Thành công", "Cảm ơn bạn đã đánh giá!",
            backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green);
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể gửi đánh giá: $e");
    }
  }

  Future<void> _handleAddToCart({required bool isBuyNow}) async {
    if (widget.product.stock <= 0) {
      Get.snackbar("Hết hàng", "Sản phẩm này hiện đã hết hàng.", backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red);
      return;
    }
    if (_getAvailableSizes().isNotEmpty && _selectedSize == null) {
      Get.snackbar("Chưa chọn Size", "Vui lòng chọn kích thước để tiếp tục", snackPosition: SnackPosition.TOP, backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red, margin: const EdgeInsets.all(16), duration: const Duration(seconds: 2));
      return;
    }
    final success = await cartController.addToCart(
      product: widget.product,
      quantity: 1,
      selectedSize: _selectedSize,
      selectedColor: null,
      showNotification: !isBuyNow,
    );
    if (success && isBuyNow) {
      Get.to(() => CheckoutScreen());
    }
  }

  Widget _buildReviewItem(Review review, bool isDark) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(review.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            backgroundImage: review.userAvatar.isNotEmpty ? NetworkImage(review.userAvatar) : null,
            child: review.userAvatar.isEmpty ? const Icon(Icons.person, size: 24, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(review.userName.isNotEmpty ? review.userName : "Người dùng", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: List.generate(5, (index) => Icon(index < review.rating ? Icons.star : Icons.star_border, size: 14, color: Colors.amber))),
                const SizedBox(height: 8),
                if (review.comment != null && review.comment!.isNotEmpty) Text(review.comment!, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader(Size size, bool isDark) {
    return Container(
      height: size.height * 0.45,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        image: widget.product.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(widget.product.imageUrl), fit: BoxFit.cover) : null,
      ),
      child: widget.product.imageUrl.isEmpty ? const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)) : null,
    );
  }

  Widget _buildWishlistButton() {
    return GetBuilder<WishlistController>(
      init: wishlistController,
      id: "Wishlist_${widget.product.id}",
      builder: (controller) {
        final isWishlist = controller.isProductInWishList(widget.product.id);
        return IconButton(
          onPressed: () async {
            await controller.toggleWishlist(widget.product);
          },
          icon: Icon(isWishlist ? Icons.favorite : Icons.favorite_border, color: isWishlist ? Colors.red : Colors.grey, size: 28),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Obx(() => OutlinedButton(
                onPressed: () => _handleAddToCart(isBuyNow: false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: isDark ? Colors.white60 : Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: cartController.isLoading.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Add to Cart", style: TextStyle(fontWeight: FontWeight.bold)),
              )),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleAddToCart(isBuyNow: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("Buy Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareProduct(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      await Share.share("${widget.product.name}\n${widget.product.description}\nCheck it out!", subject: widget.product.name, sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
    } catch (e) { debugPrint("Error sharing: $e"); }
  }
}