import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/review_controller.dart';
import 'package:ecomerceapp/controller/wishlist_controller.dart';
// Import ReviewController để lấy dữ liệu đánh giá

// --- CONSTANTS ---
const double kProductCardMaxWidth = 300;
const double kMobilePadding = 8.0;
const double kTabletBreakpoint = 600.0;

class ProductCard extends StatelessWidget {
  final Products product;
  const ProductCard({super.key, required this.product});

  /// Hàm hỗ trợ scale font chữ
  TextStyle _getResponsiveFont(
    BuildContext context,
    TextStyle baseStyle, {
    bool isTablet = false,
    FontWeight? weight,
    Color? color,
    TextDecoration? decoration,
  }) {
    double scale = isTablet ? 1.15 : 1.0;
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * scale,
      fontWeight: weight ?? baseStyle.fontWeight,
      color: color ?? baseStyle.color,
      decoration: decoration ?? baseStyle.decoration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = screenWidth >= kTabletBreakpoint;
    final priceFormatter = NumberFormat("#,###", "vi_VN");

    // Inject ReviewController
    final reviewController = Get.put(ReviewController());

    // Padding và Spacing
    final contentPadding = screenWidth < 350 ? 6.0 : kMobilePadding;
    final verticalSpacing = isTablet ? 12.0 : 4.0;

    return Container(
      constraints: BoxConstraints(
        maxWidth: kProductCardMaxWidth,
      ),
      width: isTablet ? kProductCardMaxWidth : screenWidth * 0.45,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Quan trọng: Chỉ chiếm chiều cao cần thiết
        children: [
          // --- 1. ẢNH & ICON & TAG ---
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    product.images.isNotEmpty ? product.images[0] : '',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          size: isTablet ? 40 : 30,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Nút tim
              Positioned(
                right: contentPadding,
                top: contentPadding,
                child: GetBuilder<WishlistController>(
                  id: "wishlist_${product.id}",
                  builder: (controller) {
                    final isInWishlist = controller.isProductInWishList(product.id);
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: InkWell(
                        onTap: () async {
                          await controller.toggleWishlist(product);
                          controller.update(["wishlist_${product.id}"]);
                        },
                        child: Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          size: isTablet ? 24 : 18,
                          color: isInWishlist
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Tag giảm giá
              if (product.oldPrice != null)
                Positioned(
                  left: contentPadding,
                  top: contentPadding,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red, // Màu đỏ nổi bật cho Sale
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${calculateDiscount(product.price, product.oldPrice!)}% OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // --- 2. THÔNG TIN SẢN PHẨM ---
          Padding(
            padding: EdgeInsets.all(contentPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên sản phẩm
                Text(
                  product.name,
                  style: _getResponsiveFont(
                    context,
                    AppTextStyles.h3,
                    isTablet: isTablet,
                    weight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: verticalSpacing / 2),

                Text(
                  product.category,
                  style: _getResponsiveFont(
                    context,
                    AppTextStyles.bodySmall,
                    isTablet: isTablet,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: verticalSpacing / 2),

                FutureBuilder<Map<String, dynamic>>(
                  future: reviewController.getProductRatingStat(product.id),
                  builder: (context, snapshot) {
                    double rating = product.rating;
                    int count = product.reviewCount;
                    if (snapshot.hasData) {
                      rating = (snapshot.data!['rating'] as num).toDouble();
                      count = (snapshot.data!['count'] as num).toInt();
                    }

                    final ratingString = rating.toStringAsFixed(1).replaceAll('.', ',');

                    return Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "$ratingString, ($count đánh giá)",
                            style: _getResponsiveFont(
                              context,
                              AppTextStyles.bodySmall,
                              isTablet: isTablet,
                              color: Colors.grey[600],
                              weight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: verticalSpacing),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${priceFormatter.format(product.price)} VND",
                      style: _getResponsiveFont(
                        context,
                        AppTextStyles.bodyLarge,
                        isTablet: isTablet,
                        weight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (product.oldPrice != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          "${priceFormatter.format(product.oldPrice!)} VND",
                          style: _getResponsiveFont(
                            context,
                            AppTextStyles.bodySmall,
                            isTablet: isTablet,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int calculateDiscount(double currentPrice, double oldPrice) {
    if (oldPrice == 0) return 0;
    return (((oldPrice - currentPrice) / oldPrice) * 100).round();
  }
}