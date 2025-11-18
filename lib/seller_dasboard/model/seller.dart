class Seller {
  final String id;
  final String userId;
  final String shopName;
  final String status; 

  Seller({required this.id, required this.userId, required this.shopName, required this.status});

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'],
      userId: json['user_id'],
      shopName: json['shop_name'],
      status: json['status'],
    );
  }
}