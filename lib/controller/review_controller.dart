import 'package:get/get.dart';
import 'package:ecomerceapp/models/review.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewController extends GetxController {
  final _supabase = Supabase.instance.client;

  var reviews = <Review>[].obs;
  var isLoading = false.obs;
  var averageRating = 0.0.obs;

  // Lấy danh sách Review theo Product ID
  Future<void> fetchReviews(dynamic productId) async {
    try {
      isLoading.value = true;
      print("📝 Đang tải Review cho Product ID: $productId");

      // Query bảng reviews và join với bảng users
      // Lưu ý: Nếu bảng user của bạn tên là 'profiles' thì đổi 'users' thành 'profiles'
      final response = await _supabase
          .from('reviews')
          .select('*, users(full_name, user_image)')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      print("✅ Tìm thấy ${data.length} đánh giá.");

      if (data.isNotEmpty) {
        print("   Mẫu dữ liệu đầu tiên: ${data[0]}");
      }

      reviews.value = data.map((e) => Review.fromSupabaseJson(e)).toList();

      _calculateAverage();

    } catch (e) {
      print("❌ LỖI TẢI REVIEW: $e");
      // Nếu lỗi do không join được bảng users, thử tải review thô không cần user info
      if (e.toString().contains("users") || e.toString().contains("relation")) {
         print("⚠️ Thử tải lại review không kèm thông tin user...");
         await _fetchRawReviews(productId);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Fallback: Tải review không cần join bảng user (để ít nhất hiện nội dung)
  Future<void> _fetchRawReviews(dynamic productId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select() // Không join users nữa
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      // Map thủ công, để user là Anonymous
      reviews.value = data.map((e) {
        // Fake thông tin user vì không join được
        e['users'] = {'full_name': 'Người dùng', 'user_image': ''};
        return Review.fromSupabaseJson(e);
      }).toList();

      _calculateAverage();
      print("✅ Đã tải được ${reviews.length} review thô (không có info user)");
    } catch (e) {
      print("❌ Vẫn lỗi khi tải raw review: $e");
    }
  }

  // Gửi Review mới
  Future<bool> addReview({
    required int productId,
    required int rating,
    String? comment, // Cho phép null (không bắt buộc)
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      Get.snackbar("Lỗi", "Vui lòng đăng nhập để đánh giá.");
      return false;
    }

    try {
      print("📝 Đang gửi đánh giá: User=${user.id}, Product=$productId, Rating=$rating");

      await _supabase.from('reviews').insert({
        'user_id': user.id,
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      });

      print("✅ Gửi đánh giá thành công!");

      // Refresh lại list sau khi thêm
      await fetchReviews(productId);
      return true;
    } catch (e) {
      print("❌ LỖI GỬI ĐÁNH GIÁ: $e");
      Get.snackbar("Lỗi", "Không thể gửi đánh giá: $e");
      return false;
    }
  }
  void _calculateAverage() {
    if (reviews.isEmpty) {
      averageRating.value = 0.0;
      return;
    }
    final total = reviews.fold(0, (sum, item) => sum + item.rating);
    averageRating.value = total / reviews.length;
  }
}