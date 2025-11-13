import 'dart:io';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GetStorage _storage = GetStorage();

  final RxBool _isFirstime = true.obs;
  final RxBool _isLoggedIn = false.obs;

  bool get isFirstime => _isFirstime.value;
  bool get isLoggedIn => _isLoggedIn.value;

  // User info
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

    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        userName.value = data['full_name'] ?? "User";
        userAvatar.value = data['user_image'] ?? defaultAvatar;
      } else {
        userName.value = "User";
        userAvatar.value = defaultAvatar;
      }
    } catch (e) {
      print('[LoadUser] error -> $e');
      userName.value = "User";
      userAvatar.value = defaultAvatar;
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

      await _supabase.from('users').insert({
        'id': user.id,
        'full_name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'user_image': avatarUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      _isLoggedIn.value = true;
      _storage.write('isLoggedIn', true);
      userName.value = name;
      userAvatar.value = avatarUrl;

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

        // Load user info
        final data = await _supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (data != null) {
          userName.value = data['full_name'] ?? "User";
          userAvatar.value = data['user_image'] ?? defaultAvatar;
        }

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
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'http://localhost:64001/#/ForgotpasswordScreen',
      );
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
    _storage.write('isLoggedIn', false);
  }
}
