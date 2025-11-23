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

    // Xử lý ảnh an toàn
    final ImageProvider imageProvider = (order.imageUrl.isNotEmpty)
        ? NetworkImage(order.imageUrl)
        : const AssetImage('assets/images/placeholder.png') as ImageProvider; // Đảm bảo bạn có ảnh placeholder hoặc dùng Icon thay thế

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
                // Ảnh sản phẩm
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Colors.grey[200], // Màu nền nếu ảnh lỗi
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

                // Thông tin chi tiết
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order #${order.orderNumber}",
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
                      // Truyền status Enum để logic màu chính xác hơn
                      _buildStatusChip(context, order.status),
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
    Color getStatusColor() {
      switch (status) {
        case OrderStatus.pending:
        case OrderStatus.confirmed:
        case OrderStatus.shipping:
        case OrderStatus.delivering:
          return Colors.blue;
        case OrderStatus.completed:
          return Colors.green;
        case OrderStatus.cancelled:
          return Colors.red;
      }
    }

    // Lấy text hiển thị từ Model
    String statusText = "";
    switch (status) {
      case OrderStatus.pending: statusText = "Pending"; break;
      case OrderStatus.confirmed: statusText = "Confirmed"; break;
      case OrderStatus.shipping: statusText = "Shipping"; break;
      case OrderStatus.delivering: statusText = "Delivering"; break;
      case OrderStatus.completed: statusText = "Completed"; break;
      case OrderStatus.cancelled: statusText = "Cancelled"; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        statusText.capitalize!,
        style: AppTextStyles.withColor(
          AppTextStyles.bodySmall,
          getStatusColor(),
        ),
      ),
    );
  }
}