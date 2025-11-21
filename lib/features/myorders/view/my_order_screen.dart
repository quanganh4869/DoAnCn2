import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/controller/order_controller.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/features/myorders/view/order_card.dart';


class MyOrderScreen extends StatelessWidget {
  MyOrderScreen({super.key});

  final OrderController controller = Get.put(OrderController());

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
          title: Text("My Orders", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Active"),    // Gồm: Pending, Confirmed, Shipping, Delivering
              Tab(text: "Completed"), // Gồm: Completed
              Tab(text: "Cancelled"), // Gồm: Cancelled
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // LỌC DATA CHO CÁC TAB
          // Tab 1: Active (Tất cả trạng thái đang xử lý)
          final activeList = controller.allOrders.where((o) =>
            o.status != OrderStatus.completed && o.status != OrderStatus.cancelled
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
              _buildOrderList(context, activeList),
              _buildOrderList(context, completedList),
              _buildOrderList(context, cancelledList),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<Order> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text("No orders found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: orders.length,
      itemBuilder: (context, index) => OrderCard(
        order: orders[index], // Đảm bảo OrderCard nhận Order
        onViewDetails: () {
          // Navigate to Detail
        },
      ),
    );
  }
}