import 'dart:ui';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/wishlist_controller.dart';
import 'package:ecomerceapp/features/view/widgets/size_selector.dart';
import 'package:ecomerceapp/controller/cart_controller.dart'; // Import CartController
import 'package:ecomerceapp/features/checkout/screens/checkout_screen.dart'; // Import màn hình checkout

class ProductDetailsScreen extends StatefulWidget {
  final Products product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? _selectedSize;
  String?
  _selectedColor; // Biến này chưa dùng trong UI, nhưng giữ lại cho logic

  // Inject Controllers
  final CartController cartController = Get.find<CartController>();
  // Sử dụng Get.put để đảm bảo controller tồn tại nếu chưa được khởi tạo ở đâu
  final WishlistController wishlistController = Get.put(WishlistController());

  // Hàm hỗ trợ lấy size từ JSON specification
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
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceFormatter = NumberFormat("#,###", "vi_VN");

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          "Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _shareProduct(context),
            icon: Icon(
              Icons.share,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGE SECTION ---
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    widget
                        .product
                        .imageUrl, // Dùng getter imageUrl đã có trong Model
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: screenWidth * 0.04,
                  right: screenWidth * 0.04,
                  child: GetBuilder<WishlistController>(
                    init: wishlistController, // Init nếu cần
                    id: "Wishlist_${widget.product.id}", // ID để update cục bộ
                    builder: (controller) {
                      final isWishlist = controller.isProductInWishList(
                        widget.product.id,
                      );
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () async {
                            await controller.toggleWishlist(widget.product);
                            // Không cần gọi controller.update ở đây vì toggleWishlist thường đã gọi rồi,
                            // nhưng giữ lại nếu logic của bạn yêu cầu manual update.
                          },
                          icon: Icon(
                            isWishlist ? Icons.favorite : Icons.favorite_border,
                            color: isWishlist ? Colors.red : Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // --- INFO SECTION ---
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: AppTextStyles.withColor(
                            AppTextStyles.h1,
                            Theme.of(context).textTheme.headlineMedium!.color!,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${priceFormatter.format(widget.product.price)} VND",
                            style: AppTextStyles.withColor(
                              AppTextStyles.h2,
                              Theme.of(context).primaryColor,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (widget.product.hasDiscount) ...[
                            SizedBox(height: screenHeight * 0.005),
                            Row(
                              children: [
                                Text(
                                  "${priceFormatter.format(widget.product.oldPrice)} VND",
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "-${widget.product.discountPercentage}%",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),

                  // Category & Brand
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                      if (widget.product.brand != null) ...[
                        const SizedBox(width: 8),
                        Text("|", style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 8),
                        Icon(Icons.store, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          widget.product.brand!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Stock Status
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: widget.product.isInstock
                        ? (widget.product.stock <= 5
                              ? Text(
                                  "Only ${widget.product.stock} left in stock",
                                  style: const TextStyle(color: Colors.orange),
                                )
                              : const Text(
                                  "In Stock",
                                  style: TextStyle(color: Colors.green),
                                ))
                        : const Text(
                            "Out of Stock",
                            style: TextStyle(color: Colors.red),
                          ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  if (_getAvailableSizes().isNotEmpty) ...[
                    Text("Select Size", style: AppTextStyles.labelMedium),
                    SizedBox(height: screenHeight * 0.01),
                    SizeSelector(
                      sizes: _getAvailableSizes(),
                      selectedSize:
                          _selectedSize, // Cần truyền size đang chọn vào để highlight
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
                          "Please select a size",
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],

                  SizedBox(height: screenHeight * 0.02),
                  Text("Description", style: AppTextStyles.labelMedium),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    widget.product.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // --- BOTTOM BAR ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Row(
            children: [
              // ADD TO CART
              Expanded(
                child: Obx(
                  () => OutlinedButton(
                    onPressed:
                        (cartController.isLoading.value ||
                            !widget.product.isInstock)
                        ? null
                        : () => _handleAddToCart(isBuyNow: false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.white70 : Colors.black12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: cartController.isLoading.value
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            "Add to Cart",
                            style: AppTextStyles.buttonMedium,
                          ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),

              // BUY NOW
              Expanded(
                child: ElevatedButton(
                  onPressed: !widget.product.isInstock
                      ? null
                      : () => _handleAddToCart(isBuyNow: true),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02,
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Buy Now",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareProduct(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      await Share.share(
        "${widget.product.name}\n${widget.product.description}\nCheck it out!",
        subject: widget.product.name,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      debugPrint("Error sharing: $e");
    }
  }

  // Logic Thêm vào giỏ (Sửa đổi quan trọng)
  Future<void> _handleAddToCart({required bool isBuyNow}) async {
    // 1. Validate Size
    if (_getAvailableSizes().isNotEmpty && _selectedSize == null) {
      Get.snackbar(
        "Select Size",
        "Please select a size to continue",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    // 2. Gọi CartController (Không gọi Service trực tiếp)
    // Controller sẽ tự handle loading state và show snackbar nếu thành công
    final success = await cartController.addToCart(
      product: widget.product,
      quantity: 1,
      selectedSize: _selectedSize,
      selectedColor: _selectedColor,
      showNotification:
          !isBuyNow, // Nếu mua ngay thì ko cần hiện popup "Added to cart"
    );

    // 3. Xử lý Buy Now
    if (success && isBuyNow) {
      Get.to(() => CheckoutScreen());
    }
  }
}
