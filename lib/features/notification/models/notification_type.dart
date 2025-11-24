enum NotificationType { order, delivery, promo, payment }

class NotificationItem {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.metadata,
  });

  factory NotificationItem.fromSupabaseJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      date: DateTime.parse(json['created_at']).toLocal(),
      type: _parseType(json['type']),
      // Fix: Kiểm tra kỹ kiểu dữ liệu của metadata
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  static NotificationType _parseType(String? type) {
    return NotificationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NotificationType.order,
    );
  }
}