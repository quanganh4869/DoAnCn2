import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ecomerceapp/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/supabase/stats_supabase_service.dart';

// Import AuthController and Model UserProfile

class DashboardController extends GetxController {
  final _supabase = Supabase.instance.client;
  final AuthController _authController = Get.find<AuthController>();

  var isLoading = false.obs;

  // --- TOTAL METRICS ---
  var totalRevenue = 0.0.obs;
  var totalOrders = 0.obs;
  var totalProductsSold = 0.obs;

  // Rating Metrics
  var averageRating = 0.0.obs;
  var totalReviews = 0.obs;

  // --- CHART DATA ---

  // 1. Revenue Bar Chart
  var weeklyRevenueSpots = <BarChartGroupData>[].obs;
  var maxRevenueY = 100.0.obs;
  var bottomTitles = <int, String>{}.obs;

  // 2. Product Pie Charts
  var dailyProductSections = <PieChartSectionData>[].obs;
  var allTimeProductSections = <PieChartSectionData>[].obs;

  // 3. Rating Line Chart (NEW)
  var weeklyRatingSpots = <FlSpot>[].obs;
  var ratingBottomTitles = <int, String>{}.obs; // Can reuse bottomTitles if same days

  // Subscriptions
  RealtimeChannel? _ordersSubscription;
  RealtimeChannel? _itemsSubscription;

  bool _isRealtimeSetup = false;
  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
    _initDefaultChartData();

    debounce(_authController.userProfileRx, (UserProfile? profile) {
      if (profile != null) {
        _handleUserChanged(profile.id);
      }
    }, time: const Duration(milliseconds: 500));

    if (_authController.userProfile != null) {
      _handleUserChanged(_authController.userProfile!.id);
    }
  }

  void _handleUserChanged(String userId) {
    if (_currentUserId == userId && _isRealtimeSetup) return;
    _currentUserId = userId;
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
    List<FlSpot> emptySpots = [];

    for (int i = 0; i < 7; i++) {
      DateTime date = todayNormalized.subtract(Duration(days: 6 - i));
      String dateLabel = DateFormat('dd/MM').format(date);
      bottomTitles[i] = dateLabel;
      ratingBottomTitles[i] = dateLabel;

      // Init Bar Chart (Revenue)
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

      // Init Line Chart (Rating) - Default to 0
      emptySpots.add(FlSpot(i.toDouble(), 0));
    }
    weeklyRevenueSpots.assignAll(emptyBars);
    weeklyRatingSpots.assignAll(emptySpots);
  }

  void _setupRealtimeListeners() {
    _cleanupListeners();

    // Listen for Order changes
    _ordersSubscription = _supabase.channel('public:orders_stats').onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
        fetchDashboardData();
      },
    ).subscribe();

    // Listen for new Items
    _itemsSubscription = _supabase.channel('public:items_stats').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'order_items',
      callback: (payload) {
        fetchDashboardData();
      },
    ).subscribe();

    // Note: Ideally, listen to 'reviews' table too for realtime rating updates.

    _isRealtimeSetup = true;
  }

  Future<void> fetchDashboardData() async {
    if (_currentUserId == null) return;
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      // 1. Get Order Data (Revenue, Orders, Products)
      final allItems = await StatsSupabaseService.getSellerStats(_currentUserId!);

      final completedItems = allItems.where((item) =>
        item.status.toLowerCase() == 'completed'
      ).toList();

      _calculateOverview(completedItems);
      _processWeeklyRevenue(completedItems);
      _processPieCharts(completedItems);

      // 2. Get Review Data (Average Rating & Line Chart)
      final allReviews = await StatsSupabaseService.getSellerReviews(_currentUserId!);

      _calculateShopRating(allReviews);
      _processWeeklyRatings(allReviews);

    } catch (e) {
      print("❌ Dashboard Controller Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- LOGIC: CALCULATE TOTAL RATING ---
  void _calculateShopRating(List<StatReviewItem> reviews) {
    if (reviews.isEmpty) {
      averageRating.value = 0.0;
      totalReviews.value = 0;
      return;
    }

    double totalScore = reviews.fold(0, (sum, item) => sum + item.rating);
    averageRating.value = totalScore / reviews.length;
    totalReviews.value = reviews.length;
  }

  // --- LOGIC: PROCESS RATING LINE CHART ---
  void _processWeeklyRatings(List<StatReviewItem> reviews) {
    final now = DateTime.now();
    final todayNormalized = _normalizeDate(now);

    // Map: Day Index (0-6) -> List of ratings for that day
    Map<int, List<int>> dailyRatingsMap = {};
    for (int i = 0; i < 7; i++) {
      dailyRatingsMap[i] = [];
    }

    for (var review in reviews) {
      final reviewDate = _normalizeDate(review.createdAt);
      final diffDays = todayNormalized.difference(reviewDate).inDays;

      // If review is within last 7 days
      if (diffDays >= 0 && diffDays <= 6) {
        // index 0 = 6 days ago, index 6 = today
        int chartIndex = 6 - diffDays;
        dailyRatingsMap[chartIndex]?.add(review.rating);
      }
    }

    List<FlSpot> spots = [];
    dailyRatingsMap.forEach((index, ratings) {
      double dailyAvg = 0.0;
      if (ratings.isNotEmpty) {
        // Calculate average for that specific day
        dailyAvg = ratings.fold(0, (sum, r) => sum + r) / ratings.length;
      }
      spots.add(FlSpot(index.toDouble(), dailyAvg));
    });

    weeklyRatingSpots.assignAll(spots);
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