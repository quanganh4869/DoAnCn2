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

  // Dữ liệu Logic (BẮT BUỘC PHẢI CÓ ĐỂ TRỪ KHO)
  final List<OrderItem> items;

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
    required this.items, // Thêm vào constructor
  });

  // Helper chuyển String sang Enum
  static OrderStatus _parseStatus(String? status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (status?.toLowerCase() ?? ''),
      orElse: () => OrderStatus.pending,
    );
  }

  factory Order.fromSupabaseJson(Map<String, dynamic> json) {
    String img = '';
    int count = 0;
    List<OrderItem> parsedItems = [];

    // Xử lý lấy ảnh, số lượng VÀ danh sách chi tiết từ order_items
    if (json['order_items'] != null && (json['order_items'] as List).isNotEmpty) {
      final listData = json['order_items'] as List;
      count = listData.length;

      // 1. Map ra danh sách items để dùng cho logic trừ kho
      parsedItems = listData.map((e) => OrderItem.fromJson(e)).toList();

      // 2. Lấy ảnh sản phẩm đầu tiên làm đại diện (Logic cũ của bạn)
      final firstItem = listData[0];
      if (firstItem['products'] != null && firstItem['products']['images'] != null) {
        final images = firstItem['products']['images'] as List;
        if (images.isNotEmpty) img = images[0].toString();
      }
    }

    return Order(
      id: json['id'].toString(),
      orderNumber: json['order_number'] ?? '',
      userId: json['user_id'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: _parseStatus(json['status']),
      orderDate: DateTime.tryParse(json['created_at'])?.toLocal() ?? DateTime.now(),
      imageUrl: img,
      itemCount: count,
      items: parsedItems, // Gán list items
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

// === ĐÂY LÀ CLASS ORDERITEM BẠN ĐANG THIẾU ===
// (Đặt nó ở cuối file này để tiện quản lý)
class OrderItem {
  final String id;
  final int productId;
  final int quantity;
  final double price;
  final String? selectedSize;
  final String? selectedColor;

  // Thêm các trường phụ để hiển thị chi tiết sản phẩm
  final String productName;
  final String productImage;

  OrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.price,
    this.selectedSize,
    this.selectedColor,
    this.productName = '',
    this.productImage = '',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Xử lý dữ liệu Nested từ bảng products (do query select join)
    final productData = json['products'] as Map<String, dynamic>?;
    String name = 'Unknown Product';
    String img = '';

    if (productData != null) {
      name = productData['name'] ?? name;
      if (productData['images'] != null && (productData['images'] as List).isNotEmpty) {
        img = productData['images'][0].toString();
      }
    }

    return OrderItem(
      id: json['id'].toString(),
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 1,
      price: (json['price_at_purchase'] ?? 0).toDouble(),
      selectedSize: json['selected_size'],
      selectedColor: json['selected_color'],
      productName: name,
      productImage: img,
    );
  }
}