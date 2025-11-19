import 'dart:io';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ecomerceapp/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/supabase/auth_supabase_services.dart';
// 1. Import Model UserProfile

class AuthController extends GetxController {
  final AuthSupabaseServices _authServices = AuthSupabaseServices();
  final SupabaseClient _supabase = Supabase.instance.client;
  final GetStorage _storage = GetStorage();

  final RxBool _isFirstime = true.obs;
  final RxBool _isLoggedIn = false.obs;

  // 2. Thêm biến lưu trữ UserProfile đầy đủ (bao gồm role)
  final Rx<UserProfile?> _userProfile = Rx<UserProfile?>(null);

  bool get isFirstime => _isFirstime.value;
  bool get isLoggedIn => _isLoggedIn.value;
  User? get currentUser => _supabase.auth.currentUser;

  // 3. Getter để AccountScreen gọi được
  UserProfile? get userProfile => _userProfile.value;

  // User info (Giữ nguyên cho code cũ)
  var userName = "".obs;
  var userAvatar = "".obs;

  // Default avatar
  static const String defaultAvatar =
      "https://cdn-icons-png.flaticon.com/512/149/149071.png";

  @override
  void onInit() {
    super.onInit();
    _loadInitialStates();
    _loadUserFromSession();

    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && session.user != null) {
        _loadUserFromSession();
      } else {
        // logout nếu không còn session
        _clearUserState();
      }
    });
  }

  void _loadInitialStates() {
    _isFirstime.value = _storage.read('isFirstime') ?? true;
    _isLoggedIn.value = _storage.read('isLoggedIn') ?? false;
  }

  void setFirstime() {
    _isFirstime.value = false;
    _storage.write('isFirstime', false);
  }

  /// Load user info từ Supabase session
  Future<void> _loadUserFromSession() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _clearUserState();
      return;
    }

    _isLoggedIn.value = true;
    _storage.write('isLoggedIn', true);
    print(" ID của tài khoản đang đăng nhập: ${user.id}");
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      print("👉 Dữ liệu lấy được từ DB: $data");
      if (data != null) {
        // 4. Cập nhật Model UserProfile (Thêm phần này)
        _userProfile.value = UserProfile.fromJson(data);

        // Cập nhật các biến cũ (Giữ nguyên logic cũ)
        userName.value = data['full_name'] ?? "User";
        userAvatar.value = data['user_image'] ?? defaultAvatar;
      } else {
        userName.value = "User";
        userAvatar.value = defaultAvatar;
        _userProfile.value = null; // Reset profile nếu không tìm thấy
      }
    } catch (e) {
      print('[LoadUser] error -> $e');
      userName.value = "User";
      userAvatar.value = defaultAvatar;
      _userProfile.value = null;
    }
  }

  /// Upload avatar -> trả về public URL
  Future<String> uploadUserImage(File imageFile, String userId) async {
    try {
      final ext = p.extension(imageFile.path); // .png .jpg
      final filename = 'avatar$ext';
      final storagePath = '$userId/$filename';

      await _supabase.storage
          .from('avatars')
          .upload(
            storagePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from('avatars').getPublicUrl(storagePath);
    } catch (e) {
      Get.snackbar("Storage Error", e.toString());
      rethrow;
    }
  }

  /// Signup
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String gender,
    File? avatarFile,
  }) async {
    try {
      final authResp = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      User? user = authResp.user ?? _supabase.auth.currentUser;
      if (user == null) {
        
        Get.snackbar("Signup Error", "Không tạo được user.");
        return false;
      }

      String avatarUrl = defaultAvatar;
      if (avatarFile != null) {
        try {
          avatarUrl = await uploadUserImage(avatarFile, user.id);
        } catch (_) {
          avatarUrl = defaultAvatar;
        }
      }

      final userData = {
        'id': user.id,
        'full_name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'user_image': avatarUrl,
        'role': 'user', 
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('users').insert(userData);

      _isLoggedIn.value = true;
      _storage.write('isLoggedIn', true);

      userName.value = name;
      userAvatar.value = avatarUrl;
      _userProfile.value = UserProfile.fromJson(userData);

      Get.snackbar("Welcome", "Signup successful!");
      return true;
    } catch (e) {
      Get.snackbar("Signup Error", e.toString());
      return false;
    }
  }

  /// Login
  Future<bool> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        _isLoggedIn.value = true;
        _storage.write('isLoggedIn', true);

        // Load user info (Hàm này đã được sửa ở trên để load cả profile)
        await _loadUserFromSession();

        Get.snackbar("Welcome", "Login successful!");
        return true;
      } else {
        Get.snackbar(
          "Login failed",
          "Invalid credentials or unconfirmed email.",
        );
        return false;
      }
    } catch (e) {
      Get.snackbar("Login Error", e.toString());
      return false;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      Get.snackbar(
        "Success",
        "Password reset link sent to $email",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Reset Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // Supabse xác thực OTP
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.user != null) {
        Get.snackbar("Success", "OTP verified successfully!");
        return true;
      } else {
        Get.snackbar("Invalid OTP", "Please check your OTP and try again");
        return false;
      }
    } on AuthException catch (e) {
      Get.snackbar("OTP Error", e.message);
      return false;
    } catch (e) {
      Get.snackbar("Error", "Unexpected error: ${e.toString()}");
      return false;
    }
  }

  /// Change password (sau khi xác minh OTP thành công)
  Future<bool> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        Get.snackbar(
          "Success",
          "Password updated successfully!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          "Error",
          "Failed to update password.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return false;
      }
    } on AuthException catch (e) {
      Get.snackbar(
        "Auth Error",
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        "Error",
        "Unexpected error: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('[Logout] error -> $e');
    } finally {
      _clearUserState();
    }
  }

  /// Xóa trạng thái user
  void _clearUserState() {
    _isLoggedIn.value = false;
    userName.value = "";
    userAvatar.value = "";
    _userProfile.value = null; // 6. Reset profile khi logout
    _storage.write('isLoggedIn', false);
  }

  bool get isAdmin {
    final profile = userProfile;
    
    // Debug: In ra console để xem chính xác nó đang so sánh cái gì
    print("--- CHECK ADMIN ---");
    print("Profile Object: $profile");
    print("Role from DB: '${profile?.role}'"); // Có dấu nháy để xem có khoảng trắng thừa không

    if (profile == null || profile.role == null) return false;

    // So sánh an toàn: Chuyển về chữ thường và cắt khoảng trắng
    // Ví dụ: " Admin " -> "admin"
    return profile.role!.trim().toLowerCase() == 'admin';
  }
  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    String? gender, 
    String? userImage, 
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null || userProfile == null) {
      Get.snackbar("Error", "Không tìm thấy người dùng đang đăng nhập.");
      return false;
    }
    try {
      await _authServices.updateProfile(
        userId: user.id,
        fullName: fullName,
        phone: phone,
        gender: gender,
        userImage: userImage,
      );
      final updatedProfile = userProfile!.copyWith(
        fullName: fullName,
        phone: phone,
      );
      _userProfile.value = updatedProfile;
      userName.value = fullName;
      Get.snackbar("Success", "Cập nhật hồ sơ thành công!");
      return true;
    } catch (e) {
      Get.snackbar("Update Error", "Không thể cập nhật hồ sơ: $e");
      return false;
    }
  }
}
