import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:intl/intl.dart'; // Import Intl for NumberFormat
import 'package:ecomerceapp/features/myorders/model/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onViewDetails;
  final VoidCallback? onDelete; // Nullable callback for delete action

  const OrderCard({
    super.key,
    required this.order,
    required this.onViewDetails,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Currency Formatter
    final priceFormatter = NumberFormat("#,###", "vi_VN");

    // Image handling with fallback
    final ImageProvider imageProvider = (order.imageUrl.isNotEmpty)
        ? NetworkImage(order.imageUrl)
        : const AssetImage('assets/images/placeholder.png') as ImageProvider;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- HEADER: Order ID + Delete Button ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order #${order.orderNumber}",
                  style: AppTextStyles.withColor(
                    AppTextStyles.h3,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
                // Only show delete icon if the callback is provided (based on status in parent)
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: onDelete,
                    tooltip: "Cancel/Delete Order",
                  ),
              ],
            ),
          ),

          // --- BODY: Image & Details ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Colors.grey[200],
                    image: order.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: order.imageUrl.isEmpty
                      ? const Icon(Icons.image_not_supported, color: Colors.grey)
                      : null,
                ),

                const SizedBox(width: 16.0),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Count & Total Price (Formatted)
                      Text(
                        "${order.itemCount} items - ${priceFormatter.format(order.totalAmount)} VND",
                        style: AppTextStyles.withColor(
                          AppTextStyles.bodyMedium,
                          isDark ? Colors.grey[400]! : Colors.grey[600]!,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      // Colored Status Chip
                      _buildStatusChip(context, order.status),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // --- FOOTER: View Details Button ---
          InkWell(
            onTap: onViewDetails,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Text(
                  "View Details",
                  style: AppTextStyles.withColor(
                    AppTextStyles.bodyMedium,
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, OrderStatus status) {
    Color color;
    String text;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = "Pending";
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        text = "Confirmed";
        break;
      case OrderStatus.shipping:
        color = Colors.purple;
        text = "Shipping";
        break;
      case OrderStatus.delivering:
        color = Colors.indigo;
        text = "Delivering";
        break;
      case OrderStatus.completed:
        color = Colors.green;
        text = "Completed";
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = "Cancelled";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        text.capitalize!, // Requires GetUtils
        style: AppTextStyles.withColor(
          AppTextStyles.bodySmall,
          color,
        ),
      ),
    );
  }
}