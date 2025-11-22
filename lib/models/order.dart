import 'package:ecomerceapp/features/shippingaddress/models/address.dart';

/// Định nghĩa các trạng thái đơn hàng khớp với Database và Logic Controller
enum OrderStatus {
  pending,    // Chờ xác nhận
  confirmed,  // Đã xác nhận
  shipping,   // Đang lấy hàng
  delivering, // Đang giao
  completed,  // Giao thành công
  cancelled,  // Đã hủy
}

class Order {
  final String id;
  final String userId;
  final String orderNumber;
  final double totalAmount;
  final OrderStatus status;
  final Address? shippingAddress;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    this.shippingAddress,
    required this.createdAt,
    required this.items,
  });

  // Factory convert từ JSON của Supabase về Object
  factory Order.fromSupabaseJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      // Xử lý an toàn cho số thực/nguyên
      totalAmount: (json['total_amount'] is int)
          ? (json['total_amount'] as int).toDouble()
          : (json['total_amount'] ?? 0.0),

      // Parse String sang Enum
      status: _parseStatus(json['status']),

      // Parse JSONB address từ Database thành Object Address
      shippingAddress: json['shipping_address'] != null
          ? Address.fromJson(json['shipping_address'])
          : null,

      createdAt: DateTime.parse(json['created_at']).toLocal(),

      // Map danh sách items (nếu query có join)
      items: (json['order_items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  // Helper chuyển String từ DB sang Enum
  static OrderStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'shipping':
        return OrderStatus.shipping;
      case 'delivering':
        return OrderStatus.delivering;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  // Helper hiển thị Text đẹp trên UI
  String get statusText {
    switch (status) {
      case OrderStatus.pending: return "Pending";
      case OrderStatus.confirmed: return "Confirmed";
      case OrderStatus.shipping: return "Shipping";
      case OrderStatus.delivering: return "Delivering";
      case OrderStatus.completed: return "Completed";
      case OrderStatus.cancelled: return "Cancelled";
    }
  }
}

class OrderItem {
  final String id; // id của dòng order_item
  final int productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double price;
  final String? selectedSize;
  final String? selectedColor;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.price,
    this.selectedSize,
    this.selectedColor,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Xử lý dữ liệu Nested từ bảng products (do query select join)
    final productData = json['products'] as Map<String, dynamic>?;

    // Lấy ảnh đầu tiên trong mảng images, nếu không có thì lấy string rỗng
    String img = '';
    if (productData != null && productData['images'] != null) {
      final List<dynamic> imgs = productData['images'];
      if (imgs.isNotEmpty) {
        img = imgs.first.toString();
      }
    }

    return OrderItem(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? 0,
      // Lấy tên từ bảng products join vào
      productName: productData?['name'] ?? 'Unknown Product',
      productImage: img,
      quantity: json['quantity'] ?? 1,
      price: (json['price_at_purchase'] is int)
          ? (json['price_at_purchase'] as int).toDouble()
          : (json['price_at_purchase'] ?? 0.0),
      selectedSize: json['selected_size'],
      selectedColor: json['selected_color'],
    );
  }
}