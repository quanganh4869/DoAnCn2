import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ecomerceapp/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/supabase/stats_supabase_service.dart';

// Import AuthController và Model UserProfile

class DashboardController extends GetxController {
  final _supabase = Supabase.instance.client;
  final AuthController _authController = Get.find<AuthController>();

  var isLoading = false.obs;

  // --- TOTAL METRICS ---
  var totalRevenue = 0.0.obs;
  var totalOrders = 0.obs;
  var totalProductsSold = 0.obs;

  // --- CHART DATA ---
  var weeklyRevenueSpots = <BarChartGroupData>[].obs;
  var maxRevenueY = 100.0.obs;
  var bottomTitles = <int, String>{}.obs;

  var dailyProductSections = <PieChartSectionData>[].obs;
  var allTimeProductSections = <PieChartSectionData>[].obs;

  RealtimeChannel? _ordersSubscription;
  RealtimeChannel? _itemsSubscription;

  // Biến cờ để kiểm soát trạng thái setup
  bool _isRealtimeSetup = false;
  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
    _initDefaultChartData();

    // 1. Dùng debounce thay vì ever: Chỉ chạy sau khi profile ngừng thay đổi 500ms
    // Giúp tránh việc gọi API liên tục nếu profile update nhiều lần liên tiếp
    debounce(_authController.userProfileRx, (UserProfile? profile) {
      if (profile != null) {
        _handleUserChanged(profile.id);
      }
    }, time: const Duration(milliseconds: 500));

    // 2. Kiểm tra ban đầu
    if (_authController.userProfile != null) {
      _handleUserChanged(_authController.userProfile!.id);
    }
  }

  // Hàm xử lý tập trung khi User thay đổi hoặc mới vào
  void _handleUserChanged(String userId) {
    // Nếu ID user không đổi và đã setup rồi thì thôi, không chạy lại
    if (_currentUserId == userId && _isRealtimeSetup) return;

    _currentUserId = userId;
    print("📊 Dashboard: User detected ($userId). Init data...");

    fetchDashboardData();
    _setupRealtimeListeners();
  }

  @override
  void onClose() {
    _cleanupListeners();
    super.onClose();
  }

  void _cleanupListeners() {
    if (_ordersSubscription != null) _supabase.removeChannel(_ordersSubscription!);
    if (_itemsSubscription != null) _supabase.removeChannel(_itemsSubscription!);
    _ordersSubscription = null;
    _itemsSubscription = null;
    _isRealtimeSetup = false;
  }

  void _initDefaultChartData() {
    final now = DateTime.now();
    final todayNormalized = _normalizeDate(now);
    List<BarChartGroupData> emptyBars = [];

    for (int i = 0; i < 7; i++) {
      DateTime date = todayNormalized.subtract(Duration(days: 6 - i));
      bottomTitles[i] = DateFormat('dd/MM').format(date);
      emptyBars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: 0,
              color: Colors.blueAccent,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100000,
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
    }
    weeklyRevenueSpots.assignAll(emptyBars);
  }

  void _setupRealtimeListeners() {
    // Hủy kênh cũ trước khi tạo mới
    _cleanupListeners();

    print("🔌 Dashboard: Setting up Realtime Listeners...");

    _ordersSubscription = _supabase.channel('public:orders_stats').onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
        print("♻️ Order status changed -> Refresh dashboard");
        fetchDashboardData();
      },
    ).subscribe();

    _itemsSubscription = _supabase.channel('public:items_stats').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'order_items',
      callback: (payload) {
        print("♻️ New item sold -> Refresh dashboard");
        fetchDashboardData();
      },
    ).subscribe();

    _isRealtimeSetup = true;
  }

  Future<void> fetchDashboardData() async {
    if (_currentUserId == null) return;

    // Nếu đang load thì không gọi chồng thêm
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      // 1. Call RPC
      final allItems = await StatsSupabaseService.getSellerStats(_currentUserId!);

      // 2. Filter COMPLETED
      final completedItems = allItems.where((item) =>
        item.status.toLowerCase() == 'completed'
      ).toList();

      // 3. Process Data
      _calculateOverview(completedItems);
      _processWeeklyRevenue(completedItems);
      _processPieCharts(completedItems);

    } catch (e) {
      print("❌ Dashboard Controller Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  DateTime _normalizeDate(DateTime date) {
    final localDate = date.isUtc ? date.toLocal() : date;
    return DateTime(localDate.year, localDate.month, localDate.day);
  }

  void _calculateOverview(List<StatOrderItem> items) {
    double revenue = 0;
    int products = 0;
    Set<String> uniqueOrders = {};

    for (var item in items) {
      revenue += (item.price * item.quantity);
      products += item.quantity;
      uniqueOrders.add(item.orderNumber);
    }

    totalRevenue.value = revenue;
    totalOrders.value = uniqueOrders.length;
    totalProductsSold.value = products;
  }

  void _processWeeklyRevenue(List<StatOrderItem> items) {
    final now = DateTime.now();
    final todayNormalized = _normalizeDate(now);

    Map<int, double> revenueMap = {};
    for (int i = 0; i < 7; i++) {
      revenueMap[i] = 0.0;
      DateTime date = todayNormalized.subtract(Duration(days: 6 - i));
      bottomTitles[i] = DateFormat('dd/MM').format(date);
    }

    for (var item in items) {
      final itemDateNormalized = _normalizeDate(item.orderDate);
      final diffDays = todayNormalized.difference(itemDateNormalized).inDays;

      if (diffDays >= 0 && diffDays <= 6) {
        double itemTotal = item.price * item.quantity;
        int chartIndex = 6 - diffDays;
        revenueMap[chartIndex] = (revenueMap[chartIndex] ?? 0) + itemTotal;
      }
    }

    double maxVal = 0;
    List<BarChartGroupData> bars = [];

    revenueMap.forEach((index, value) {
      if (value > maxVal) maxVal = value;
      bars.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              color: Colors.blueAccent,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxVal * 1.2 == 0 ? 100000 : maxVal * 1.2,
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
    });

    maxRevenueY.value = maxVal * 1.2;
    if (maxRevenueY.value == 0) maxRevenueY.value = 100000;
    weeklyRevenueSpots.assignAll(bars);
  }

  void _processPieCharts(List<StatOrderItem> items) {
    final now = DateTime.now();
    final todayNormalized = _normalizeDate(now);

    Map<String, int> dailyCounts = {};
    Map<String, int> allTimeCounts = {};

    for (var item in items) {
      final itemDateNormalized = _normalizeDate(item.orderDate);
      bool isToday = itemDateNormalized.isAtSameMomentAs(todayNormalized);

      allTimeCounts[item.productName] = (allTimeCounts[item.productName] ?? 0) + item.quantity;
      if (isToday) {
        dailyCounts[item.productName] = (dailyCounts[item.productName] ?? 0) + item.quantity;
      }
    }

    dailyProductSections.assignAll(_generatePieSections(dailyCounts));
    allTimeProductSections.assignAll(_generatePieSections(allTimeCounts));
  }

  List<PieChartSectionData> _generatePieSections(Map<String, int> data) {
    if (data.isEmpty) return [];

    List<Color> colors = [Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.red, Colors.teal];
    int colorIndex = 0;
    int total = data.values.fold(0, (sum, val) => sum + val);

    return data.entries.map((entry) {
      final percent = (entry.value / total) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percent.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        badgeWidget: _buildBadge(entry.key),
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Colors.black),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}