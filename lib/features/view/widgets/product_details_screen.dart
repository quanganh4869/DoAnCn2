import 'dart:ui';
import 'package:get/get.dart'; 
import 'package:intl/intl.dart';
import 'package:flutter/material.dart'; 
import 'package:share_plus/share_plus.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/controller/wishlist_controller.dart';
import 'package:ecomerceapp/supabase/cart_supabase_services.dart';
import 'package:ecomerceapp/features/view/widgets/size_selector.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Products product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? _selectedSize;
  String? _selectedColor;
  bool _isAdding = false;

  // Hàm hỗ trợ lấy size
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
            onPressed: () => _shareProduct(
              context,
              widget.product.name,
              widget.product.description,
            ),
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
                    widget.product.primaryImage.isNotEmpty
                        ? widget.product.primaryImage
                        : 'https://via.placeholder.com/400',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported,
                              size: 50, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: screenWidth * 0.04,
                  right: screenWidth * 0.04,
                  child: GetBuilder<WishlistController>(
                    id: "Wishlist_${widget.product.id}",
                    builder: (controller) {
                      final isWishlist =
                          controller.isProductInWishList(widget.product.id);
                      return IconButton(
                        onPressed: () async {
                          await controller.toggleWishlist(widget.product);
                          controller.update(["Wishlist_${widget.product.id}"]);
                        },
                        icon: Icon(
                          isWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isWishlist
                              ? Theme.of(context).primaryColor
                              : (isDark ? Colors.white : Colors.black),
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
                              Theme.of(context).textTheme.headlineMedium!.color!,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (widget.product.oldPrice != null &&
                              widget.product.oldPrice! >
                                  widget.product.price) ...[
                            SizedBox(height: screenHeight * 0.005),
                            Row(
                              children: [
                                Text(
                                  "${priceFormatter.format(widget.product.oldPrice)} VND",
                                  style: AppTextStyles.withColor(
                                    AppTextStyles.bodySmall,
                                    isDark ? Colors.grey[400]! : Colors.grey[600]!,
                                  ).copyWith(
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "${((widget.product.oldPrice! - widget.product.price) / widget.product.oldPrice! * 100).round()}% OFF",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
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
                      Text(
                        widget.product.category,
                        style: AppTextStyles.withColor(
                          AppTextStyles.bodyMedium,
                          isDark ? Colors.grey[400]! : Colors.grey[600]!,
                        ),
                      ),
                      if (widget.product.brand != null) ...[
                        const SizedBox(width: 8),
                        Text("|", style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 8),
                        Text(
                          widget.product.brand!,
                          style: AppTextStyles.withColor(
                            AppTextStyles.bodyMedium,
                            isDark ? Colors.grey[400]! : Colors.grey[600]!,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Stock Status
                  if (widget.product.stock <= 5 && widget.product.stock > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Only ${widget.product.stock} left in stock",
                        style: AppTextStyles.withColor(
                            AppTextStyles.bodySmall, Colors.orange),
                      ),
                    )
                  else if (widget.product.stock == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Out of stock",
                        style: AppTextStyles.withColor(
                            AppTextStyles.bodySmall, Colors.red),
                      ),
                    ),

                  SizedBox(height: screenHeight * 0.02),

                  // Size Selector
                  if (_getAvailableSizes().isNotEmpty) ...[
                    Text(
                      "Select Size",
                      style: AppTextStyles.withColor(
                        AppTextStyles.labelMedium,
                        Theme.of(context).textTheme.bodyLarge!.color!,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    SizeSelector(
                      sizes: _getAvailableSizes(),
                      // Thêm logic để highlight size đã chọn
                      onSizeSelected: (size) {
                        setState(() {
                          _selectedSize = size;
                        });
                      },
                    ),
                    if (_selectedSize == null)
                       Padding(
                         padding: const EdgeInsets.only(top: 8.0),
                         child: Text("Please select a size", style: TextStyle(color: Colors.red[300], fontSize: 12)),
                       ),
                  ],

                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Description",
                    style: AppTextStyles.withColor(
                      AppTextStyles.labelMedium,
                      Theme.of(context).textTheme.bodyLarge!.color!,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    widget.product.description,
                    style: AppTextStyles.withColor(
                      AppTextStyles.bodyLarge,
                      Theme.of(context).textTheme.headlineSmall!.color!,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isAdding || widget.product.stock == 0
                      ? null
                      : _handleAddToCart,
                  style: OutlinedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    side: BorderSide(
                        color: isDark ? Colors.white70 : Colors.black12),
                  ),
                  child: _isAdding
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                                Theme.of(context).primaryColor),
                          ),
                        )
                      : Text(
                          "Add to Cart",
                          style: AppTextStyles.withColor(
                            AppTextStyles.buttonMedium,
                            Theme.of(context).textTheme.bodyLarge!.color!,
                          ),
                        ),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Logic Buy Now (thường là thêm vào cart rồi chuyển sang checkout)
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text(
                    "Buy Now",
                    style: AppTextStyles.withColor(
                        AppTextStyles.buttonMedium, Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareProduct(BuildContext context, String productName, String description) async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      await Share.share(
        "$description\n\nCheck out $productName!",
        subject: productName,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      debugPrint("Error sharing: $e");
    }
  }

  Future<void> _handleAddToCart() async {
    // Validate Size
    if (_getAvailableSizes().isNotEmpty && _selectedSize == null) {
      Get.snackbar(
        "Select Size", 
        "Please select a size to continue",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        Get.snackbar("Login Required", "Please login to add items to cart.");
        return;
      }

      final success = await CartSupabaseServices.addToCart(
        userId: user.id,
        product: widget.product,
        selectedSize: _selectedSize,
        selectedColor: _selectedColor,
        quantity: 1,
      );

      if (success == true) {
        Get.snackbar(
          "Success", 
          "Added to cart successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
        );
      } else {
        Get.snackbar(
          "Error", 
          "Failed to add to cart",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      debugPrint("Error adding to cart: $e");
      Get.snackbar("Error", "An unexpected error occurred");
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }
}