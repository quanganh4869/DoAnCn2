import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/features/notification/models/notification_type.dart';

class NotificationController extends GetxController {
  final _supabase = Supabase.instance.client;

  // Danh sách thông báo (Observable)
  var notifications = <NotificationItem>[].obs;
  var unreadCount = 0.obs;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void onInit() {
    super.onInit();

    // --- FIX LỖI WEB: Lắng nghe Auth để đảm bảo Session đã sẵn sàng ---
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      if (session != null) {
        _setupRealtimeSubscription();
      }
    });

    // Check nhanh cho Mobile
    if (_supabase.auth.currentUser != null) {
      _setupRealtimeSubscription();
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  // 1. Lắng nghe Realtime từ Supabase
  void _setupRealtimeSubscription() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Stream bảng notifications của user hiện tại
    _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> data) {

      final parsedList = data.map((e) => NotificationItem.fromSupabaseJson(e)).toList();

      notifications.assignAll(parsedList);
      unreadCount.value = parsedList.where((n) => !n.isRead).length;
    });
  }

  // 2. Hàm Gửi thông báo (Static để gọi ở mọi nơi)
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

  //  Đánh dấu đã đọc tất cả
  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }
    //  Đánh dấu đã đọc từng thông báo
   Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }
}