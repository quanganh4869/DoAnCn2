class Review {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final int productId;
  final int rating;
  final String? comment; // Cho phép null
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.productId,
    required this.rating,
    this.comment, // Nullable
    required this.createdAt,
  });

  factory Review.fromSupabaseJson(Map<String, dynamic> json) {
    String name = "Anonymous";
    String avatar = "";

    // Xử lý thông tin user từ quan hệ bảng (joined table 'users')
    if (json['users'] != null) {
      name = json['users']['full_name'] ?? "Unknown User";
      avatar = json['users']['user_image'] ?? "";
    }

    return Review(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: name,
      userAvatar: avatar,
      // Xử lý an toàn cho productId (có thể là int hoặc string từ DB)
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id'].toString()) ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'], // Lấy giá trị gốc (có thể null)
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}