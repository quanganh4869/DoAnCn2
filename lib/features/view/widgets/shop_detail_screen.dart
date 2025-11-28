import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/controller/review_controller.dart';
import 'package:ecomerceapp/controller/product_controller.dart';
import 'package:ecomerceapp/features/view/widgets/product_card.dart';

class ShopDetailScreen extends StatefulWidget {
  final String brandName;

  const ShopDetailScreen({super.key, required this.brandName});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  final ProductController productController = Get.find<ProductController>();
  final ReviewController reviewController = Get.put(ReviewController());

  late List<Products> shopProducts;
  late List<Products> filteredProducts;
  final TextEditingController _searchController = TextEditingController();

  double _shopRating = 0.0;
  int _totalReviews = 0;
  bool _isLoadingStats = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    shopProducts = productController.allProducts
        .where(
          (p) =>
              p.brand != null &&
              p.brand!.toLowerCase() == widget.brandName.toLowerCase(),
        )
        .toList();

    filteredProducts = shopProducts;
    _calculateShopRatingFromService();
  }

  Future<void> _calculateShopRatingFromService() async {
    if (shopProducts.isEmpty) {
      if (mounted) setState(() => _isLoadingStats = false);
      return;
    }

    try {
      double totalWeightedScore = 0;
      int totalCount = 0;

      final futures = shopProducts.map(
        (p) => reviewController.getProductRatingStat(p.id),
      );
      final results = await Future.wait(futures);

      for (var stat in results) {
        final double rating = stat['rating'] ?? 0.0;
        final int count = stat['count'] ?? 0;

        if (count > 0) {
          totalWeightedScore += (rating * count);
          totalCount += count;
        }
      }

      if (mounted) {
        setState(() {
          _totalReviews = totalCount;
          _shopRating = totalCount > 0 ? totalWeightedScore / totalCount : 0.0;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint("Error calculating shop rating: $e");
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        filteredProducts = shopProducts;
      } else {
        filteredProducts = shopProducts
            .where(
              (p) => p.name.toLowerCase().contains(query.trim().toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
    Get.snackbar(
      _isFollowing ? "Đã theo dõi" : "Đã hủy theo dõi",
      _isFollowing
          ? "Bạn sẽ nhận được thông báo mới từ shop."
          : "Đã hủy đăng ký nhận tin.",
      snackPosition: SnackPosition.TOP,
      backgroundColor: _isFollowing
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
      colorText: _isFollowing ? Colors.green : Colors.red,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth > 900) {
      crossAxisCount = 4;
      childAspectRatio = 0.75;
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
      childAspectRatio = 0.7;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 0.64;
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor.withOpacity(0.8), primaryColor],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Icon(
                      Icons.store,
                      size: 250,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),

                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  widget.brandName.isNotEmpty
                                      ? widget.brandName[0].toUpperCase()
                                      : "S",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Tên và Thông số
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.brandName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _buildShopStat(
                                        "${shopProducts.length}",
                                        "Sản phẩm",
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 1,
                                        height: 12,
                                        color: Colors.white54,
                                      ),
                                      const SizedBox(width: 12),
                                      _isLoadingStats
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : _buildShopStat(
                                              _shopRating > 0
                                                  ? _shopRating
                                                        .toStringAsFixed(1)
                                                        .replaceAll('.', ',')
                                                  : "N/A",
                                              "Đánh giá ($_totalReviews)",
                                            ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: _toggleFollow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.white,
                              foregroundColor: _isFollowing
                                  ? Colors.white
                                  : primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  8,
                                ), // Bo góc nhẹ cho nút dài
                                side: _isFollowing
                                    ? const BorderSide(color: Colors.white)
                                    : BorderSide.none,
                              ),
                              elevation: _isFollowing ? 0 : 2,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              _isFollowing ? "Đang theo dõi" : "Theo dõi Shop",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _filterProducts,
                decoration: InputDecoration(
                  hintText: "Tìm trong shop ...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ),

          if (filteredProducts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      shopProducts.isEmpty
                          ? "Shop này chưa có sản phẩm nào."
                          : "Không tìm thấy sản phẩm nào.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return ProductCard(product: filteredProducts[index]);
                }, childCount: filteredProducts.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShopStat(String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
