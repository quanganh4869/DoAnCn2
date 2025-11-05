import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/features/myorders/repository/order_repository.dart';
import 'package:ecomerceapp/features/myorders/view/screens/widgets/order_card.dart';

class MyOrderScreen extends StatelessWidget {
  final OrderRepository _repository = OrderRepository();
  MyOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          "My Orders",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(text: "Active"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _buildOrderList(context, OrderStatus.active),
          _buildOrderList(context, OrderStatus.completed),
          _buildOrderList(context, OrderStatus.cancelled),
        ],
      )
    );
  }
  Widget _buildOrderList(BuildContext context, OrderStatus status) {
    final orders = _repository.getOrdersByStatus(status);
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: orders.length,
      itemBuilder: (context, index) => OrderCard(
        order: orders[index],
         onViewDetails: () {  },),
    );
  }
}