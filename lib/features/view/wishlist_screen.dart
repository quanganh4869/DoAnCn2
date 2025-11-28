import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/controller/wishlist_controller.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!Get.isRegistered<AuthController>()) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final auth = Get.find<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Danh sách yêu thích của tôi",
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold
          )
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search, color: isDark ? Colors.white : Colors.black),
          ),
        ],
      ),
      body: GetBuilder<WishlistController>(
        init: WishlistController(),
        builder: (controller) {
          if (controller.isLoading && controller.wishlistProducts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.hasError) {
            return _buildError(controller);
          }

          if (controller.isEmpty) {
            return _buildEmpty(isDark);
          }

          return Column(
            children: [
              _buildSummary(context, controller),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _buildItem(
                              context, controller.wishlistProducts[i], controller),
                          childCount: controller.wishlistProducts.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildError(WishlistController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(controller.errorMessage,
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: controller.refreshWishlist,
            child: const Text("Thử lại"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Danh sách yêu thích trống",
            style: TextStyle(
                fontSize: 18, color: isDark ? Colors.white70 : Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, WishlistController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          )
        ],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Số lượng: ",
                  style: AppTextStyles.withColor(
                      AppTextStyles.bodySmall, Colors.grey),
                ),
                Text(
                  "${controller.itemCount} sản phẩm",
                  style: AppTextStyles.withColor(
                    AppTextStyles.h2,
                    isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: controller.isLoading
                  ? null
                  : () {
                      controller.addAllToCart();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      "Thêm tất cả vào giỏ hàng",
                      style: AppTextStyles.withColor(
                          AppTextStyles.buttonMedium, Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
      BuildContext context, Products product, WishlistController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceFormatter = NumberFormat("#,###", "vi_VN");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Image.network(
              _safe(product.primaryImage),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                color: Colors.grey[300],
                child:
                    const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.withColor(
                      AppTextStyles.h3,
                      isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: AppTextStyles.withColor(
                        AppTextStyles.bodySmall, Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${priceFormatter.format(product.price)} VND",
                        style: AppTextStyles.withColor(
                          AppTextStyles.h3,
                          Theme.of(context).primaryColor,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: (product.stock ?? 0) > 0
                                ? () => controller.addSingleItemToCart(product)
                                : null,
                            icon: Icon(
                              Icons.shopping_cart_checkout,
                              color: (product.stock ?? 0) > 0
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                            ),
                            tooltip: "Thêm vào giỏ hàng",
                          ),
                          IconButton(
                            onPressed: () async {
                              await controller.removeFromWishlist(product.id);
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red[400],
                            ),
                            tooltip: "Xóa",
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  String _safe(String? url) {
    if (url == null || url.isEmpty || !url.startsWith("http")) {
      return "https://via.placeholder.com/150";
    }
    return url;
  }
}