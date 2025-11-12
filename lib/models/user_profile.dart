class UserProfile {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? gender;
  final String? userImage;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.gender,
    this.userImage,
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
      'created_at': createdAt.toIso8601String(),
    };
  }
}
