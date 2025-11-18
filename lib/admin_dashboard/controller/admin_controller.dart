import 'package:get/get.dart';
import 'package:ecomerceapp/models/user_profile.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/admin_dashboard/model/seller_request.dart';

enum AdminPage { 
  dashboard, 
  sellerRequests, 
  userManagement, 
  productManagement, 
  categoryManagement, 
  salesAnalysis,
  settings
}

class AdminController extends GetxController {
  final _supabase = Supabase.instance.client;
  
  // STATE & NAVIGATION
  Rx<AdminPage> currentPage = AdminPage.dashboard.obs;
  RxBool isLoading = false.obs;
  
  // DASHBOARD STATS
  RxInt totalProducts = 0.obs;
  RxInt totalSellers = 0.obs;
  RxList<SellerRequest> pendingRequests = <SellerRequest>[].obs;
  RxList salesData = [].obs; // Dữ liệu cho biểu đồ/phân tích

  // MANAGEMENT LISTS & SEARCH
  RxList<UserProfile> usersList = <UserProfile>[].obs;
  RxList sellersList = <SellerRequest>[].obs; // Dùng SellerRequest để có cả UserProfile
  RxString currentSearchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Khởi tạo các lần fetch ban đầu
    // fetchDashboardData();
    fetchPendingSellers();
    fetchUsers(query: ''); // Load danh sách user ban đầu
  }

  void navigateTo(AdminPage page) {
    currentPage.value = page;
  }
  
  // ============================================================
  //  1. CHỨC NĂNG DUYỆT NGƯỜI BÁN (SELLER REQUESTS)
  // ============================================================

  // Trong lib/controller/admin_controller.dart

// Đảm bảo bạn đã có các biến này:
// RxList<SellerRequest> pendingRequests = <SellerRequest>[].obs;
// RxBool isLoading = false.obs;
// final _supabase = Supabase.instance.client;

Future<void> fetchPendingSellers() async {
    isLoading.value = true;
    try {
        // Query bảng sellers, JOIN với bảng users để lấy thông tin người đăng ký
        final response = await _supabase
            .from('sellers')
            .select('*, users(*)') 
            .eq('status', 'pending')
            .order('created_at', ascending: false);
        
        final data = response as List<dynamic>;
        
        // Chuyển đổi JSON thành Model SellerRequest (kết hợp Seller và UserProfile)
        pendingRequests.value = data
            .map((json) => SellerRequest.fromSupabaseJson(json as Map<String, dynamic>))
            .toList();

    } catch (e) {
        print("Error fetching pending sellers: $e");
        // Bạn có thể thêm Get.snackbar("Error", "Failed to load seller requests");
    } finally {
        isLoading.value = false;
    }
}
  
  Future<void> updateSellerStatus(String sellerId, String status) async {
    isLoading.value = true;
    try {
        await _supabase
            .from('sellers')
            .update({'status': status})
            .eq('id', sellerId);
        
        pendingRequests.removeWhere((req) => req.seller.id == sellerId);
        Get.snackbar("Success", "Seller status updated to $status");
    } catch (e) {
        Get.snackbar("Error", "Failed to update seller status");
    } finally {
        isLoading.value = false;
    }
  }

  // ============================================================
  //  2. QUẢN LÝ USER & SELLER (CHẶN/TÌM KIẾM)
  // ============================================================
  
  // Tải danh sách User (và tìm kiếm)
  Future<void> fetchUsers({String query = ''}) async {
    isLoading.value = true;
    currentSearchQuery.value = query;
    try {
      var dbQuery = _supabase.from('users').select();
      
      if (query.isNotEmpty) {
          // Tìm kiếm theo full_name HOẶC email HOẶC phone
          dbQuery = dbQuery.or('full_name.ilike.%$query%,email.ilike.%$query%,phone.ilike.%$query%');
      }
      
      final response = await dbQuery;

      usersList.value = (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
      
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch users");
      print("User fetch error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Chặn/Mở chặn User (Chỉ áp dụng cho User thường, không phải Seller)
  Future<void> updateUserActiveStatus(String userId, bool isActive) async {
    try {
        await _supabase
            .from('users')
            .update({'is_active': isActive})
            .eq('id', userId);
        
        // Cập nhật state local
        final index = usersList.indexWhere((user) => user.id == userId);
        if (index != -1) {
            final updatedUser = usersList[index].copyWith(isActive: isActive);
            usersList[index] = updatedUser;
        }
        Get.snackbar("Success", "User status updated");
    } catch (e) {
        Get.snackbar("Error", "Failed to block user");
    }
  }
  
  // Tải danh sách Sellers (và tìm kiếm)
  Future<void> fetchSellers({String query = ''}) async {
    // Logic tương tự fetchUsers, nhưng bạn cần JOIN với bảng users để có thông tin
    // Hoặc query bảng sellers nếu bạn chỉ cần shop_name
  }


  // ============================================================
  //  3. PHÂN TÍCH DOANH SỐ (SALES ANALYSIS)
  // ============================================================

  // Giả lập hàm lấy dữ liệu cho biểu đồ mua hàng trong ngày (chưa có bảng Orders)
  Future<void> fetchDailySalesData() async {
    // Logic: SELECT date_trunc('day', created_at) AS day, SUM(total_amount) AS sales FROM orders GROUP BY day
    // Do chưa có bảng orders, chúng ta mock data
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
  
  // Lọc sản phẩm được bán trong ngày (ví dụ: lấy top 10 sản phẩm bán chạy nhất ngày hôm nay)
  Future<void> fetchTopSellingProducts(DateTime date) async {
    // Logic: Query bảng order_items (nếu có) hoặc orders, lọc theo ngày và group by product_id
    // ...
  }
}