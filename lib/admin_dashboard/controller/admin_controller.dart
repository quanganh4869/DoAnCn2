import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/models/category.dart';
import 'package:ecomerceapp/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/supabase/order_supabase_services.dart';

enum AdminPage {
  dashboard,
  sellerRequests,
  userManagement,
  productManagement,
  categoryManagement,
  settings,
}

class AdminController extends GetxController {
  final _supabase = Supabase.instance.client;

  RxBool isLoading = false.obs;
  Rx<AdminPage> currentPage = AdminPage.dashboard.obs;
  RxList<UserProfile> usersList = <UserProfile>[].obs;
  RxList<UserProfile> pendingRequests = <UserProfile>[].obs;
  RxList<Map<String, dynamic>> salesData = <Map<String, dynamic>>[].obs;
  RxString currentSearchQuery = ''.obs;
  RxList<Category> categoriesList = <Category>[].obs;
  RxList<Products> adminProductsList = <Products>[].obs;

  var totalPlatformRevenue = 0.0.obs;
  var totalUsersCount = 0.obs;
  var totalOrdersCount = 0.obs;

  var recentOrders = <Order>[].obs;
  var monthlyRevenue = <double>[0, 0, 0, 0, 0, 0, 0].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPendingSellers();
    fetchDashboardStats();
  }

  void navigateTo(AdminPage page) {
    currentPage.value = page;
  }

  Future<void> fetchDashboardStats() async {
    try {
      final userRes = await _supabase
          .from('users')
          .select('id')
          .count(CountOption.exact);
      totalUsersCount.value = userRes.count;

      // 2. Lấy Đơn hàng (Lấy 50 đơn gần nhất để tính toán nhanh cho Dashboard)
      final orderRes = await _supabase
          .from('orders')
          .select('''
            *,
            order_items(
              id, product_id, quantity, price_at_purchase,
              products(name, images)
            )
          ''')
          .order('created_at', ascending: false)
          .limit(50);

      final List<dynamic> data = orderRes;
      final List<Order> loadedOrders = data
          .map((json) => Order.fromSupabaseJson(json))
          .toList();

      // Cập nhật danh sách đơn mới nhất cho trang Home
      recentOrders.assignAll(loadedOrders.take(5).toList());
      totalOrdersCount.value = loadedOrders.length; // (Số lượng tải về)

      // 3. Tính tổng doanh thu & Biểu đồ 7 ngày
      double revenue = 0;
      List<double> chartData = List.filled(7, 0.0);
      final now = DateTime.now();

      for (var order in loadedOrders) {
        if (order.status == OrderStatus.completed) {
          revenue += order.totalAmount;

          final diff = now.difference(order.orderDate).inDays;
          if (diff >= 0 && diff < 7) {
            chartData[6 - diff] += order.totalAmount;
          }
        }
      }

      totalPlatformRevenue.value = revenue;
      monthlyRevenue.assignAll(chartData);
    } catch (e) {
      print("Dashboard Stats Error: $e");
    }
  }

  Future<void> fetchPendingSellers() async {
    try {
      // Truy vấn trực tiếp bảng users
      final response = await _supabase
          .from('users')
          .select()
          .eq('seller_status', 'pending')
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;

      // Map dữ liệu sang UserProfile
      pendingRequests.value = data
          .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching pending sellers: $e");
    }
  }

  Future<void> approveOrRejectSeller(String userId, bool isApproved) async {
    isLoading.value = true;

    final newStatus = isApproved ? 'active' : 'rejected';

    final newRole = isApproved ? 'seller' : 'user';

    try {
      final updateData = {'seller_status': newStatus, 'role': newRole};

      await _supabase.from('users').update(updateData).eq('id', userId);

      pendingRequests.removeWhere((user) => user.id == userId);

      final index = usersList.indexWhere((u) => u.id == userId);
      if (index != -1) {
        usersList[index] = usersList[index].copyWith(
          sellerStatus: newStatus,
          role: newRole,
        );
      }

      Get.snackbar(
        "Thành công",
        isApproved
            ? "Đã duyệt Shop! User đã được cấp quyền Seller."
            : "Đã từ chối yêu cầu mở Shop.",
        backgroundColor: isApproved
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        colorText: isApproved ? Colors.green : Colors.red,
        icon: Icon(
          isApproved ? Icons.check_circle : Icons.cancel,
          color: isApproved ? Colors.green : Colors.red,
        ),
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      print("Approve Error: $e");
      Get.snackbar(
        "Lỗi xử lý",
        "Chi tiết: $e",
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 2. QUẢN LÝ USER (USER MANAGEMENT)

  Future<void> fetchUsers({String query = ''}) async {
    isLoading.value = true;
    currentSearchQuery.value = query;
    try {
      var dbQuery = _supabase.from('users').select();

      if (query.isNotEmpty) {
        dbQuery = dbQuery.or(
          'full_name.ilike.%$query%,email.ilike.%$query%,phone.ilike.%$query%,shop_name.ilike.%$query%',
        );
      }

      final response = await dbQuery.order('created_at', ascending: false);
      usersList.value = (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      print("User fetch error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserActiveStatus(String userId, bool isActive) async {
    try {
      await _supabase
          .from('users')
          .update({'is_active': isActive})
          .eq('id', userId);

      // Cập nhật UI Local
      final index = usersList.indexWhere((user) => user.id == userId);
      if (index != -1) {
        usersList[index] = usersList[index].copyWith(isActive: isActive);
      }
      Get.snackbar(
        "Thành công",
        "Đã cập nhật trạng thái User",
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể cập nhật User: $e");
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);

      usersList.removeWhere((u) => u.id == userId);
      pendingRequests.removeWhere((u) => u.id == userId);

      Get.snackbar(
        "Đã xóa",
        "Đã xóa hồ sơ User khỏi database.",
        backgroundColor: Colors.grey.withValues(alpha: 0.2),
      );
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể xóa User: $e");
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final orders = await OrderSupabaseService.getMyOrders(userId);

      double totalSpent = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;

      Map<String, double> categoryStats = {};

      for (var o in orders) {
        if (o.status == OrderStatus.completed) {
          totalSpent += o.totalAmount;
          completedOrders++;

          for (var item in o.items) {
            String catName = "General";
            if (item.productName.toLowerCase().contains('laptop'))
              catName = "Laptop";
            else if (item.productName.toLowerCase().contains('phone'))
              catName = "Phone";
            else if (item.productName.toLowerCase().contains('shirt') ||
                item.productName.toLowerCase().contains('shoes'))
              catName = "Fashion";

            // Cộng dồn tiền vào danh mục
            double itemTotal = item.price * item.quantity;
            categoryStats[catName] = (categoryStats[catName] ?? 0) + itemTotal;
          }
        } else if (o.status == OrderStatus.cancelled) {
          cancelledOrders++;
        }
      }

      return {
        'total_spent': totalSpent,
        'total_orders': orders.length,
        'completed_orders': completedOrders,
        'cancelled_orders': cancelledOrders,
        'orders': orders,
        'category_distribution': categoryStats, // Trả về map phân bổ danh mục
      };
    } catch (e) {
      print("Error fetching user stats: $e");
      return {
        'total_spent': 0.0,
        'total_orders': 0,
        'orders': <Order>[],
        'category_distribution': <String, double>{},
      };
    }
  }

  Future<Map<String, dynamic>> getUserDeepAnalytics(String userId) async {
    try {
      // 1. Lấy thông tin đơn hàng (như cũ)
      final orders = await OrderSupabaseService.getMyOrders(userId);
      double totalSpent = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      for (var o in orders) {
        if (o.status == OrderStatus.completed) {
          totalSpent += o.totalAmount;
          completedOrders++;
        } else if (o.status == OrderStatus.cancelled) {
          cancelledOrders++;
        }
      }

      // 2. Lấy lịch sử hành vi từ bảng user_behaviors
      // Join với bảng products để biết đó là sản phẩm gì, thuộc danh mục nào
      final behaviorResponse = await _supabase
          .from('user_behaviors')
          .select('*, products(name, category, images)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50); // Lấy 50 hành động gần nhất

      final behaviors = behaviorResponse as List<dynamic>;

      // 3. Tính toán Điểm Sở Thích (Category Interest Score)
      Map<String, double> categoryScores = {};

      for (var b in behaviors) {
        final product = b['products'];
        if (product != null) {
          final cat = product['category'] ?? 'Other';
          final score = (b['score'] as num).toDouble();

          // Cộng dồn điểm: Xem (+5), Thêm giỏ (+9), Mua (+10)...
          categoryScores[cat] = (categoryScores[cat] ?? 0) + score;
        }
      }

      return {
        'total_spent': totalSpent,
        'total_orders': orders.length,
        'completed_orders': completedOrders,
        'cancelled_orders': cancelledOrders,
        'orders': orders,
        'behaviors': behaviors,
        'category_interests': categoryScores,
      };
    } catch (e) {
      print("Error fetching deep analytics: $e");
      return {};
    }
  }

  /// Lấy danh sách sản phẩm của Seller (nếu user này là Seller)
  Future<List<Products>> getUserProducts(String userId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('seller_id', userId);

      if (response != null) {
        return (response as List)
            .map((e) => Products.fromSupabaseJson(e, e['id'].toString()))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching user products: $e");
      return [];
    }
  }

  // 3. STATS (DASHBOARD)
  Future<void> fetchDailySalesData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    salesData.value = [
      {'day': 'Mon', 'sales': 1200},
      {'day': 'Tue', 'sales': 1800},
      {'day': 'Wed', 'sales': 1500},
      {'day': 'Thu', 'sales': 2200},
      {'day': 'Fri', 'sales': 2500},
      {'day': 'Sat', 'sales': 1900},
      {'day': 'Sun', 'sales': 2100},
    ];
  }

  // Category
  Future<void> fetchCategories({String query = ''}) async {
    isLoading.value = true;
    try {
      var dbQuery = _supabase.from('categories').select();

      if (query.isNotEmpty) {
        dbQuery = dbQuery.ilike('display_name', '%$query%');
      }

      final response = await dbQuery.order('sort_order', ascending: true);
      final data = response as List<dynamic>;

      categoriesList.value = data
          .map(
            (json) => Category.fromSupabaseJson(
              json as Map<String, dynamic>,
              json['id'].toString(),
            ),
          )
          .toList();
    } catch (e) {
      print("Category fetch error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCategory({
    required String name,
    required String displayName,
    String? description,
    String? iconUrl,
    String? imageUrl,
    int sortOrder = 0,
    List<String> subcategories = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    isLoading.value = true;
    try {
      // Map các trường đúng với cột trong Supabase (thường là snake_case)
      await _supabase.from('categories').insert({
        'name': name,
        'display_name': displayName,
        'description': description,
        'icon_url': iconUrl,
        'image_url': imageUrl,
        'sort_order': sortOrder,
        'subcategories': subcategories,
        'metadata': metadata,
        'is_active': true,
      });

      Get.snackbar(
        "Success",
        "New category added",
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
      fetchCategories(); // Refresh list
    } catch (e) {
      Get.snackbar("Error", "Failed to add category: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 4.3 UPDATE
  Future<void> updateCategory(Category category) async {
    // Optimistic UI Update
    int index = categoriesList.indexWhere((c) => c.id == category.id);
    Category? oldCategory;
    if (index != -1) {
      oldCategory = categoriesList[index];
      categoriesList[index] = category;
    }

    try {
      // Update các trường, dùng key snake_case để khớp với DB Supabase
      await _supabase
          .from('categories')
          .update({
            'name': category.name,
            'display_name': category.displayName,
            'description': category.description,
            'icon_url': category.iconUrl,
            'image_url': category.imageUrl,
            'is_active': category.isActive,
            'sort_order': category.sortOrder,
            'subcategories': category.subcategories,
            'metadata': category.metadata,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', category.id);

      Get.snackbar("Success", "Category updated");
    } catch (e) {
      // Revert if failed
      if (index != -1 && oldCategory != null) {
        categoriesList[index] = oldCategory;
      }
      Get.snackbar("Error", "Update failed: $e");
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _supabase.from('categories').delete().eq('id', id);
      categoriesList.removeWhere((c) => c.id == id);
      Get.snackbar("Deleted", "Category removed");
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete (Category might contain products): $e",
      );
    }
  }

  // product
  Future<void> fetchAllAdminProducts({String query = ''}) async {
    isLoading.value = true;
    currentSearchQuery.value = query;
    try {
      // Join với bảng users để biết sản phẩm của Shop nào
      var dbQuery = _supabase
          .from('products')
          .select('*, users(shop_name, email)');

      if (query.isNotEmpty) {
        // Tìm theo tên sản phẩm
        dbQuery = dbQuery.ilike('name', '%$query%');
      }

      final response = await dbQuery.order('created_at', ascending: false);
      final data = response as List<dynamic>;

      adminProductsList.value = data
          .map((json) => Products.fromSupabaseJson(json, json['id'].toString()))
          .toList();
    } catch (e) {
      print("Admin Product fetch error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 5.2 Cấm/Mở bán sản phẩm (Toggle Active)
  Future<void> toggleProductActiveStatus(
    String productId,
    bool isActive,
  ) async {
    try {
      await _supabase
          .from('products')
          .update({'is_active': isActive})
          .eq('id', productId);

      // Cập nhật UI local
      final index = adminProductsList.indexWhere((p) => p.id == productId);
      if (index != -1) {
        fetchAllAdminProducts(query: currentSearchQuery.value);
      }

      Get.snackbar(
        "Thành công",
        isActive ? "Đã mở bán sản phẩm" : "Đã ẩn sản phẩm (Ban)",
        backgroundColor: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        colorText: isActive ? Colors.green : Colors.orange,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể cập nhật: $e");
    }
  }

  // 5.3 Xóa vĩnh viễn sản phẩm (Cần thận trọng)
  Future<void> deleteAdminProduct(String productId) async {
    try {
      await _supabase.from('products').delete().eq('id', productId);
      adminProductsList.removeWhere((p) => p.id == productId);
      Get.snackbar(
        "Đã xóa",
        "Sản phẩm đã bị xóa vĩnh viễn.",
        backgroundColor: Colors.grey.withOpacity(0.2),
      );
    } catch (e) {
      Get.snackbar("Lỗi", "Xóa thất bại (có thể do ràng buộc đơn hàng): $e");
    }
  }

  // Ban
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      // Cập nhật DB
      await _supabase
          .from('users')
          .update({'is_active': isActive})
          .eq('id', userId);

      // Cập nhật UI Local (Optimistic Update)
      final index = usersList.indexWhere((user) => user.id == userId);
      if (index != -1) {
        usersList[index] = usersList[index].copyWith(isActive: isActive);
        usersList.refresh(); // Force refresh UI
      }

      Get.snackbar(
        isActive ? "Đã mở khóa" : "Đã khóa tài khoản",
        isActive
            ? "User có thể đăng nhập bình thường."
            : "User này đã bị cấm hoạt động.",
        backgroundColor: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        colorText: isActive ? Colors.green : Colors.red,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể cập nhật trạng thái User: $e");
    }
  }

  // --- 2. HAM BAN/UNBAN PRODUCT (SẢN PHẨM) ---
  Future<void> toggleProductStatus(String productId, bool isActive) async {
    try {
      await _supabase
          .from('products')
          .update({'is_active': isActive})
          .eq('id', productId);

      final index = adminProductsList.indexWhere((p) => p.id == productId);
      if (index != -1) {
        fetchAllAdminProducts(query: currentSearchQuery.value);
      }

      Get.snackbar(
        isActive ? "Đã hiện sản phẩm" : "Đã ẩn sản phẩm",
        isActive
            ? "Sản phẩm đã hiển thị lại trên sàn."
            : "Sản phẩm đã bị ẩn khỏi người dùng.",
        backgroundColor: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        colorText: isActive ? Colors.green : Colors.orange,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể cập nhật trạng thái Sản phẩm: $e");
    }
  }

  // --- 3. HAM BAN/UNBAN CATEGORY (DANH MỤC) ---
  Future<void> toggleCategoryStatus(String categoryId, bool isActive) async {
    try {
      await _supabase
          .from('categories')
          .update({'is_active': isActive})
          .eq('id', categoryId);

      // Cập nhật UI
      final index = categoriesList.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        categoriesList[index] = categoriesList[index].copyWith(
          isActive: isActive,
        );
        categoriesList.refresh();
      }

      Get.snackbar(
        isActive ? "Đã hiện danh mục" : "Đã ẩn danh mục",
        isActive
            ? "Danh mục này đã hiển thị lại."
            : "Danh mục này tạm thời bị ẩn.",
        backgroundColor: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        colorText: isActive ? Colors.green : Colors.orange,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể cập nhật danh mục: $e");
    }
  }

  // GỠ QUYỀN SELLER
  Future<void> revokeSellerRole(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({'role': 'user', 'seller_status': 'none'})
          .eq('id', userId);

      final index = usersList.indexWhere((u) => u.id == userId);
      if (index != -1) {
        usersList[index] = usersList[index].copyWith(
          role: 'user',
          sellerStatus: 'none',
        );
        usersList.refresh();
      }

      Get.snackbar(
        "Thành công",
        "Đã gỡ quyền Seller của tài khoản này.",
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể gỡ quyền: $e");
    }
  }
}
