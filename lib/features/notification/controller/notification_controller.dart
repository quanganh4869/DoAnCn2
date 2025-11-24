import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/features/notification/models/notification_type.dart';

class NotificationController extends GetxController {
  final _supabase = Supabase.instance.client;

  // Danh sách thông báo
  var notifications = <NotificationItem>[].obs;

  // --- BIẾN ĐẾM (Đã khôi phục) ---
  var unreadCount = 0.obs; // Tổng số chưa đọc (Chung)

  // Getter đếm riêng cho User (Khách mua)
  int get unreadUserCount => notifications
      .where((n) => !n.isRead && (n.metadata?['role'] == 'user' || n.metadata?['role'] == null))
      .length;

  // Getter đếm riêng cho Seller (Người bán)
  int get unreadSellerCount => notifications
      .where((n) => !n.isRead && n.metadata?['role'] == 'seller')
      .length;

  // --- Selection Mode ---
  var isSelectionMode = false.obs;
  var selectedIds = <String>{}.obs;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null) _setupRealtimeSubscription();
    });
    if (_supabase.auth.currentUser != null) _setupRealtimeSubscription();
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  void _setupRealtimeSubscription() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> data) {

      final parsedList = data.map((e) => NotificationItem.fromSupabaseJson(e)).toList();

      notifications.assignAll(parsedList);
      _updateUnreadCount(); // Cập nhật số lượng
    });
  }

  // Hàm helper để cập nhật biến unreadCount
  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  static Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': receiverId,
        'title': title,
        'message': message,
        'type': type.name,
        'is_read': false,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Cập nhật UI ngay lập tức (Optimistic)
    /* Lưu ý: Vì NotificationItem thường là final, ta không sửa trực tiếp được.
       Realtime Stream sẽ tự cập nhật lại list khi DB thay đổi.
       Nhưng ta có thể reset biến đếm tạm thời để UI phản hồi nhanh.
    */
    unreadCount.value = 0;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> markAsRead(String notificationId) async {
    // Cập nhật DB
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // --- SELECTION & DELETE LOGIC ---

  void enterSelectionMode(String initialId) {
    isSelectionMode.value = true;
    selectedIds.clear();
    selectedIds.add(initialId);
  }

  void exitSelectionMode() {
    isSelectionMode.value = false;
    selectedIds.clear();
  }

  void toggleItemSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
      if (selectedIds.isEmpty) exitSelectionMode();
    } else {
      selectedIds.add(id);
    }
  }

  void toggleSelectAll(List<NotificationItem> currentList) {
    if (selectedIds.length == currentList.length) {
      selectedIds.clear();
    } else {
      selectedIds.addAll(currentList.map((e) => e.id));
    }
  }

  Future<void> deleteSelectedNotifications() async {
    if (selectedIds.isEmpty) return;
    try {
      final idsToDelete = selectedIds.toList();

      // Cập nhật UI ngay lập tức
      notifications.removeWhere((n) => idsToDelete.contains(n.id));
      _updateUnreadCount();
      exitSelectionMode();

      // Xóa trên DB
      final filterString = '(${idsToDelete.join(',')})';
      await _supabase.from('notifications').delete().filter('id', 'in', filterString);

      Get.snackbar("Thành công", "Đã xóa thông báo");
    } catch (e) {
      _setupRealtimeSubscription(); // Load lại nếu lỗi
      Get.snackbar("Lỗi", "Không thể xóa: $e");
    }
  }

  Future<void> deleteNotification(String id) async {
    // Cập nhật UI ngay lập tức
    notifications.removeWhere((n) => n.id == id);
    _updateUnreadCount();

    try {
      await _supabase.from('notifications').delete().eq('id', id);
    } catch (e) {
      print("Error deleting: $e");
    }
  }

  Future<void> deleteAllNotifications(String filterRole) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Xóa UI theo bộ lọc
    if (filterRole == 'user') {
      notifications.removeWhere((n) => n.metadata?['role'] == 'user' || n.metadata?['role'] == null);
    } else {
      notifications.removeWhere((n) => n.metadata?['role'] == 'seller');
    }
    _updateUnreadCount();
    exitSelectionMode();

    // Lưu ý: Xóa DB cần cẩn thận để không xóa nhầm của role khác
    // Tạm thời hướng dẫn user dùng "Chọn tất cả" -> "Xóa" để an toàn hơn
    // Hoặc implement xóa bulk với logic phức tạp hơn ở backend.
    Get.snackbar("Thông báo", "Vui lòng dùng chức năng 'Chọn tất cả' để xóa an toàn theo danh sách hiển thị.");
  }
}