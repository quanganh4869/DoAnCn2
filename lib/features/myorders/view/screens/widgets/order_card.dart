import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onViewDetails;
  const OrderCard({
    super.key,
    required this.order,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    image: DecorationImage(
                      image: NetworkImage(order.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order #${order.OrderNumber}",
                        style: AppTextStyles.withColor(
                          AppTextStyles.h3,
                          Theme.of(context).textTheme.bodyLarge!.color!,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        "${order.itemCount} items - \$${order.totalAmount.toStringAsFixed(2)}",
                        style: AppTextStyles.withColor(
                          AppTextStyles.bodyMedium,
                          isDark ? Colors.grey[400]! : Colors.grey[600]!,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      _buildStatusChip(context, order.statusString),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),
          InkWell(
            onTap: onViewDetails,
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

  Widget _buildStatusChip(BuildContext context, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color getStatusColor() {
      switch (type) {
        case 'Active':
          return Colors.blue;
        case 'Completed':
          return Colors.green;
        case 'Cancelled':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        type.capitalize!,
        style: AppTextStyles.withColor(
          AppTextStyles.bodySmall,
          getStatusColor(),
        ),
      ),
    );
  }
}
