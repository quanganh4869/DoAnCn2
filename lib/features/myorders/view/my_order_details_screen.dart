import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';

class MyOrderDetailsScreen extends StatelessWidget {
  final Order order;

  const MyOrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(order.orderDate);

    final priceFormatter = NumberFormat("#,###", "vi_VN");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Order Information Header
            _buildSectionHeader("Order Information"),
            const SizedBox(height: 10),
            _buildInfoRow("Order ID", order.orderNumber),
            _buildInfoRow("Date", dateStr),
            _buildInfoRow("Status", order.statusString, isStatus: true),

            const Divider(height: 30),

            // 2. Shipping Address Section
            _buildSectionHeader("Shipping Address"),
            const SizedBox(height: 10),
            if (order.shippingAddress != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          order.shippingAddress!.label,
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${order.shippingAddress!.fullAddress}, ${order.shippingAddress!.city}",
                      style: TextStyle(color: Colors.grey[600], height: 1.4),
                    ),
                    const SizedBox(height: 4),
                    // Placeholder for phone if not in address model
                    Text(
                      "Phone: ${order.userId.substring(0, 4)}*** (User ID)",
                      style: TextStyle(color: Colors.grey[600])
                    ),
                  ],
                ),
              )
            else
            const Text("No shipping info available"),
            const Divider(height: 30),
            // 3. Product List Section
            _buildSectionHeader("Items (${order.itemCount})"),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.productImage.isNotEmpty
                            ? item.productImage
                            : 'https://via.placeholder.com/60',
                        width: 60, height: 60, fit: BoxFit.cover,
                        errorBuilder: (_,__,___) => Container(
                          width: 60, height: 60, color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Item Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Size: ${item.selectedSize ?? '-'}  |  Color: ${item.selectedColor ?? '-'}",
                            style: TextStyle(fontSize: 12, color: Colors.grey[500])
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Số lượng: ${item.quantity}",
                                style: const TextStyle(fontWeight: FontWeight.bold)
                              ),
                              Text(
                                "${priceFormatter.format(item.price)} VND",
                                style: const TextStyle(fontWeight: FontWeight.bold)
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const Divider(height: 30),

            // 4. Payment Summary Section
            _buildSectionHeader("Payment Summary"),
            const SizedBox(height: 10),
            _buildInfoRow("Subtotal", "${priceFormatter.format(order.totalAmount)} VND"),
            _buildInfoRow("Shipping Fee", "${priceFormatter.format(0)} VND"),
            const Divider(),
            _buildInfoRow(
              "Total",
              "${priceFormatter.format(order.totalAmount)} VND",
              isTotal: true
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false, bool isTotal = false}) {
    Color? textColor;
    if (isStatus) {
      // Use status color logic if needed, currently basic blue
      textColor = Colors.blue;
    } else if (isTotal) {
      textColor = Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isTotal ? 16 : 14
            )
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 18 : 14,
              color: textColor
            )
          ),
        ],
      ),
    );
  }
}