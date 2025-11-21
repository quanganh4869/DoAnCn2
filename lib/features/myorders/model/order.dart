import 'package:ecomerceapp/features/shippingaddress/models/address.dart';

// Mở rộng trạng thái đơn hàng
enum OrderStatus {
  pending,    // Chờ xác nhận
  confirmed,  // Đã xác nhận (Seller đã nhận đơn)
  shipping,   // Giao cho vận chuyển
  delivering, // Shipper đang giao
  completed,  // Giao thành công
  cancelled   // Hủy/Thất bại
}

class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final double totalAmount;
  final OrderStatus status;
  final DateTime orderDate;
  final Address? shippingAddress;

  // Dữ liệu hiển thị
  final String imageUrl;
  final int itemCount;

  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.shippingAddress,
    this.imageUrl = '',
    this.itemCount = 0,
  });

  // Helper chuyển String sang Enum
  static OrderStatus _parseStatus(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => OrderStatus.pending,
    );
  }

  factory Order.fromSupabaseJson(Map<String, dynamic> json) {
    String img = '';
    int count = 0;

    // Xử lý lấy ảnh và số lượng từ order_items
    if (json['order_items'] != null && (json['order_items'] as List).isNotEmpty) {
      final items = json['order_items'] as List;
      count = items.length;

      // Lấy ảnh sản phẩm đầu tiên làm đại diện
      final firstItem = items[0];
      if (firstItem['products'] != null && firstItem['products']['images'] != null) {
        final images = firstItem['products']['images'] as List;
        if (images.isNotEmpty) img = images[0];
      }
    }

    return Order(
      id: json['id'].toString(),
      orderNumber: json['order_number'] ?? '',
      userId: json['user_id'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: _parseStatus(json['status'] ?? 'pending'),
      orderDate: DateTime.tryParse(json['created_at']) ?? DateTime.now(),
      imageUrl: img,
      itemCount: count,
      shippingAddress: json['shipping_address'] != null
          ? Address.fromJson(json['shipping_address'])
          : null,
    );
  }

  String get statusString {
    switch (status) {
      case OrderStatus.pending: return "Pending Confirmation";
      case OrderStatus.confirmed: return "Confirmed";
      case OrderStatus.shipping: return "Handed to Carrier";
      case OrderStatus.delivering: return "Shipper is Delivering";
      case OrderStatus.completed: return "Completed";
      case OrderStatus.cancelled: return "Cancelled/Failed";
    }
  }
}