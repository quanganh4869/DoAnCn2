import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/controller/wishlist_controller.dart';

class WishlistScreen extends StatelessWidget {
  WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Get.find<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Wishlist",
          style: AppTextStyles.withColor(
            AppTextStyles.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search, color: isDark ? Colors.white : Colors.black),
          ),
        ],
      ),

      // 🔥 Auto refresh khi update
      body: GetBuilder<WishlistController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.hasError) {
            return _buildError(controller);
          }

          if (controller.isEmpty) {
            return _buildEmpty(isDark);
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildSummary(context, controller.itemCount),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _buildItem(context, controller.wishlistProducts[i], controller),
                    childCount: controller.wishlistProducts.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // UI BLOCKS
  // ==========================================================

  Widget _buildError(WishlistController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(controller.errorMessage, style: TextStyle(color: Colors.grey[600])),
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
          Icon(Icons.favorite_border, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Wishlist của bạn trống",
            style: TextStyle(fontSize: 18, color: isDark ? Colors.white70 : Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$count items", style: AppTextStyles.h2),
          ElevatedButton(
            onPressed: () {},
            child: const Text("Add All to Cart"),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FIXED — Wishlist Item
  // ==========================================================
  Widget _buildItem(BuildContext context, Products product, WishlistController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.08),
          )
        ],
      ),
      child: Row(
        children: [
          // FIX FALLBACK 404
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: Image.network(
              _safe(product.primaryImage),
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 110,
                height: 110,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h3),

                  const SizedBox(height: 6),
                  Text(product.category, style: AppTextStyles.bodySmall),

                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${product.price} VND",
                          style: AppTextStyles.h3),

                      Row(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.shopping_cart_outlined,
                                color: Theme.of(context).primaryColor),
                          ),

                          IconButton(
                            onPressed: () async {
                              await controller.removeFromWishlist(product.id);
                              controller.update(); 
                            },
                            icon: Icon(Icons.delete_outline,
                                color: Colors.redAccent),
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

  /// Fix URL rỗng hoặc sai → tránh 404
  String _safe(String url) {
    if (url.isEmpty || !url.startsWith("http")) {
      return "https://via.placeholder.com/150";
    }
    return url;
  }
}
