import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/models/wishlist.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistSupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _wishlistTable = "wishlist";

  // 🔹 Add product to wishlist
  static Future<bool> addToWishlist({
    required String userId,
    required Products product,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final existingItem = await getWishlistItem(userId, product.id);
      if (existingItem != null) return true;

      final wishlistItem = Wishlist(
        id: '',
        userId: userId,
        productId: product.id,
        product: product,
        addedAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      await _supabase.from(_wishlistTable).insert({
        "userId": wishlistItem.userId,
        "productId": wishlistItem.productId,
        "product": {"id": wishlistItem.product.id},
        "addedAt": wishlistItem.addedAt.toIso8601String(),
        "metadata": wishlistItem.metadata,
      });

      print(" Added to wishlist: ${product.name}");
      return true;
    } catch (e) {
      print(" addToWishlist error: $e");
      return false;
    }
  }

  // 🔹 Get specific wishlist item
  static Future<Wishlist?> getWishlistItem(String userId, String productId) async {
    try {
      final data = await _supabase
          .from(_wishlistTable)
          .select()
          .eq("userId", userId)
          .eq("productId", productId)
          .maybeSingle() as Map<String, dynamic>?;

      if (data == null) return null;
      return Wishlist.fromSupabaseJson(data, data["id"].toString());
    } catch (e) {
      print(" getWishlistItem error: $e");
      return null;
    }
  }

  // 🔹 Remove product from wishlist
  static Future<bool> removeFromWishlist(String userId, String productId) async {
    try {
      final deletedItems = await _supabase
          .from(_wishlistTable)
          .delete()
          .eq("userId", userId)
          .eq("productId", productId) as List<dynamic>?;

      print("Removed $deletedItems item(s) from wishlist");
      return (deletedItems?.isNotEmpty ?? false);
    } catch (e) {
      print("removeFromWishlist error: $e");
      return false;
    }
  }

  // 🔹 Get all wishlist items for a user
  static Future<List<Wishlist>> getUserWishlist(String userId) async {
    try {
      final dataList = await _supabase
          .from(_wishlistTable)
          .select()
          .eq("userId", userId)
          .order("addedAt", ascending: false) as List<dynamic>?;

      if (dataList == null) return [];

      final wishlist = dataList
          .map((data) => Wishlist.fromSupabaseJson(Map<String, dynamic>.from(data), data["id"].toString()))
          .toList();

      print("getUserWishlist: ${wishlist.length} items");
      return wishlist;
    } catch (e) {
      print(" getUserWishlist error: $e");
      return [];
    }
  }

  // 🔹 Listen to wishlist changes in realtime
  static Stream<List<Wishlist>> listenToUserWishlist(String userId) {
    try {
      return _supabase
          .from("$_wishlistTable:userId=eq.$userId")
          .stream(primaryKey: ["id"])
          .map((rows) {
        final wishlist = (rows as List)
            .map((data) => Wishlist.fromSupabaseJson(Map<String, dynamic>.from(data), data["id"].toString()))
            .toList();

        print("Wishlist update: ${wishlist.length} items");
        return wishlist;
      });
    } catch (e) {
      print("listenToUserWishlist error: $e");
      return const Stream.empty();
    }
  }

  // 🔹 Check if a product is in wishlist
  static Future<bool> isInWishlist(String userId, String productId) async {
    try {
      final data = await _supabase
          .from(_wishlistTable)
          .select()
          .eq("userId", userId)
          .eq("productId", productId)
          .maybeSingle() as Map<String, dynamic>?;

      return data != null;
    } catch (e) {
      print("isInWishlist error: $e");
      return false;
    }
  }

  // 🔹 Clear entire wishlist
  static Future<bool> clearUserWishlist(String userId) async {
    try {
      final deletedItems = await _supabase.from(_wishlistTable).delete().eq("userId", userId) as List<dynamic>?;
      print(" Cleared wishlist: ${deletedItems?.length ?? 0} items");
      return true;
    } catch (e) {
      print(" clearUserWishlist error: $e");
      return false;
    }
  }

  // 🔹 Toggle wishlist item (add/remove)
  static Future<bool> toggleWishlist(String userId, Products product) async {
    try {
      final exists = await isInWishlist(userId, product.id);
      if (exists) {
        await removeFromWishlist(userId, product.id);
        print(" Removed from wishlist: ${product.name}");
        return false; // Removed
      } else {
        await addToWishlist(userId: userId, product: product);
        print(" Added to wishlist: ${product.name}");
        return true; // Added
      }
    } catch (e) {
      print(" toggleWishlist error: $e");
      return false;
    }
  }
}
