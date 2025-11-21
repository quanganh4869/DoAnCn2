import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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

  // STATE
  RxBool isLoading = false.obs;
  Rx<AdminPage> currentPage = AdminPage.dashboard.obs;

  // LISTS
  RxList<UserProfile> usersList = <UserProfile>[].obs;

  // Thay đổi: List chờ duyệt giờ là UserProfile (vì thông tin shop nằm trong user)
  RxList<UserProfile> pendingRequests = <UserProfile>[].obs;

  RxList<Map<String, dynamic>> salesData = <Map<String, dynamic>>[].obs;

  // SEARCH
  RxString currentSearchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPendingSellers();
  }

  void navigateTo(AdminPage page) {
    currentPage.value = page;
  }

  // 1. QUẢN LÝ YÊU CẦU SELLER (LOGIC MỚI - SINGLE TABLE)

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

  /// Duyệt hoặc Từ chối yêu cầu làm Seller
  /// userId: ID của user cần duyệt
  Future<void> approveOrRejectSeller(String userId, bool isApproved) async {
    isLoading.value = true;

    // Trạng thái mới: 'active' hoặc 'rejected'
    final newStatus = isApproved ? 'active' : 'rejected';

    // Role mới: Nếu duyệt -> lên 'seller', nếu từ chối -> về 'user' (hoặc giữ nguyên)
    final newRole = isApproved ? 'seller' : 'user';

    try {
      // Cập nhật bảng users (Gộp cả status và role vào 1 lệnh update)
      final updateData = {
        'seller_status': newStatus,
        'role': newRole, // Cấp quyền seller luôn nếu duyệt
      };

      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', userId);

      // --- CẬP NHẬT UI LOCAL (Không cần fetch lại API) ---

      // 1. Xóa khỏi danh sách chờ (pendingRequests)
      pendingRequests.removeWhere((user) => user.id == userId);

      // 2. Cập nhật trong danh sách quản lý user (usersList) nếu đang hiển thị
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
        backgroundColor: isApproved ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        colorText: isApproved ? Colors.green : Colors.red,
        icon: Icon(
          isApproved ? Icons.check_circle : Icons.cancel,
          color: isApproved ? Colors.green : Colors.red
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

  // ============================================================
  // 2. QUẢN LÝ USER (USER MANAGEMENT)
  // ============================================================

  Future<void> fetchUsers({String query = ''}) async {
    isLoading.value = true;
    currentSearchQuery.value = query;
    try {
      var dbQuery = _supabase.from('users').select();

      if (query.isNotEmpty) {
        // Tìm kiếm theo tên, email, sđt hoặc tên shop
        dbQuery = dbQuery.or('full_name.ilike.%$query%,email.ilike.%$query%,phone.ilike.%$query%,shop_name.ilike.%$query%');
      }

      final response = await dbQuery.order('created_at', ascending: false);
      usersList.value = (response as List).map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      print("User fetch error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserActiveStatus(String userId, bool isActive) async {
    try {
      await _supabase.from('users').update({'is_active': isActive}).eq('id', userId);

      // Cập nhật UI Local
      final index = usersList.indexWhere((user) => user.id == userId);
      if (index != -1) {
        usersList[index] = usersList[index].copyWith(isActive: isActive);
      }
      Get.snackbar(
        "Thành công", "Đã cập nhật trạng thái User",
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
      // Xóa user khỏi bảng users (Các bảng con như cart/order sẽ xóa theo nếu setup Cascade Delete ở DB)
      await _supabase.from('users').delete().eq('id', userId);

      // Xóa auth user (Chỉ Admin mới làm được, cần setup function bên Supabase hoặc dùng Service Role Key ở Backend)
      // Lưu ý: Client SDK thường không xóa được Auth User trực tiếp vì lý do bảo mật

      usersList.removeWhere((u) => u.id == userId);
      pendingRequests.removeWhere((u) => u.id == userId);

      Get.snackbar("Đã xóa", "Đã xóa hồ sơ User khỏi database.", backgroundColor: Colors.grey.withValues(alpha: 0.2));
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể xóa User: $e");
    }
  }

  Future<List<Products>> getUserProducts(String userId) async {
    try {
      // Logic mới: Truy vấn trực tiếp products where seller_id = userId
      // Không cần check bảng sellers nữa vì seller_id chính là user_id
      final response = await _supabase
          .from('products')
          .select() // Bỏ join sellers vì bảng không còn
          .eq('seller_id', userId);

      if (response != null) {
        // Lưu ý: Products.fromSupabaseJson cần được cập nhật nếu nó đang map trường seller lồng nhau
        // Ở đây mình giả định product model xử lý được
        return (response as List).map((e) => Products.fromSupabaseJson(e, e['id'].toString())).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching user products: $e");
      return [];
    }
  }

  // ============================================================
  // 3. STATS (DASHBOARD)
  // ============================================================

  Future<void> fetchDailySalesData() async {
    // Giả lập data
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
}