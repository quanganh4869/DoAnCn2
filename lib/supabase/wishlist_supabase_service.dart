import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/models/wishlist.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistSupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _wishlistTable = "wishlist";

  static Future<bool> addToWishlist({
    required String userId,
    required Products product,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final existingItem = await getWishlistItem(userId, product.id);
      if (existingItem != null) return true;

      await _supabase.from(_wishlistTable).insert({
        "user_id": userId,
        "product_id": product.id,
        "product": product.toJson(), // <-- FULL JSON (FIX)
        "added_at": DateTime.now().toIso8601String(),
        "metadata": metadata ?? {},
      });

      print("Added to wishlist: ${product.name}");
      return true;
    } catch (e) {
      print("addToWishlist error: $e");
      return false;
    }
  }
  static Future<WishlistItem?> getWishlistItem(
    String userId,
    String productId,
  ) async {
    try {
      final rows = await _supabase
          .from(_wishlistTable)
          .select("""
            *,
            product:products(*)
          """)
          .eq("user_id", userId)
          .eq("product_id", productId);

      if (rows.isEmpty) return null;

      final data = Map<String, dynamic>.from(rows.first);

      data["product_id"] = data["product_id"].toString();

      // thêm dữ liệu product JOIN vào json
      data["product"] = rows.first["product"];

      return WishlistItem.fromSupabaseJson(data, data["id"].toString());
    } catch (e) {
      print("getWishlistItem error: $e");
      return null;
    }
  }


  static Future<List<WishlistItem>> getUserWishlistItemCount(
    String userId,
  ) async {
    try {
      final rows = await _supabase
          .from(_wishlistTable)
          .select("""
            *,
            product:products(*)
          """)
          .eq("user_id", userId)
          .order("added_at", ascending: false);

      final wishlist = rows.map((row) {
        final data = Map<String, dynamic>.from(row);

        data["product_id"] = data["product_id"].toString();
        data["product"] = row["product"];

        return WishlistItem.fromSupabaseJson(data, data["id"].toString());
      }).toList();

      print("getUserWishlist: ${wishlist.length} items");
      return wishlist;
    } catch (e) {
      print("getUserWishlist error: $e");
      return [];
    }
  }

  static Future<bool> removeFromWishlist(
    String userId,
    String productId,
  ) async {
    try {
      final deletedRows = await _supabase
          .from(_wishlistTable)
          .delete()
          .eq("user_id", userId)
          .eq("product_id", productId.toString())
          .select();

      final removedCount = (deletedRows as List).length;

      print("Removed $removedCount item(s) from wishlist");

      return removedCount > 0;
    } catch (e) {
      print("removeFromWishlist error: $e");
      return false;
    }
  }

  static Stream<List<WishlistItem>> getUserWishListItemsStream(String userId) {
    return _supabase
        .from("$_wishlistTable:user_id=eq.$userId")
        .stream(primaryKey: ["id"]).map((rows) {
      final wishlist = (rows as List).map((row) {
        final data = Map<String, dynamic>.from(row);

        data["product_id"] = data["product_id"].toString();
        return WishlistItem.fromSupabaseJson(data, data["id"].toString());
      }).toList();

      print("Wishlist update: ${wishlist.length} items");

      return wishlist;
    });
  }

  static Future<bool> isProductInWishList(
    String userId,
    String productId,
  ) async {
    try {
      final rows = await _supabase
          .from(_wishlistTable)
          .select("product_id")
          .eq("user_id", userId)
          .eq("product_id", productId.toString()) as List;

      return rows.isNotEmpty;
    } catch (e) {
      print("isInWishlist error: $e");
      return false;
    }
  }

  static Future<bool> clearUserWishlist(String userId) async {
    try {
      final deletedItems =
          await _supabase.from(_wishlistTable).delete().eq("user_id", userId)
              as List<dynamic>?;

      print("Cleared wishlist: ${deletedItems?.length ?? 0} items");
      return true;
    } catch (e) {
      print("clearUserWishlist error: $e");
      return false;
    }
  }

  static Future<bool> toggleWishlist(String userId, Products product) async {
    try {
      final exists = await isProductInWishList(userId, product.id);
      if (exists) {
        await removeFromWishlist(userId, product.id);
        print("Removed from wishlist: ${product.name}");
        return false;
      } else {
        await addToWishlist(userId: userId, product: product);
        print("Added to wishlist: ${product.name}");
        return true;
      }
    } catch (e) {
      print("toggleWishlist error: $e");
      return false;
    }
  }
}
