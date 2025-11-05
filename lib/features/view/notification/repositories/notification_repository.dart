import 'package:ecomerceapp/features/view/notification/models/notification_type.dart';

class NotificationRepository {
  List<NotificationItem> getNotifications() {
    return  [
      NotificationItem(
        title: 'New Order Received',
        message: 'You have received a new order #12345.',
        date: DateTime(2024, 6, 1, 10, 0),
        type: NotificationType.order,
        isRead: true,
      ),
      NotificationItem(
        title: 'Order Shipped',
        message: 'Your order #12345 has been shipped.',
        date: DateTime(2024, 6, 2, 14, 30),
        type: NotificationType.delivery,
      ),
      NotificationItem(
        title: 'Summer Sale!',
        message: 'Get up to 50% off on selected items during our summer sale.',
        date: DateTime(2024, 6, 3, 9, 0),
        type: NotificationType.promo,
      ),
      NotificationItem(
        title: 'Payment Successful',
        message: 'Your payment for order #12345 was successful.',
        date: DateTime(2024, 6, 4, 16, 45),
        type: NotificationType.payment,
        isRead: true,
      ),
    ];
  }
}
