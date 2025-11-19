import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/cart_item.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/cart_controller.dart';
import 'package:ecomerceapp/features/checkout/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartController controller = Get.put(CartController());

  @override
  void initState() {
    super.initState();
    // Load dữ liệu khi màn hình vừa khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadCartItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          "My Cart",
          style: AppTextStyles.withColor(
            AppTextStyles.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Obx(() {
        // 1. Trạng thái Loading
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Trạng thái Giỏ hàng rỗng
        if (controller.cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Your cart is empty',
                  style: AppTextStyles.withColor(
                    AppTextStyles.h3,
                    isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          );
        }

        // 3. Hiển thị danh sách và tổng tiền
        return Column(
          children: [
            // Danh sách sản phẩm (Scrollable)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: controller.cartItems.length,
                separatorBuilder: (ctx, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = controller.cartItems[index];
                  return _buildCartItem(context, item);
                },
              ),
            ),
            // Phần tổng tiền cố định ở dưới
            _buildCartSummary(context),
          ],
        );
      }),
    );
  }

  // --- WIDGET: CART ITEM ---
 Widget _buildCartItem(BuildContext context, CartItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceFormatter = NumberFormat("#,###", "vi_VN");
    final product = item.product;

    if (product == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Ảnh sản phẩm
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              product.images.isNotEmpty ? product.images[0] : '',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 90,
                height: 90,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Thông tin chi tiết
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HÀNG 1: Tên sản phẩm và nút xóa ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: AppTextStyles.withColor(
                          AppTextStyles.h3,
                          isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showDeleteConfirmationDialog(context, item),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red[400],
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),

                // Size (nếu có)
                if (item.selectedSize != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "Size: ${item.selectedSize}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),

                const SizedBox(height: 4),

                // --- HÀNG 2: Giá tiền và Tăng/Giảm số lượng ---
                // ĐÂY LÀ CHỖ ĐÃ SỬA LỖI TRÀN MÀN HÌNH
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cột giá tiền (Bọc trong Expanded để không đẩy nút số lượng)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${priceFormatter.format(product.price)} VND",
                            style: AppTextStyles.withColor(
                              AppTextStyles.h3, // Giảm size chữ xuống h3 hoặc giữ h2 tùy ý, nhưng h3 an toàn hơn
                              Theme.of(context).textTheme.headlineMedium!.color!,
                            ).copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // Cắt bớt nếu quá dài
                          ),

                          // Giá cũ (nếu có)
                          if (product.oldPrice != null &&
                              product.oldPrice! > product.price)
                            Wrap( // Dùng Wrap thay vì Row để tự xuống dòng nếu giá cũ quá dài
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Text(
                                  "${priceFormatter.format(product.oldPrice)} VND",
                                  style: TextStyle(
                                    fontSize: 11, // Giảm size chữ giá cũ
                                    decoration: TextDecoration.lineThrough,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "-${((product.oldPrice! - product.price) / product.oldPrice! * 100).round()}%",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Khoảng cách nhỏ giữa giá và nút
                    const SizedBox(width: 8),

                    // Bộ tăng giảm số lượng (Giữ nguyên kích thước cố định)
                    Container(
                      height: 30, // Giảm chiều cao một chút cho gọn
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            iconSize: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.remove,
                              color: item.quantity > 1
                                  ? (isDark ? Colors.white : Colors.black)
                                  : Colors.grey,
                            ),
                            onPressed: item.quantity > 1
                                ? () => controller.decreaseQuantity(item)
                                : null,
                          ),
                          Text(
                            item.quantity.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          IconButton(
                            iconSize: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.add,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            onPressed: () => controller.increaseQuantity(item),
                          ),
                        ],
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

  // --- WIDGET: CART SUMMARY ---
  Widget _buildCartSummary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceFormatter = NumberFormat("#,###", "vi_VN");

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dòng tổng cộng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text(
                      'Total (${controller.itemCount.value} items):',
                      style: AppTextStyles.withColor(
                        AppTextStyles.bodyLarge,
                        isDark ? Colors.grey[300]! : Colors.grey[700]!,
                      ),
                    )),
                Obx(() => Text(
                      '${priceFormatter.format(controller.total.value)} đ',
                      style: AppTextStyles.withColor(
                        AppTextStyles.h2,
                        isDark ? Colors.white : Colors.black,
                      ).copyWith(fontWeight: FontWeight.bold),
                    )),
              ],
            ),
            const SizedBox(height: 20),

            // Hàng nút bấm
            Row(
              children: [
                // Nút Xóa hết (Clear All)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showClearCartConfirmationDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Nút Checkout
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.to(() =>  CheckoutScreen()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Checkout',
                      style: AppTextStyles.withColor(
                        AppTextStyles.buttonMedium,
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOGS ---
  void _showClearCartConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text('Are you sure you want to remove all items?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Clear All', style: TextStyle(color: Colors.red)),
              onPressed: () {
                controller.clearCart();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, CartItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: const Text('Are you sure you want to remove this item?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
              onPressed: () {
                controller.removeItem(item);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}