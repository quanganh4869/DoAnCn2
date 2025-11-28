import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/cart_item.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/cart_controller.dart';

class OrderSummaryCard extends StatelessWidget {
  OrderSummaryCard({super.key});
  final CartController cartController = Get.find<CartController>();
  final priceFormatter = NumberFormat("#,###", "vi_VN");

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cartController.cartItems.isNotEmpty) ...[
              ...cartController.cartItems.map(
                (item) => _buildProductItem(context, item),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, thickness: 1),
              ),
            ],

            _buildSummaryRow(
              context,
              "Đơn giá",
              "${priceFormatter.format(cartController.subtotal.value)} VND",
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              "Tiền ship",
              "${priceFormatter.format(cartController.shipping.value)} VND",
            ),

            // // Chỉ hiện Discount nếu có tiết kiệm
            // if (cartController.saving.value > 0) ...[
            //   const SizedBox(height: 8),
            //   _buildSummaryRow(
            //     context,
            //     "Discount",
            //     "-${priceFormatter.format(cartController.saving.value)} VND",
            //     isDiscount: true,
            //   ),
            // ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),

            _buildSummaryRow(
              context,
              "Tổng",
              "${priceFormatter.format(cartController.total.value)} VND",
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, CartItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              image:
                  (item.product?.images != null &&
                      item.product!.images.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(item.product!.images[0]),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child:
                (item.product?.images == null || item.product!.images.isEmpty)
                ? Icon(
                    Icons.image_not_supported,
                    size: 30,
                    color: Colors.grey[400],
                  )
                : null,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product?.name ?? "Unknown Product",
                  style: AppTextStyles.withColor(
                    AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (item.selectedSize != null || item.selectedColor != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "${item.selectedColor ?? ''} ${item.selectedSize != null ? '• ${item.selectedSize}' : ''}"
                          .trim(),
                      style: AppTextStyles.withColor(
                        AppTextStyles.bodySmall,
                        Colors.grey,
                      ),
                    ),
                  ),

                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${priceFormatter.format(item.product?.price ?? 0)} VND",
                      style: AppTextStyles.withColor(
                        AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      "Số lượng: ${item.quantity}",
                      style: AppTextStyles.withColor(
                        AppTextStyles.bodyMedium,
                        Colors.grey,
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

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    final textStyle = isTotal ? AppTextStyles.h3 : AppTextStyles.bodyLarge;

    Color textColor;
    if (isTotal) {
      textColor = Theme.of(context).primaryColor;
    } else if (isDiscount) {
      textColor = Colors.green;
    } else {
      textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.withColor(
            textStyle,
            Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
        Text(value, style: AppTextStyles.withColor(textStyle, textColor)),
      ],
    );
  }
}
