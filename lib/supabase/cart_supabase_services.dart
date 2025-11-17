import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/models/cart_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartSupabaseServices {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _cartTable = "cart";
  //  LOAD GIỎ HÀNG  
  static Future<List<CartItem>> loadCart() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        print("User not logged in");

        return [];
      }
      final List<dynamic> res = await _supabase
          .from(_cartTable)
          .select("*, products(*)")
          .eq("user_id", user.id);

      return res.map<CartItem>((data) {
        return CartItem.fromSupabaseJson(
          Map<String, dynamic>.from(data),

          data["id"].toString(),
        );
      }).toList();
    } catch (e) {
      print("Load cart error: $e");

      return [];
    }
  }

  //  ADD TO CART 
  static Future<bool> addToCart({
    required String userId,
    required Products product,
    int quantity = 1,
    String? selectedSize,
    String? selectedColor,
    Map<String, dynamic> customizations = const {},
  }) async {
    try {
      // Kiểm tra sản phẩm đã có trong giỏ chưa
      final existingItem = await getCartItem(
        userId,
        product.id,
        selectedSize: selectedSize,
        selectedColor: selectedColor,
      );

      if (existingItem != null) {
        // Nếu có rồi thì update số lượng
        return await updateCartItemQuantity(
          existingItem.id,
          existingItem.quantity + quantity,
        );
      }

      // Nếu chưa có thì tạo mới
      final now = DateTime.now();
      final newCartItem = CartItem(
        id: "", 
        userId: userId,
        productId: product.id,
        product: product,
        quantity: quantity,
        selectedSize: selectedSize,
        selectedColor: selectedColor,
        customizations: customizations,
        addedAt: now,
        updatedAt: now,
      );

      // QUAN TRỌNG: Thêm .select() để lấy dữ liệu trả về
      final response = await _supabase
          .from(_cartTable)
          .insert(newCartItem.toJson())
          .select(); 
      
      return response.isNotEmpty;
    } catch (e) {
      print("Lỗi thêm sản phẩm vào giỏ hàng: $e");
      return false;
    }
  }

  // --- FIX LỖI UPDATE CART QUANTITY (Nơi xảy ra lỗi của bạn) ---
  static Future<bool> updateCartItemQuantity(
    String cartItemId,
    int newQuantity,
  ) async {
    try {
      if (newQuantity <= 0) {
        return await removeCartItem(cartItemId);
      }
      
      // QUAN TRỌNG: Thêm .select() vào cuối
      final response = await _supabase
          .from(_cartTable)
          .update({
            "quantity": newQuantity,
            "updated_at": DateTime.now().toIso8601String(),
          })
          .eq("id", cartItemId)
          .select(); 

      return response.isNotEmpty;
    } catch (e) {
      print("Lỗi cập nhật số lượng giỏ hàng: $e");
      return false;
    }
  }

  // --- FIX LỖI REMOVE ITEM ---
  static Future<bool> removeCartItem(String cartItemId) async {
    try {
      // QUAN TRỌNG: Thêm .select() vào cuối
      final response = await _supabase
          .from(_cartTable)
          .delete()
          .eq("id", cartItemId)
          .select();
          
      return response.isNotEmpty;
    } catch (e) {
      print("Lỗi xoá sản phẩm khỏi giỏ hàng: $e");
      return false;
    }
  }

  // GET USER CART ITEMS 
  static Future<List<CartItem>> getUserCartItems(String userId) async {
    try {
      final response = await _supabase
          .from(_cartTable)
          .select("*, products(*)")
          .eq("user_id", userId)
          .order("added_at", ascending: false);
      if (response == null) return [];

      return response.map<CartItem>((data) {
        return CartItem.fromSupabaseJson(
          Map<String, dynamic>.from(data),
          data["id"].toString(),
        );
      }).toList();
    } catch (e) {
      print("Lỗi lấy giỏ hàng: $e");
      return [];
    }
  }

  // REALTIME CART 
  static Stream<List<CartItem>> getUserCartItemsRealtime(String userId) {
    return _supabase
        .from(_cartTable)
        .stream(primaryKey: ["id"])
        .eq("user_id", userId) // FIX
        .order("added_at", ascending: false)
        .map((rows) {
          return rows.map<CartItem>((data) {
            return CartItem.fromSupabaseJson(
              Map<String, dynamic>.from(data),

              data["id"].toString(),
            );
          }).toList();
        });
  }

  // GET ONE CART ITEM 
  static Future<CartItem?> getCartItem(
    String userId,
    String productId, {
    String? selectedSize,
    String? selectedColor,
  }) async {
    try {
      var query = _supabase
          .from(_cartTable)
          .select("*, products(*)")
          .eq("user_id", userId)
          .eq("product_id", productId);
      if (selectedSize != null) {
        query = query.eq("selected_size", selectedSize);
      }
      if (selectedColor != null) {
        query = query.eq("selected_color", selectedColor);
      }
      final response = await query.maybeSingle();
      if (response == null) return null;
      return CartItem.fromSupabaseJson(
        Map<String, dynamic>.from(response),
        response["id"].toString(),
      );
    } catch (e) {
      print("Lỗi lấy cart item: $e");
      return null;
    }
  }
 // Lấy tổng số lượng sản phẩm trong giỏ của user
static Future<int> getCartItemCount(String userId) async {
  try {
    final response = await _supabase
        .from(_cartTable)
        .select("quantity")
        .eq("user_id", userId);

    if (response == null || response.isEmpty) return 0;

    int totalItems = 0;

    // Cộng dồn quantity của từng cart item
    for (var item in response) {
      totalItems += (item["quantity"] ?? 1) as int;
    }

    return totalItems;
  } catch (e) {
    print("Lỗi đếm cart item: $e");
    return 0;
  }
}

  // CLEAR CART (GIỮ NGUYÊN)
  static Future<bool> clearUserCart(String userId) async {
    try {
      await _supabase.from(_cartTable).delete().eq("user_id", userId);
      return true;
    } catch (e) {
      print("Lỗi xóa cart item: $e");
      return false;
    }
  }

  // GET TOTAL ITEM COUNT (FIX)
  static Future<int> itemCount(String userId) async {
    try {
      final response = await _supabase
          .from(_cartTable)
          .select("quantity")
          .eq("user_id", userId); // FIX

      if (response == null || response.isEmpty) return 0;

      int totalItems = 0;

      for (var item in response) {
        totalItems += (item["quantity"] ?? 1) as int;
      }
      return totalItems;
    } catch (e) {
      print("Lỗi đếm cart item: $e");

      return 0;
    }
  }

  // CART TOTALS (GIỮ NGUYÊN)
  static Future<Map<String, double>> getCartTotals(String userId) async {
    try {
      final cartItems = await getUserCartItems(userId);
      double subtotal = 0.0;
      double savings = 0.0;
      for (var item in cartItems) {
        subtotal += item.totalPrice;
        savings += item.savings;
      }
      const double shipping = 10;
      final double total = subtotal + shipping;
      return {
        "subtotal": subtotal,
        "savings": savings,
        "shipping": shipping,
        "total": total,
      };
    } catch (e) {
      print("Lỗi tính tổng giá hàng: $e");
      return {"subtotal": 0.0, "savings": 0.0, "shipping": 0.0, "total": 0.0};
    }
  }
}
