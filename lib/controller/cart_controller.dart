import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/models/cart_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/supabase/cart_supabase_services.dart';

class CartController extends GetxController {
  final RxList<CartItem> _cartItems = <CartItem>[].obs;
  RxList<CartItem> get cartItems => _cartItems;

  final RxBool _isLoading = false.obs;
  RxBool get isLoading => _isLoading;

  final RxBool _hasError = false.obs;
  RxBool get hasError => _hasError;

  final RxString _errorMessage = "".obs;
  RxString get errorMessage => _errorMessage;

  final RxInt _itemCount = 0.obs;
  RxInt get itemCount => _itemCount;

  final RxDouble _subtotal = 0.0.obs;
  RxDouble get subtotal => _subtotal;

  final RxDouble _saving = 0.0.obs;
  RxDouble get saving => _saving;

  final RxDouble _shipping = 0.0.obs;
  RxDouble get shipping => _shipping;

  final RxDouble _total = 0.0.obs;
  RxDouble get total => _total;

  // Helper: userId from local storage
  String? get _userId {
    // Lấy trực tiếp từ phiên đăng nhập hiện tại của Supabase
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id;
  }

  // LOAD CART (1 lần)
  Future<void> loadUserCart(String userId) async {
    try {
      _isLoading.value = true;
      _hasError.value = false;

      final items = await CartSupabaseServices.getUserCartItems(userId);
      _cartItems.assignAll(items);

      await _refreshTotals(userId);
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  // REALTIME CART
  void listenToRealtimeCart(String userId) {
    CartSupabaseServices.getUserCartItemsRealtime(userId).listen((items) async {
      _cartItems.assignAll(items);
      await _refreshTotals(userId);
    });
  }

  // ADD TO CART
  Future<bool> addToCart({
    required Products product,
    int quantity = 1,
    String? selectedSize,
    String? selectedColor,
    Map<String, dynamic>? customizations,
    bool showNotification = true,
  }) async {
    try {
      final userId = _userId;
      if (userId == null) {
        Get.snackbar(
          "Authentication Required",
          "Please sign in to add your cart",
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }

      final stock = product.stock ?? 0;
      if (stock < quantity) {
        Get.snackbar(
          "Insufficient Stock",
          "Only $stock items available",
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }

      final success = await CartSupabaseServices.addToCart(
        userId: userId,
        product: product,
        quantity: quantity,
        selectedColor: selectedColor,
        selectedSize: selectedSize,
        customizations: customizations ?? {},
      );

      if (success) {
        await loadCartItem();
        update();
        if (showNotification) {
          Get.snackbar(
            "Success",
            "Item added to cart",
            snackPosition: SnackPosition.TOP,
          );
        }
      }
      return success;
    } catch (e) {
      print("Error adding to cart: $e");
      Get.snackbar(
        "Error",
        "Failed to add your cart",
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  // UPDATE QUANTITY
  Future<bool> updateQuantity(String cartItemId, int newQuantity) async {
    try {
      final userId = _userId;
      if (userId == null) {
        Get.snackbar(
          "Authentication Required",
          "Please sign in",
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }

      final cartItem = _cartItems.firstWhere((item) => item.id == cartItemId);

      final product = cartItem.product;
      final stock = product?.stock ?? 0;

      if (newQuantity > stock) {
        Get.snackbar(
          "Insufficient Stock",
          "Only $stock items available",
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }

      final success = await CartSupabaseServices.updateCartItemQuantity(
        cartItemId,
        newQuantity,
      );

      if (success) {
        await loadCartItem();
        update();
      }

      return success;
    } catch (e) {
      print("Error updating quantity: $e");
      return false;
    }
  }

  // convenience: increase quantity by 1 (used by UI)
  Future<void> increaseQuantity(CartItem item) async {
    final newQty = item.quantity + 1;
    await updateQuantity(item.id, newQty);
  }

  // convenience: decrease quantity by 1 (min 1)
  Future<void> decreaseQuantity(CartItem item) async {
    final newQty = (item.quantity - 1).clamp(1, 99999);
    // nếu muốn xóa khi xuống 0, thay clamp và gọi removeItem
    await updateQuantity(item.id, newQty);
  }

  // REMOVE ITEM (by CartItem)
  Future<bool> removeItem(CartItem item) async {
    final userId = _userId;
    if (userId == null) {
      Get.snackbar(
        "Authentication Required",
        "Please sign in",
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
    final removed = await CartSupabaseServices.removeCartItem(item.id);
    if (removed) {
      await loadUserCart(userId);
    }
    return removed;
  }

  // REMOVE ITEM (by id) - keep existing signature
  // CartController
  Future<bool> removeCartItem(String cartItemId) async {
    try {
      final userId = GetStorage().read("userId");
      if (userId == null) return false;

      final removed = await CartSupabaseServices.removeCartItem(cartItemId);
      if (removed) {
        await loadUserCart(userId);
      }
      return removed;
    } catch (e) {
      print("Error removing cart item: $e");
      return false;
    }
  }

  // CLEAR ALL ITEMS
  // Thêm vào CartController
  Future<void> clearCart() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      _isLoading.value = true;
      // Gọi service để xóa
      final success = await CartSupabaseServices.clearUserCart(userId);

      if (success) {
        _cartItems.clear();
        _itemCount.value = 0;
        _subtotal.value = 0.0;
        _saving.value = 0.0;
        _total.value = 0.0;

        Get.snackbar("Success", "Cart cleared successfully");
      }
    } catch (e) {
      print("Error clearing cart: $e");
      Get.snackbar("Error", "Failed to clear cart");
    } finally {
      _isLoading.value = false;
    }
  }

  // REFRESH TOTALS
  Future<void> _refreshTotals(String userId) async {
    final count = await CartSupabaseServices.getCartItemCount(userId);
    _itemCount.value = count;

    final totals = await CartSupabaseServices.getCartTotals(userId);
    _subtotal.value = totals["subtotal"] ?? 0.0;
    _saving.value = totals["savings"] ?? 0.0;
    _shipping.value = totals["shipping"] ?? 0.0;
    _total.value = totals["total"] ?? 0.0;
  }

  // RESET GIỎ HÀNG
  void _reretTotals() {
    _subtotal.value = 0.0;
    _saving.value = 0.0;
    _total.value = _shipping.value;
  }

  // LOAD GIỎ HÀNG (for current user)
  Future<void> loadCartItem() async {
    _isLoading.value = true;
    _hasError.value = false;

    try {
      final userId = _userId;

      if (userId == null) {
        _cartItems.clear();
        _itemCount.value = 0;
        _reretTotals();
        _hasError.value = true;
        _errorMessage.value = "Please sign in to view your cart";
        return;
      }

      final items = await CartSupabaseServices.getUserCartItems(userId);
      _cartItems.value = items;
      _calculateTotals();
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value = "Failed to load cart items. Please try again.";
      print("Error loading cart items: $e");
    } finally {
      _isLoading.value = false;
    }
  }

  void _calculateTotals() {
    double subtotal = 0.0;
    double saving = 0.0;
    int totalItems = 0;

    for (var item in _cartItems) {
      subtotal += item.totalPrice;
      saving += item.savings;
      totalItems += item.quantity;
    }

    _subtotal.value = subtotal;
    _saving.value = saving;
    _total.value = subtotal + _shipping.value;
    _itemCount.value = totalItems;
  }
}
