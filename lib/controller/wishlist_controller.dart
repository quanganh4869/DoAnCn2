import 'package:get/get.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/models/wishlist.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/supabase/wishlist_supabase_service.dart';

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
    final authController = Get.find<AuthController>();
    final user = authController.currentUser;
    return user?.id;
  }

  @override
  void onInit() {
    super.onInit();
    _listenToAuthChanges();
    loadWishlistItems();
  }

  void _listenToAuthChanges() {
    final authController = Get.find<AuthController>();
    ever(authController.isLoggedIn.obs, (bool isLoggedIn) {
      if (isLoggedIn) {
        loadWishlistItems();
      } else {
        // Clear tất cả wishlist khi logout
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
      final items = await WishlistSupabaseService.getUserWishlistItemCount(userId);
      _userWishlists[userId] = RxList<WishlistItem>(items);

      // Update từng item để rebuild icon
      for (var item in items) {
        update(["wishlist_${item.productId}"]);
      }
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

  // Thêm sản phẩm
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

  // Xóa sản phẩm
  Future<bool> removeFromWishlist(String productId) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      final success =
          await WishlistSupabaseService.removeFromWishlist(userId, productId);
      if (success) {
        _userWishlists[userId]?.removeWhere((item) => item.productId == productId);
        update(["wishlist_$productId"]);
        Get.snackbar("Removed", "$productId removed from wishlist");
      }
      return success;
    } catch (e) {
      print("removeFromWishlist error: $e");
      return false;
    }
  }

  // Toggle
  Future<void> toggleWishlist(Products product) async {
    final userId = _userId;
    if (userId == null) {
      Get.snackbar("Login Required", "Please log in to manage wishlist");
      return;
    }

    final exists = isProductInWishList(product.id);
    if (exists) {
      await removeFromWishlist(product.id);
      print("Removed from wishlist: ${product.name}");
    } else {
      await addToWishlist(product);
      print("Added to wishlist: ${product.name}");
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
  List<Products> get wishlistProducts => wishlist.map((e) => e.product).toList();

  Future<void> refreshWishlist() async => await loadWishlistItems();
}
