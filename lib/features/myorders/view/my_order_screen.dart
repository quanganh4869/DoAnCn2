import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/controller/order_controller.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/features/myorders/view/order_card.dart';
import 'package:ecomerceapp/features/myorders/view/my_order_details_screen.dart';

class MyOrderScreen extends StatelessWidget {
  MyOrderScreen({super.key});

  final OrderController controller = Get.find<OrderController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          ),
          title: Text(
            "My Orders",
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)
          ),
          centerTitle: true,
          bottom: TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: "Active"),
              Tab(text: "Completed"),
              Tab(text: "Cancelled"),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter orders for each tab
          final activeList = controller.allOrders.where((o) =>
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled
          ).toList();

          final completedList = controller.allOrders.where((o) =>
            o.status == OrderStatus.completed
          ).toList();

          final cancelledList = controller.allOrders.where((o) =>
            o.status == OrderStatus.cancelled
          ).toList();

          return TabBarView(
            children: [
              // Tab Active: Có thể hủy nếu chưa giao hàng
              _buildOrderList(context, activeList, "No active orders", allowDeleteAction: true),
              // Tab Completed: Có thể xóa lịch sử
              _buildOrderList(context, completedList, "No completed orders", allowDeleteAction: true),
              // Tab Cancelled: Có thể xóa lịch sử
              _buildOrderList(context, cancelledList, "No cancelled orders", allowDeleteAction: true),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<Order> orders, String emptyMsg, {bool allowDeleteAction = false}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(emptyMsg, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => await controller.fetchOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];

          bool canDelete = false;
          if (allowDeleteAction) {
            if (order.status == OrderStatus.shipping || order.status == OrderStatus.delivering) {
              canDelete = false;
            } else {
              canDelete = true;
            }
          }

          return OrderCard(
            order: order,
            // Chỉ truyền callback onDelete nếu đủ điều kiện
            onDelete: canDelete ? () => _showDeleteConfirmDialog(context, order) : null,
            onViewDetails: () {
              Get.to(() => MyOrderDetailsScreen(order: order));
            },
          );
        },
      ),
    );
  }

  // Show Confirmation Dialog
  void _showDeleteConfirmDialog(BuildContext context, Order order) {
    final isPending = order.status == OrderStatus.pending || order.status == OrderStatus.confirmed;
    final actionText = isPending ? "Cancel Order" : "Delete History";
    final contentText = isPending
        ? "Are you sure you want to cancel this order?"
        : "Are you sure you want to remove this order from your history?";

    Get.dialog(
      AlertDialog(
        title: Text(actionText),
        content: Text(contentText),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteOrder(order.id);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}