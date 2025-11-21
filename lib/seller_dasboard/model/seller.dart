class Seller {
  final String id;
  final String userId;
  final String shopName; // Vẫn giữ tên biến là shopName cho UI đỡ phải sửa nhiều
  final String? shopDescription;
  final String? businessEmail;
  final String? phoneNumber;
  final String? address;
  final String status;
  final String? avatarUrl;

  Seller({
    required this.id,
    required this.userId,
    required this.shopName,
    required this.status,
    this.shopDescription,
    this.businessEmail,
    this.phoneNumber,
    this.address,
    this.avatarUrl,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'].toString(),
      userId: json['user_id'] ?? '',
      // FIX: Lấy từ cột 'brand_name' thay vì 'shop_name'
      shopName: json['brand_name'] ?? json['shop_name'] ?? 'Unknown Shop',
      shopDescription: json['shop_description'],
      businessEmail: json['business_email'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      status: json['status'] ?? 'pending',
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      // FIX: Gửi lên với key 'brand_name'
      'brand_name': shopName,
      'shop_description': shopDescription,
      'business_email': businessEmail,
      'phone_number': phoneNumber,
      'address': address,
      'status': status,
    };
  }
}