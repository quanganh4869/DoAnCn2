import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/controller/order_controller.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/features/myorders/view/order_card.dart';

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
              Tab(text: "Active"),    // Pending, Confirmed, Shipping, Delivering
              Tab(text: "Completed"), // Completed
              Tab(text: "Cancelled"), // Cancelled
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // FILTER DATA FOR TABS

          // Tab 1: Active (Processing states)
          final activeList = controller.allOrders.where((o) =>
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled
          ).toList();

          // Tab 2: Completed
          final completedList = controller.allOrders.where((o) =>
            o.status == OrderStatus.completed
          ).toList();

          // Tab 3: Cancelled
          final cancelledList = controller.allOrders.where((o) =>
            o.status == OrderStatus.cancelled
          ).toList();

          return TabBarView(
            children: [
              _buildOrderList(context, activeList, "No active orders"),
              _buildOrderList(context, completedList, "No completed orders"),
              _buildOrderList(context, cancelledList, "No cancelled orders"),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<Order> orders, String emptyMsg) {
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
        itemBuilder: (context, index) => OrderCard(
          order: orders[index],
          onViewDetails: () {
            // Navigate to Order Detail Screen here
            // Get.to(() => OrderDetailScreen(order: orders[index]));
          },
        ),
      ),
    );
  }
}