class UserProfile {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? gender;
  final String? userImage;
  final String? role;
  final bool? isActive; // <--- THÊM: Trạng thái hoạt động (cho Admin chặn/mở chặn)
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.gender,
    this.userImage,
    this.role,
    this.isActive, // <--- THÊM
    required this.createdAt,
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
      // Ánh xạ trạng thái hoạt động từ cột 'is_active'
      isActive: (json['is_active'] ?? json['isActive'] ?? true) as bool, // Mặc định là true
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
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
      'is_active': isActive, // <--- THÊM
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Phương thức copyWith giúp update trạng thái isActive trong Controller
  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? gender,
    String? userImage,
    String? role,
    bool? isActive, // <--- THÊM
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      userImage: userImage ?? this.userImage,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive, // <--- THÊM
      createdAt: createdAt ?? this.createdAt,
    );
  }
}