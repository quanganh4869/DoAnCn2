import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/features/notification/view/notification_utils.dart';
import 'package:ecomerceapp/features/notification/models/notification_type.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(notification.date);
    final priceFormatter = NumberFormat("#,###", "vi_VN");
    final metadata = notification.metadata ?? {};
    final orderId = metadata['orderId']?.toString();

    List<dynamic> items = [];
    if (metadata['items'] != null && metadata['items'] is List) {
      items = metadata['items'] as List;
    } else if (metadata.containsKey('productName')) {
      items.add(metadata);
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Chi tiết thông báo"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NotificationUtils.getIconBackgroundColor(context, notification.type),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    NotificationUtils.getNotificationIcon(notification.type),
                    color: NotificationUtils.getIconColor(context, notification.type),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        notification.type.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            Text(
              notification.title,
              style: AppTextStyles.withColor(
                AppTextStyles.h3,
                isDark ? Colors.white : Colors.black87,
              ).copyWith(height: 1.3, fontSize: 22),
            ),

            const SizedBox(height: 16),

            // MESSAGE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                notification.message,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (items.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Sản phẩm ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.grey[800]
                      ),
                    ),
                    if (orderId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Đơn hàng #$orderId",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                  ],
                ),
              ),

              ...items.map((item) {
                String priceDisplay = '';
                if (item['price'] != null) {
                  if (item['price'] is num) {
                    priceDisplay = priceFormatter.format(item['price']);
                  }
                  else {
                    String priceString = item['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
                    double? priceNum = double.tryParse(priceString);
                    if (priceNum != null) {
                       priceDisplay = "${priceFormatter.format(priceNum)} VND";
                    } else {
                       priceDisplay = item['price'].toString();
                    }
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.grey[100],
                          height: 70,
                          width: 70,
                          child: Image.network(
                            item['productImage']?.toString() ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['productName']?.toString() ?? 'Sản phẩm',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (item['size'] != null || item['color'] != null)
                              Text(
                                "Size: ${item['size'] ?? '-'} | Màu: ${item['color'] ?? '-'}",
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  " Số Lượng: ${item['quantity'] ?? 1}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Spacer(),
                                Text(
                                  priceDisplay,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
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
              }),
            ]
          ],
        ),
      ),
    );
  }
}