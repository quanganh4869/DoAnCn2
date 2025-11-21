import 'package:ecomerceapp/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSupabaseServices {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableName = 'users'; // Tên bảng người dùng trong Supabase

  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _supabase.from(_tableName).insert(profile.toJson());
    } catch (e) {
      print('[_createUserProfile] Error creating user profile: $e');
      rethrow;
    }
  }

  Future<UserProfile?> getUserProfileById(String userId) async {
    try {
      final data = await _supabase
          .from(_tableName)
          .select()
          .eq('id', userId)
          .maybeSingle(); // Lấy 1 bản ghi hoặc null

      if (data != null) {
        return UserProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      print('[getUserProfileById] Error fetching user profile: $e');
      rethrow;
    }
  }

  // --- UPDATE ---
  /// Cập nhật thông tin UserProfile.
  ///
  /// Chỉ cập nhật các trường có thể thay đổi (full_name, phone, gender, user_image, v.v.).
  /// Lưu ý: Không nên cho phép người dùng tự cập nhật 'id', 'role' hay 'created_at'.
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? gender,
    String? userImage,
  }) async {
    final Map<String, dynamic> updates = {};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (gender != null) updates['gender'] = gender;
    if (userImage != null) updates['user_image'] = userImage;

    if (updates.isEmpty) {
      print('[updateProfile] No fields to update.');
      return;
    }

    try {
      // Dùng update().eq('id', userId) để chỉ cập nhật bản ghi của user đó
      await _supabase
          .from(_tableName)
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      print('[updateProfile] Error updating user profile: $e');
      rethrow;
    }
  }

  // Hàm cập nhật trạng thái isActive (thường dùng cho admin)
  Future<void> updateActiveStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'is_active': isActive})
          .eq('id', userId);
    } catch (e) {
      print('[updateActiveStatus] Error updating active status: $e');
      rethrow;
    }
  }

  // --- DELETE ---
  /// Xóa UserProfile dựa trên ID.
  ///
  /// Lưu ý: Trong ứng dụng thực tế, việc xóa Profile DB thường đi kèm với
  /// việc xóa user khỏi Auth Supabase. Cần xử lý cẩn thận.
  Future<void> deleteUserProfile(String userId) async {
    try {
      // Xóa bản ghi trong bảng 'users'
      await _supabase.from(_tableName).delete().eq('id', userId);

      // Bạn CŨNG CẦN XÓA TÀI KHOẢN AUTH NẾU MUỐN
      // (thường dùng API keys ở backend hoặc chỉ cho admin làm)
      // await _supabase.auth.admin.deleteUser(userId); // Dùng cho Admin

      print('[deleteUserProfile] User profile for ID $userId deleted successfully.');
    } catch (e) {
      print('[deleteUserProfile] Error deleting user profile: $e');
      rethrow;
    }
  }
}