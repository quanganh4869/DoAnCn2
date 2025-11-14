import 'package:ecomerceapp/models/product.dart';

class WishlistItem {
  final String id;
  final String userId;
  final String productId;
  final Products product;
  final DateTime addedAt;
  final Map<String, dynamic> metadata;

  const WishlistItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.addedAt,
    required this.product,
    this.metadata = const {},
  });

  Map<String, dynamic> toSupbasestore() {
    return {
      "user_id": userId,
      "product_id": productId,
      "product": product.toJson(), 
      "added_at": addedAt.toIso8601String(),
      "metadata": metadata,
    };
  }

  factory WishlistItem.fromSupabaseJson(Map<String, dynamic> data, String id) {
    return WishlistItem(
      id: id,
      userId: data["user_id"] ?? "",
      productId: data["product_id"] ?? "",
      product: Products.fromSupabaseJson(
        Map<String, dynamic>.from(data["product"] ?? {}),
        data["product_id"] ?? "",
      ),
      addedAt: DateTime.tryParse(data["added_at"] ?? "") ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data["metadata"] ?? {}),
    );
  }

  @override
  String toString() => "Wishlist(${product.name})";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WishlistItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
