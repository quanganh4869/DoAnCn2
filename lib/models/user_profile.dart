class UserProfile {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? gender;
  final String? userImage;
  final String? role; // 'user' hoặc 'admin'
  final String? createdAt;
  final bool? isActive;

  // --- THÔNG TIN SELLER (ĐÃ GỘP) ---
  final String? storeName;
  final String? storeDescription;
  final String? businessEmail; // Mới
  final String? shopPhone;     // Mới
  final String? shopAddress;   // Mới
  final String? sellerStatus;  // 'pending', 'active', 'rejected', 'none'

  UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.gender,
    this.userImage,
    this.role,
    this.createdAt,
    this.isActive,
    this.storeName,
    this.storeDescription,
    this.businessEmail,
    this.shopPhone,
    this.shopAddress,
    this.sellerStatus,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
      gender: json['gender'],
      userImage: json['user_image'],
      role: json['role'],
      createdAt: json['created_at'],
      isActive: json['is_active'],
      // Map các trường seller
      storeName: json['shop_name'], // Lưu ý: DB là shop_name
      storeDescription: json['shop_description'],
      businessEmail: json['business_email'],
      shopPhone: json['shop_phone'],
      shopAddress: json['shop_address'],
      sellerStatus: json['seller_status'] ?? 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'user_image': userImage,
      'role': role,
      'created_at': createdAt,
      'is_active': isActive,
      // Lưu các trường seller
      'shop_name': storeName,
      'shop_description': storeDescription,
      'business_email': businessEmail,
      'shop_phone': shopPhone,
      'shop_address': shopAddress,
      'seller_status': sellerStatus,
    };
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? gender,
    String? userImage,
    String? role,
    String? createdAt,
    bool? isActive,
    String? storeName,
    String? storeDescription,
    String? businessEmail,
    String? shopPhone,
    String? shopAddress,
    String? sellerStatus,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      userImage: userImage ?? this.userImage,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      storeName: storeName ?? this.storeName,
      storeDescription: storeDescription ?? this.storeDescription,
      businessEmail: businessEmail ?? this.businessEmail,
      shopPhone: shopPhone ?? this.shopPhone,
      shopAddress: shopAddress ?? this.shopAddress,
      sellerStatus: sellerStatus ?? this.sellerStatus,
    );
  }
}