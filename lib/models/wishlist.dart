import 'package:ecomerceapp/models/product.dart';
class Wishlist {
  final String id;
  final String userId;
  final String productId;
  final Products product;
  final DateTime addedAt;
  final Map<String, dynamic> metadata;

  const Wishlist({
    required this.id,
    required this.userId,
    required this.productId,
    required this.addedAt,
    required this.product,
    this.metadata = const {},
  });

  factory Wishlist.fromSupabaseJson(Map<String, dynamic> data, String id) {
    return Wishlist(
      id: id,
      userId: data["userId"] ?? "",
      productId: data["productId"] ?? "",
      product: Products.fromSupabaseJson(
        Map<String, dynamic>.from(data["product"] ?? {}),
        data["productId"] ?? ""
      ),
      addedAt: DateTime.tryParse(data["addedAt"] ?? "") ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data["metadata"] ?? {}),
    );
  }

  Map<String, dynamic> toSupbasestore() {
    return {
      "userId": userId,
      "productId": productId,
      "product": product,
      "addedAt": addedAt.toIso8601String(),
      "metadata": metadata,
    };
  }

  @override
  String toString() => "Wishlist(${product.name})";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wishlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
