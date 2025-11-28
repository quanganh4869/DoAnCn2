import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/models/wishlist.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/supabase/user_behavior_service.dart';
import 'package:ecomerceapp/supabase/wishlist_supabase_service.dart';
import 'package:ecomerceapp/controller/cart_controller.dart'; // IMPORT CartController

class WishlistController extends GetxController {
  // Key: userId, Value: list wishlist của user
  final Map<String, RxList<WishlistItem>> _userWishlists = {};

  final RxBool _isLoading = false.obs;
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = "".obs;

  bool get isLoading => _isLoading.value;
  bool get hasError => _hasError.value;
  String get errorMessage => _errorMessage.value;

  // Lấy user hiện tại
  String? get _userId {
    try {
      // Sử dụng try-catch để tránh lỗi nếu AuthController chưa được khởi tạo
      if (!Get.isRegistered<AuthController>()) return null;
      final authController = Get.find<AuthController>();
      final user = authController.currentUser;
      return user?.id;
    } catch (e) {
      return null;
    }
  }

  // Lấy CartController một cách an toàn
  CartController get _cartController {
    if (Get.isRegistered<CartController>()) {
      return Get.find<CartController>();
    } else {
      return Get.put(CartController());
    }
  }

  @override
  void onInit() {
    super.onInit();
    _listenToAuthChanges();
    loadWishlistItems();
  }

  void _listenToAuthChanges() {
    if (!Get.isRegistered<AuthController>()) return;
    final authController = Get.find<AuthController>();
    ever(authController.isLoggedIn.obs, (bool isLoggedIn) {
      if (isLoggedIn) {
        loadWishlistItems();
      } else {
        _userWishlists.clear();
        update();
      }
    });
  }

  // Lấy wishlist theo user hiện tại
  List<WishlistItem> get wishlist {
    final userId = _userId;
    if (userId == null) return [];
    _userWishlists.putIfAbsent(userId, () => <WishlistItem>[].obs);
    return _userWishlists[userId]!;
  }

  int get itemCount => wishlist.length;
  bool get isEmpty => wishlist.isEmpty;

  // Load wishlist user hiện tại
  Future<void> loadWishlistItems() async {
    final userId = _userId;
    if (userId == null) {
      _hasError.value = true;
      _errorMessage.value = "Please sign in to view your wishlist.";
      return;
    }

    _isLoading.value = true;
    _hasError.value = false;

    try {
      final items = await WishlistSupabaseService.getUserWishlistItemCount(
        userId,
      );
      _userWishlists[userId] = RxList<WishlistItem>(items);

      for (var item in items) {
        update(["wishlist_${item.productId}"]);
      }
      update(); // Update toàn bộ UI liên quan
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value = "Failed to load wishlist. Please try again.";
      print("loadWishlistItems error: $e");
    } finally {
      _isLoading.value = false;
    }
  }

  // Check sản phẩm có trong wishlist
  bool isProductInWishList(String productId) {
    return wishlist.any((item) => item.productId == productId);
  }

  WishlistItem? getWishlistItem(String productId) {
    try {
      return wishlist.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Thêm sản phẩm vào wishlist
  Future<bool> addToWishlist(Products product) async {
    final userId = _userId;
    if (userId == null) {
      Get.snackbar("Authentication required", "Please log in first");
      return false;
    }

    try {
      final success = await WishlistSupabaseService.addToWishlist(
        userId: userId,
        product: product,
      );

      if (success) {
        await loadWishlistItems();
        Get.snackbar("Added", "${product.name} added to wishlist");
      } else {
        Get.snackbar("Error", "Failed to add item");
      }

      return success;
    } catch (e) {
      print("addToWishlist error: $e");
      Get.snackbar("Error", "Failed to add item to wishlist");
      return false;
    }
  }

  // Xóa sản phẩm khỏi wishlist
  Future<bool> removeFromWishlist(String productId) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      final success = await WishlistSupabaseService.removeFromWishlist(
        userId,
        productId,
      );
      if (success) {
        _userWishlists[userId]?.removeWhere(
          (item) => item.productId == productId,
        );
        update(["wishlist_$productId"]);
        update(); // Cập nhật list view
        Get.snackbar("Removed", "Item removed from wishlist");
      }
      return success;
    } catch (e) {
      print("removeFromWishlist error: $e");
      return false;
    }
  }

  // Toggle (Thêm/Xóa)
   Future<void> toggleWishlist(Products product) async {
    final userId = _userId;
    if (userId == null) {
      Get.snackbar("Yêu cầu đăng nhập", "Vui lòng đăng nhập để lưu sản phẩm yêu thích",
          snackPosition: SnackPosition.TOP);
      return;
    }

    final exists = isProductInWishList(product.id);

    if (exists) {
      await removeFromWishlist(product.id);
      UserBehaviorService.trackAction(product.id, 'unwishlist');
    } else {
      await addToWishlist(product);
      UserBehaviorService.trackAction(product.id, 'wishlist');
    }
    update(["wishlist_${product.id}"]);
  }

  // Xóa toàn bộ wishlist
  Future<bool> clearWishlist() async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      final success = await WishlistSupabaseService.clearUserWishlist(userId);
      if (success) {
        _userWishlists[userId]?.clear();
        update();
        Get.snackbar("Wishlist cleared", "All items removed from wishlist");
      }
      return success;
    } catch (e) {
      print("clearWishlist error: $e");
      return false;
    }
  }

  // Lấy danh sách Products
  List<Products> get wishlistProducts =>
      wishlist.map((e) => e.product).toList();

  Future<void> refreshWishlist() async => await loadWishlistItems();

  ///  Thêm 1 sản phẩm từ Wishlist vào Giỏ hàng
  // 1. Thêm 1 sản phẩm từ Wishlist vào Giỏ hàng
  Future<void> addSingleItemToCart(Products product) async {
    _isLoading.value = true;
    try {
      // Gọi hàm addToCart của CartController
      final success = await _cartController.addToCart(
        product: product,
        quantity: 1,
        // QUAN TRỌNG: Tắt thông báo mặc định của CartController để tự xử lý vị trí TOP tại đây
        showNotification: false,
      );

      if (success) {
        Get.snackbar(
          "Success",
          "${product.name} added to cart",
          snackPosition: SnackPosition.TOP, // Hiển thị ở trên
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
        );

        // (Tùy chọn) Xóa khỏi wishlist nếu cần
        // await removeFromWishlist(product.id);
      } else {
        // Trường hợp thất bại (ví dụ hết hàng) nhưng CartController không bắn lỗi
        Get.snackbar(
          "Error",
          "Failed to add to cart",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      print("Error addSingleItemToCart: $e");
      Get.snackbar(
        "Error",
        "Failed to add to cart",
        snackPosition: SnackPosition.TOP, // Hiển thị ở trên
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // 2. Thêm TẤT CẢ sản phẩm từ Wishlist vào Giỏ hàng
  Future<void> addAllToCart() async {
    if (wishlist.isEmpty) {
      Get.snackbar(
        "Notice",
        "Your wishlist is empty",
        snackPosition: SnackPosition.TOP, // Hiển thị ở trên
      );
      return;
    }

    _isLoading.value = true;
    int successCount = 0;
    int failCount = 0;

    try {
      for (var item in wishlist) {
        if ((item.product.stock ?? 0) > 0) {
          final success = await _cartController.addToCart(
            product: item.product,
            quantity: 1,
            showNotification: false, // Tắt thông báo lẻ tẻ
          );
          if (success)
            successCount++;
          else
            failCount++;
        } else {
          failCount++; // Hết hàng
        }
      }

      // Hiển thị thông báo tổng kết
      if (successCount > 0) {
        Get.snackbar(
          "Success",
          "Added $successCount items to cart" +
              (failCount > 0 ? " ($failCount failed/out of stock)" : ""),
          snackPosition: SnackPosition.TOP, // Hiển thị ở trên
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
        );

        // (Tùy chọn) Xóa wishlist sau khi thêm tất cả thành công
        // await clearWishlist();
      } else {
        Get.snackbar(
          "Error",
          "Failed to add items (Out of stock or Error)",
          snackPosition: SnackPosition.TOP, // Hiển thị ở trên
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      print("Error addAllToCart: $e");
      Get.snackbar(
        "Error",
        "Something went wrong",
        snackPosition: SnackPosition.TOP, // Hiển thị ở trên
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      _isLoading.value = false;
    }
  }
}
