import 'package:supabase_flutter/supabase_flutter.dart';

class UserBehaviorService {
  static final _supabase = Supabase.instance.client;

  // Bảng điểm hành vi
  static const int SCORE_VIEW = 5;
  static const int SCORE_WISHLIST = 8;
  static const int SCORE_CART = 9;
  static const int SCORE_ORDER = 10;

  /// 1. Ghi nhận hành vi (TRACKING)
  /// Gọi hàm này ở các sự kiện tương ứng (onTap, AddToCart...)
  static Future<void> trackAction(String productId, String actionType) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    int score = 0;
    switch (actionType) {
      case 'view': score = SCORE_VIEW; break;
      case 'wishlist': score = SCORE_WISHLIST; break;
      case 'cart': score = SCORE_CART; break;
      case 'order': score = SCORE_ORDER; break;
      default: score = 1;
    }

    try {
      // Ghi log hành vi (Fire & Forget - không cần await để UI mượt)
      _supabase.from('user_behaviors').insert({
        'user_id': userId,
        'product_id': productId,
        'action_type': actionType,
        'score': score,
      }).then((_) => print("📡 Tracked: $actionType on $productId (+$score)"));
    } catch (e) {
      print("Tracking Error: $e");
    }
  }

  /// 2. Lấy danh sách ID sản phẩm user quan tâm nhất (để làm seed cho AI)
  static Future<List<String>> getTopInterests() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // Gọi hàm RPC đã tạo trong SQL
      final List<dynamic> response = await _supabase.rpc(
        'get_top_user_interests',
        params: {'_user_id': userId}
      );

      return response.map((e) => e['product_id'].toString()).toList();
    } catch (e) {
      print("Get Interests Error: $e");
      return [];
    }
  }
}