import 'package:ecomerceapp/models/category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategorySupabaseServices {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _categoryTable = "categories";

  // Lấy tất cả Danh mục đang hoạt động (is_active = true)
  static Future<List<Category>> getAllCategories() async {
    try {
      final response = await _supabase
          .from(_categoryTable)
          .select(
            'id, name, display_name, description, icon_url, image_url, is_active, sort_order, subcategories, metadata, created_at, updated_at',
          )
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      print("Supabase response: $response");
      return (response as List)
          .map((data) => Category.fromSupabaseJson(data, data['id'].toString()))
          .toList();
    } catch (e) {
      print("Error fetching category: $e");
      return [];
    }
  }

  // Lấy Danh mục theo ID
  static Future<Category?> getCategoryById(String categoryid) async {
    try {
      final response = await _supabase
          .from(_categoryTable)
          .select()
          .eq('id', categoryid)
          .maybeSingle();

      if (response == null) return null;
      return Category.fromSupabaseJson(response, categoryid);
    } catch (e) {
      print("Error fatching category by ID: $e");
    }
  }

  // Lấy Danh mục theo tên
  static Future<Category?> getCategoryByName(String categoryname) async {
    try {
      final response = await _supabase
          .from(_categoryTable)
          .select()
          .ilike('name', categoryname)
          .maybeSingle();

      if (response == null) return null;
      return Category.fromSupabaseJson(response, response['id'].toString());
    } catch (e) {
      print("Error fatching category by name: $e");
      return null;
    }
  }

  // Lấy stream realtime khi bảng Danh mục có thay đổi
  static Stream<List<Category>> getCategoryStream() {
    return _supabase
        .from('categories:is_active=eq.true')
        .stream(primaryKey: ['id'])
        .map(
          (rows) => rows
              .map(
                (data) =>
                    Category.fromSupabaseJson(data, data['id'].toString()),
              )
              .toList(),
        );
  }

  // Tạo Danh mục mới
  static Future<bool> createCategory(Category category) async {
    try {
      await _supabase.from(_categoryTable).insert(category.toSupabasestore());
      return true;
    } catch (e) {
      print("Error create category: $e");
      return false;
    }
  }

  /// 🟦 Cập nhật Danh mục
  static Future<bool> updateCategory(
    String categoryId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from(_categoryTable).update(updates).eq('id', categoryId);
      return true;
    } catch (e) {
      print("Error update category: $e");
      return false;
    }
  }

  // Xóa Danh mục (set is_active = false)
  static Future<bool> DeleteCategory(String categoryId) async {
    try {
      await _supabase
          .from(_categoryTable)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', categoryId);
      return true;
    } catch (e) {
      print("Error deleting category: $e");
      return false;
    }
  }

  // Kiểm tra Danh mục có tồn tại không
  static Future<bool> categoryExists(String categoryName) async {
    final response = await _supabase
        .from(_categoryTable)
        .select('id')
        .ilike('name', categoryName)
        .maybeSingle();

    return response != null;
  }
}
