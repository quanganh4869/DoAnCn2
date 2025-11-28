import 'dart:io';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ecomerceapp/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/supabase/auth_supabase_services.dart';

class AuthController extends GetxController {
  final AuthSupabaseServices _authServices = AuthSupabaseServices();
  final SupabaseClient _supabase = Supabase.instance.client;
  final GetStorage _storage = GetStorage();

  final RxBool _isFirstime = true.obs;
  final RxBool _isLoggedIn = false.obs;
  final Rx<UserProfile?> _userProfile = Rx<UserProfile?>(null);

  bool get isFirstime => _isFirstime.value;
  bool get isLoggedIn => _isLoggedIn.value;
  User? get currentUser => _supabase.auth.currentUser;

  UserProfile? get userProfile => _userProfile.value;
  Rx<UserProfile?> get userProfileRx => _userProfile;

  var userName = "".obs;
  var userAvatar = "".obs;

  static const String defaultAvatar =
      "https://cdn-icons-png.flaticon.com/512/149/149071.png";

  @override
  void onInit() {
    super.onInit();
    _loadInitialStates();
    loadUserFromSession();

    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && session.user != null) {
        if (_userProfile.value == null || _userProfile.value!.id != session.user.id) {
           loadUserFromSession();
        }
      } else {
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

   Future<void> loadUserFromSession() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _clearUserState();
      return;
    }

    try {
      final profile = await _authServices.getUserProfileById(user.id);

      if (profile != null) {
        if (profile.isActive == false) {
          print("⛔ Tài khoản này đã bị khóa (Banned). Đang đăng xuất...");
          await logout();
          Get.snackbar(
            "Tài khoản bị khóa",
            "Vui lòng liên hệ quản trị viên để biết thêm chi tiết.",
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red,
            duration: const Duration(seconds: 5),
          );
          return;
        }

        _isLoggedIn.value = true;
        _storage.write('isLoggedIn', true);

        _userProfile.value = profile;
        userName.value = profile.fullName ?? "User";
        userAvatar.value = profile.userImage ?? defaultAvatar;

        print("✅ Đã load UserProfile: ${profile.fullName} | Role: ${profile.role}");
      } else {
        userName.value = "User";
        userAvatar.value = defaultAvatar;
        _userProfile.value = null;
      }
    } catch (e) {
      print('[LoadUser] error -> $e');
      userName.value = "User";
      userAvatar.value = defaultAvatar;
      _userProfile.value = null;
    }
  }

  Future<void> updateLocalProfile(UserProfile newProfile) async {
    _userProfile.value = newProfile;
    userName.value = newProfile.fullName ?? userName.value;
    if (newProfile.userImage != null) {
      userAvatar.value = newProfile.userImage!;
    }
  }

  Future<String> uploadUserImage(File imageFile, String userId) async {
    try {
      final ext = p.extension(imageFile.path);
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

  // Đăng ký tài khoản User mới
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

      final newProfile = UserProfile(
        id: user.id,
        fullName: name,
        email: email,
        phone: phone,
        gender: gender,
        userImage: avatarUrl,
        role: 'user',
        createdAt: DateTime.now().toIso8601String(),
        isActive: true,
        sellerStatus: 'none',
        storeName: null,
        storeDescription: null,
      );

      await _authServices.createUserProfile(newProfile);

      _isLoggedIn.value = true;
      _storage.write('isLoggedIn', true);

      userName.value = name;
      userAvatar.value = avatarUrl;
      _userProfile.value = newProfile;

      Get.snackbar("Welcome", "Signup successful!");
      return true;
    } catch (e) {
      Get.snackbar("Signup Error", e.toString());
      return false;
    }
  }

  // Login
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

        await loadUserFromSession();

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

  // Reset password (Gửi mail)
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

  // Xác thực OTP
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

  // Update Password (Sau khi OTP thành công)
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
      Get.snackbar("Auth Error", e.message);
      return false;
    } catch (e) {
      Get.snackbar("Error", "Unexpected error: ${e.toString()}");
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('[Logout] error -> $e');
    } finally {
      _clearUserState();
    }
  }

  // Clear toàn bộ state khi logout
  void _clearUserState() {
    _isLoggedIn.value = false;
    userName.value = "";
    userAvatar.value = "";
    _userProfile.value = null;
    _storage.write('isLoggedIn', false);
  }

  // Kiểm tra Admin
  bool get isAdmin {
    final profile = userProfile;
    if (profile == null || profile.role == null) return false;
    return profile.role!.trim().toLowerCase() == 'admin';
  }

  // Update thông tin cá nhân (User Profile)
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
      // 1. Gọi Service cập nhật DB
      await _authServices.updateProfile(
        userId: user.id,
        fullName: fullName,
        phone: phone,
        gender: gender,
        userImage: userImage,
      );

      // 2. Cập nhật state local (sử dụng hàm updateLocalProfile mới)
      final updatedProfile = userProfile!.copyWith(
        fullName: fullName,
        phone: phone,
        gender: gender,
        userImage: userImage ?? userProfile!.userImage,
      );

      await updateLocalProfile(updatedProfile);

      Get.snackbar("Success", "Cập nhật hồ sơ thành công!");
      return true;
    } catch (e) {
      Get.snackbar("Update Error", "Không thể cập nhật hồ sơ: $e");
      return false;
    }
  }

  // Ban/Unban User Login
  Future<void> adminToggleUserBan(String targetUserId, bool ban) async {
    try {
      await _supabase.from('users').update({'is_active': !ban}).eq('id', targetUserId);

      String msg = ban ? "Đã khóa tài khoản user" : "Đã mở khóa tài khoản user";
      Get.snackbar("Admin Action", msg, backgroundColor: Colors.blue.withOpacity(0.1));
    } catch (e) {
      Get.snackbar("Error", "Lỗi khi ban user: $e");
    }
  }

  // Ban/Unban Seller Mode
  Future<void> adminToggleSellerBan(String targetUserId, bool ban) async {
    try {
      String newStatus = ban ? 'suspended' : 'active';

      await _supabase.from('users').update({
        'seller_status': newStatus
      }).eq('id', targetUserId);

      String msg = ban ? "Đã đình chỉ quyền bán hàng (Suspended)" : "Đã khôi phục quyền bán hàng (Active)";
      Get.snackbar("Admin Action", msg, backgroundColor: Colors.orange.withOpacity(0.1), colorText: Colors.orange);
    } catch (e) {
      Get.snackbar("Error", "Lỗi khi cấm seller: $e");
    }
  }
}