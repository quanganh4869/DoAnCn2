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
      ),
      // Obx LỚN nhất bao trùm body để lắng nghe thay đổi của list cartItems
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

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

        return Column(
          children: [
            // Danh sách sản phẩm
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: controller.cartItems.length,
                separatorBuilder: (ctx, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  // Lấy item ra
                  final item = controller.cartItems[index];
                  return _buildCartItem(context, item);
                },
              ),
            ),
            // Phần tổng tiền (Summary)
            _buildCartSummary(context),
          ],
        );
      }),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceFormatter = NumberFormat("#,###", "vi_VN");

    // FIX 1: Lấy product từ item ra biến cục bộ để dễ xử lý
    final product = item.product;

    // Nếu dữ liệu sản phẩm bị null thì trả về rỗng để tránh crash app
    if (product == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 16), // Thêm khoảng cách dưới
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
              product.primaryImage,
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

          // 2. Thông tin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: Tên + Nút xóa
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
                        padding: const EdgeInsets.all(4.0),
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
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(
                      "Size: ${item.selectedSize}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Hàng 2: Giá + Nút tăng giảm
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cột Giá Tiền (FIX: Dùng biến product thay vì widget.product)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${priceFormatter.format(product.price)} VND",
                          style: AppTextStyles.withColor(
                            AppTextStyles.h2,
                            Theme.of(context).textTheme.headlineMedium!.color!,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        // Logic hiển thị giá cũ
                        if (product.oldPrice != null &&
                            product.oldPrice! > product.price) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "${priceFormatter.format(product.oldPrice)} VND",
                                style:
                                    AppTextStyles.withColor(
                                      AppTextStyles.bodySmall,
                                      isDark
                                          ? Colors.grey[400]!
                                          : Colors.grey[600]!,
                                    ).copyWith(
                                      decoration: TextDecoration.lineThrough,
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
                                  "${((product.oldPrice! - product.price) / product.oldPrice! * 100).round()}% OFF",
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

                    // Bộ điều khiển số lượng
                    Container(
                      height: 32,
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

  // ... (Các phần code khác giữ nguyên)

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
            // Dòng tổng tiền
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
            
            // Hàng chứa 2 nút: Clear Cart & Checkout
            Row(
              children: [
                // --- NÚT CLEAR CART (Màu trắng) ---
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showClearCartConfirmationDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.grey[800] : Colors.white, // Nền trắng (hoặc xám tối nếu dark mode)
                      foregroundColor: Colors.red, // Chữ đỏ
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      side: const BorderSide(color: Colors.red, width: 1), // Viền đỏ
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete All',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16), // Khoảng cách giữa 2 nút

                // --- NÚT CHECKOUT ---
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.to(() => CheckoutScreen()),
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

  // Hàm hiển thị hộp thoại xác nhận xóa tất cả
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
                // Gọi hàm clearCart trong controller
                // Lưu ý: Đảm bảo controller có hàm clearCart không cần tham số hoặc tự lấy userId
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
