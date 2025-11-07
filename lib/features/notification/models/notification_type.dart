enum NotificationType {order, delivery, promo, payment}
class NotificationItem{
  final NotificationType type;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;

  NotificationItem({
    required this.type,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
  });
}