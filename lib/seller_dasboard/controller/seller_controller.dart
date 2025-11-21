import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/controller/product_controller.dart';


class SellerController extends GetxController {
  final _supabase = Supabase.instance.client;
  final AuthController _authController = Get.find<AuthController>();

  var isSellerMode = false.obs;
  var myProducts = <Products>[].obs;
  var isLoading = false.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _sellerRealtimeSubscription;

  @override
  void onInit() {
    super.onInit();
    ever(_authController.userProfileRx, (UserProfile? profile) {
      if (profile != null) {
        _setupRealtimeListener(profile.id);
      } else {
        resetState();
      }
    });
    if (_authController.userProfile != null) {
      _setupRealtimeListener(_authController.userProfile!.id);
    }
  }

  @override
  void onClose() {
    _sellerRealtimeSubscription?.cancel();
    super.onClose();
  }

  void resetState() {
    isSellerMode.value = false;
    myProducts.clear();
    isLoading.value = false;
    _sellerRealtimeSubscription?.cancel();
  }

  void _setupRealtimeListener(String userId) {
    _sellerRealtimeSubscription?.cancel();
    _sellerRealtimeSubscription = _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((List<Map<String, dynamic>> data) {
      if (data.isNotEmpty) {
        final updatedProfile = UserProfile.fromJson(data.first);
        final oldStatus = _authController.userProfile?.sellerStatus;
        final newStatus = updatedProfile.sellerStatus;

        if (oldStatus != 'active' && (newStatus == 'active' || newStatus == 'approved')) {
          _showSuccessSnackbar("Chúc mừng!", "Cửa hàng của bạn đã được duyệt.");
          isSellerMode.value = true;
          fetchSellerProducts();
        } else if (newStatus == 'rejected' && oldStatus != 'rejected') {
          _showErrorSnackbar("Thông báo", "Yêu cầu đăng ký của bạn đã bị từ chối.");
        }
        _authController.updateLocalProfile(updatedProfile);
      }
    });
  }

  Future<bool> registerSeller({
    required String storeName,
    required String description,
    required String businessEmail,
    required String shopPhone,
    required String shopAddress,
  }) async {
    final user = _authController.userProfile;
    if (user == null) return false;

    isLoading.value = true;
    try {
      final updateData = {
        'shop_name': storeName,
        'shop_description': description,
        'business_email': businessEmail,
        'shop_phone': shopPhone,
        'shop_address': shopAddress,
        'seller_status': 'pending',
      };
      await _supabase.from('users').update(updateData).eq('id', user.id);
      final updatedProfile = user.copyWith(
        storeName: storeName, storeDescription: description, businessEmail: businessEmail,
        shopPhone: shopPhone, shopAddress: shopAddress, sellerStatus: 'pending',
      );
      await _authController.updateLocalProfile(updatedProfile);
      _showSuccessSnackbar("Thành công", "Đã gửi hồ sơ đăng ký shop!");
      return true;
    } catch (e) {
      _showErrorSnackbar("Lỗi", "Có lỗi xảy ra: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSellerMode() {
    final user = _authController.userProfile;
    if (user == null || (user.sellerStatus == 'none' || user.sellerStatus == null)) {
       _showErrorSnackbar("Lỗi", "Bạn chưa đăng ký người bán.");
       return;
    }
    if (user.sellerStatus == 'pending') {
      _showErrorSnackbar("Chờ duyệt", "Hồ sơ đang được xét duyệt.");
      return;
    }
    if (user.sellerStatus == 'rejected') {
      _showErrorSnackbar("Từ chối", "Hồ sơ bị từ chối. Vui lòng đăng ký lại.");
      return;
    }
    if (user.sellerStatus == 'active' || user.sellerStatus == 'approved') {
      isSellerMode.value = !isSellerMode.value;
      if (isSellerMode.value) {
        fetchSellerProducts();
        _showInfoSnackbar("Chế độ", "Dashboard Người bán");
      } else {
        _showInfoSnackbar("Chế độ", "Mua hàng");
      }
    }
  }

  Future<void> fetchSellerProducts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('seller_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      myProducts.value = (response as List).map((e) => Products.fromSupabaseJson(e, e['id'].toString())).toList();
    } catch (e) {
      debugPrint("Error fetching products: $e");
    }
  }

  Future<bool> addProduct({
    required String name, required String description, required double price,
    required String category, required int stock, String? imageUrl, double? oldPrice,
    Map<String, dynamic>? specification,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      isLoading.value = true;
      await _supabase.from('products').insert({
        'name': name, 'description': description, 'price': price, 'old_price': oldPrice,
        'category': category, 'stock': stock, 'images': imageUrl != null ? [imageUrl] : [],
        'seller_id': userId, 'is_featured': false, 'is_active': true, 'specification': specification ?? {},
      });
      await fetchSellerProducts();
      _refreshGlobalProducts();
      _showSuccessSnackbar("Thành công", "Đã thêm sản phẩm!");
      return true;
    } catch (e) {
      _showErrorSnackbar("Lỗi", "Thêm sản phẩm thất bại: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProduct({
    required String productId, required String name, required String description,
    required double price, required String category, required int stock,
    String? imageUrl, double? oldPrice, Map<String, dynamic>? specification,
  }) async {
    try {
      isLoading.value = true;
      await _supabase.from('products').update({
        'name': name, 'description': description, 'price': price, 'old_price': oldPrice,
        'category': category, 'stock': stock, 'images': imageUrl != null ? [imageUrl] : [],
        'specification': specification ?? {},
      }).eq('id', productId);
      await fetchSellerProducts();
      _refreshGlobalProducts();

      // ✅ ĐÃ FIX: Đưa thông báo lên TOP để không bị bàn phím che
      _showSuccessSnackbar("Thành công", "Đã cập nhật sản phẩm!");
      return true;
    } catch (e) {
      _showErrorSnackbar("Lỗi", "Cập nhật thất bại: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      try {
        await _supabase.from('products').delete().eq('id', productId);
      } catch (fkError) {
        await _supabase.from('products').update({'is_active': false}).eq('id', productId);
      }
      myProducts.removeWhere((p) => p.id == productId);
      _refreshGlobalProducts();
      _showSuccessSnackbar("Đã xóa", "Sản phẩm đã được xóa thành công.");
    } catch (e) {
      _showErrorSnackbar("Lỗi", "Không thể xóa: $e");
    }
  }

  void _refreshGlobalProducts() {
    if (Get.isRegistered<ProductController>()) {
      Get.find<ProductController>().loadProducts();
    }
  }

  // ✅ CẤU HÌNH SNACKBAR CHUẨN (HIỆN TRÊN CÙNG)
  void _showSuccessSnackbar(String t, String m) => Get.rawSnackbar(
    title: t, message: m,
    backgroundColor: Colors.green,
    snackPosition: SnackPosition.TOP, // QUAN TRỌNG
    margin: const EdgeInsets.all(10), borderRadius: 10,
    icon: const Icon(Icons.check_circle, color: Colors.white)
  );

  void _showErrorSnackbar(String t, String m) => Get.rawSnackbar(
    title: t, message: m,
    backgroundColor: Colors.red,
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(10), borderRadius: 10,
    icon: const Icon(Icons.error, color: Colors.white)
  );

  void _showInfoSnackbar(String t, String m) => Get.rawSnackbar(
    title: t, message: m,
    backgroundColor: Colors.blue,
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(10), borderRadius: 10,
    icon: const Icon(Icons.info, color: Colors.white)
  );
}