import 'package:ecomerceapp/models/product.dart';

class CartItem {
  final String id;
  final String userId;
  final String productId;
  final Products? product;
  final int quantity;
  final String? selectedSize;
  final String? selectedColor;
  final Map<String, dynamic> customizations;
  final DateTime? addedAt;
  final DateTime? updatedAt;

  const CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.product,
    required this.quantity,
    this.selectedSize,
    this.selectedColor,
    this.customizations = const {},
    required this.addedAt,
    required this.updatedAt,
  });

  factory CartItem.fromSupabaseJson(Map<String, dynamic> data, String id) {
    // --- FIX LỖI TẠI ĐÂY ---
    // Supabase trả về key là "products" (tên bảng), nhưng đôi khi chúng ta nhầm là "product".
    // Dòng này sẽ thử lấy "products" trước, nếu null thì thử "product".
    final productData = data["products"] ?? data["product"]; 

    return CartItem(
      id: (data['id'] ?? id).toString(),
      userId: (data["userId"] ?? data["user_id"] ?? "").toString(),
      productId: (data["productId"] ?? data["product_id"] ?? "").toString(),
      
      // Parse thông tin sản phẩm
      product: productData != null
          ? Products.fromSupabaseJson(
              Map<String, dynamic>.from(productData),
              (productData["id"] ?? "").toString(),
            )
          : null,
          
      quantity: (data["quantity"] ?? 1) is int
          ? data["quantity"]
          : int.tryParse(data["quantity"].toString()) ?? 1,
          
      selectedSize: data["selectedSize"] ?? data["selected_size"],
      selectedColor: data["selectedColor"] ?? data["selected_color"],
      
      // Xử lý customizations (nếu database chưa có cột này thì trả về map rỗng để tránh lỗi)
      customizations: data["customizations"] != null 
          ? Map<String, dynamic>.from(data["customizations"]) 
          : {},
          
      addedAt: data["added_at"] != null
          ? DateTime.tryParse(data["added_at"].toString())
          : null,
      updatedAt: data["updated_at"] != null
          ? DateTime.tryParse(data["updated_at"].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": userId,
      "product_id": productId,
      "quantity": quantity,
      "selected_size": selectedSize,
      "selected_color": selectedColor,
      // Nếu DB bạn đã tạo cột customizations thì bỏ comment dòng dưới, chưa tạo thì comment lại
      "customizations": customizations, 
      "added_at": addedAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }

  double get totalPrice => (product?.price ?? 0) * quantity;

  double get savings {
    if (product?.oldPrice != null &&
        product!.oldPrice! > (product?.price ?? 0)) {
      return (product!.oldPrice! - (product?.price ?? 0)) * quantity;
    }
    return 0.0;
  }

  // Hàm copyWith để update state dễ dàng
  CartItem copyWith({
    String? id,
    String? userId,
    String? productId,
    Products? product,
    int? quantity,
    String? selectedSize,
    String? selectedColor,
    Map<String, dynamic>? customizations,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      customizations: customizations ?? this.customizations,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      "CartItem(product: ${product?.name ?? 'null'}, qty: $quantity)";
}