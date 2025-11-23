import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/seller_dasboard/controller/seller_controller.dart';

// Import the standard Order Model
// Import the Seller Controller

class ManageOrdersScreen extends StatelessWidget {
  ManageOrdersScreen({super.key});

  // Find the existing SellerController (initialized in your dashboard binding)
  final SellerController controller = Get.find<SellerController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Shop Orders"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchSellerOrders(),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text("No orders yet.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.orders.length,
          itemBuilder: (context, index) {
            final order = controller.orders[index];
            return _buildOrderCard(context, order);
          },
        );
      }),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate);

    final double shopTotal = order.items.fold(0, (sum, item) => sum + (item.price * item.quantity));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Auto-expand if the order is pending action
        initiallyExpanded: order.status == OrderStatus.pending,

        // 1. HEADER: Order Number, Status, Date
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Placed on: $dateStr",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        subtitle: Text(
          "Customer ID: ${order.userId.substring(0, 8)}...",
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),

        // 2. BODY: Product Details & Actions
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shipping Info
                if (order.shippingAddress != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${order.shippingAddress!.fullAddress}, ${order.shippingAddress!.city}",
                          style: const TextStyle(fontSize: 13, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                ],

                const Text("Items to Pack:",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),

                // Product List (Filtered for this Shop)
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      // Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item.productImage.isNotEmpty
                              ? item.productImage
                              : 'https://via.placeholder.com/50',
                          width: 50, height: 50, fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => Container(
                            width: 50, height: 50, color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Product Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Size: ${item.selectedSize ?? '-'} | Color: ${item.selectedColor ?? '-'}",
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Qty: ${item.quantity}  x  \$${item.price}",
                              style: TextStyle(
                                fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),

                const Divider(),

                // Shop Total Income
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text("Your Income: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      "\$${shopTotal.toStringAsFixed(2)}", // Shows calculated shop total
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Action Buttons
                _buildActionButtons(context, order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Status Badge
  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    String text;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange; text = "Pending"; break;
      case OrderStatus.confirmed:
        color = Colors.blue; text = "Confirmed"; break;
      case OrderStatus.shipping:
        color = Colors.purple; text = "Shipping"; break;
      case OrderStatus.delivering:
        color = Colors.indigo; text = "Delivering"; break;
      case OrderStatus.completed:
        color = Colors.green; text = "Completed"; break;
      case OrderStatus.cancelled:
        color = Colors.red; text = "Cancelled"; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Action Buttons Logic
  Widget _buildActionButtons(BuildContext context, Order order) {
    if (order.status == OrderStatus.cancelled || order.status == OrderStatus.completed) {
      return const SizedBox.shrink(); // No actions for finished orders
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Cancel Button (Visible unless Completed)
        OutlinedButton(
          onPressed: () => _confirmAction(context, "Cancel Order",
            "Are you sure you want to cancel this order?",
            () => controller.changeOrderStatus(order, OrderStatus.cancelled)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
          child: const Text("Cancel"),
        ),

        const SizedBox(width: 12),

        // Main Status Action
        if (order.status == OrderStatus.pending)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white
            ),
            onPressed: () => _confirmAction(context, "Confirm & Pack",
              "This will deduct stock from your inventory. Continue?",
              () => controller.changeOrderStatus(order, OrderStatus.confirmed)),
            child: const Text("Confirm"),
          )

        else if (order.status == OrderStatus.confirmed)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white
            ),
            onPressed: () => controller.changeOrderStatus(order, OrderStatus.shipping),
            child: const Text("Ship Order"),
          )

        else if (order.status == OrderStatus.shipping)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white
            ),
            onPressed: () => controller.changeOrderStatus(order, OrderStatus.delivering),
            child: const Text("Start Delivery"),
          )

        else if (order.status == OrderStatus.delivering)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white
            ),
            onPressed: () => _confirmAction(context, "Complete Order",
              "Confirm customer has received the package?",
              () => controller.changeOrderStatus(order, OrderStatus.completed)),
            child: const Text("Mark Delivered"),
          ),
      ],
    );
  }

  void _confirmAction(BuildContext context, String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text("Yes")
          ),
        ],
      ),
    );
  }
}