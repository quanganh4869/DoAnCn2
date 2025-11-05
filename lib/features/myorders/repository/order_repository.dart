import 'package:ecomerceapp/features/myorders/model/order.dart';

class OrderRepository {
  List<Order> getOrders() {
    return [
      Order(
        OrderNumber: 'ORD123456',
        itemCount: 3,
        totalAmount: 150.75,
        status: OrderStatus.active,
        imageUrl: 'assets/images/laptop.jpg',
        orderDate: DateTime.now().subtract(Duration(hours: 2)),
      ),
      Order(
        OrderNumber: 'ORD123457',
        itemCount: 1,
        totalAmount: 50.00,
        status: OrderStatus.completed,
        imageUrl: 'assets/images/ao_thun_basic.jpg',
        orderDate: DateTime.now().subtract(Duration(hours: 10)),
      ),
      Order(
        OrderNumber: 'ORD123458',
        itemCount: 2,
        totalAmount: 80.25,
        status: OrderStatus.cancelled,
        imageUrl: 'assets/images/laptop.jpg',
        orderDate: DateTime.now().subtract(Duration(days: 5)),
      ),
    ];
  }

  List<Order> getOrdersByStatus(OrderStatus status) {
    return getOrders().where((order) => order.status == status).toList();
  }
}
