import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/seller_dasboard/model/seller.dart';

class SellerController extends GetxController {
  final _supabase = Supabase.instance.client;
  
  // Trạng thái
  Rx<Seller?> currentSeller = Rx<Seller?>(null);
  RxBool isSellerMode = false.obs; // Để chuyển đổi giao diện
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkSellerStatus();
  }

  // Kiểm tra xem User đã đăng ký làm Seller chưa
  Future<void> checkSellerStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('sellers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        currentSeller.value = Seller.fromJson(response);
      }
    } catch (e) {
      print("Error checking seller status: $e");
    }
  }

  // Đăng ký làm Seller
  Future<bool> registerSeller(String shopName, String desc, String email, String phone) async {
    isLoading.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('sellers').insert({
        'user_id': userId,
        'shop_name': shopName,
        'shop_description': desc,
        'business_email': email,
        'phone_number': phone,
        'status': 'pending', // Mặc định là chờ duyệt
      });
      
      await checkSellerStatus(); // Reload lại trạng thái
      return true;
    } catch (e) {
      print("Error registering seller: $e");
      Get.snackbar("Error", "Registration failed: ${e.toString()}");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Chuyển đổi chế độ
  void toggleSellerMode() {
    isSellerMode.value = !isSellerMode.value;
    if (isSellerMode.value) {
      // Logic điều hướng sang Seller Home Screen được xử lý ở UI
    }
  }
}