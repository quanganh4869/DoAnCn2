import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ecomerceapp/models/user_profile.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/admin_dashboard/controller/admin_controller.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final UserProfile user;
  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final AdminController admincontroller = Get.find<AdminController>();

  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = admincontroller.getUserDeepAnalytics(widget.user.id);
  }

  void _confirmRevokeSeller() {
    Get.defaultDialog(
      title: "Gỡ quyền Seller",
      middleText:
          "Người dùng này sẽ trở thành khách hàng bình thường và mất quyền truy cập Shop. Bạn có chắc chắn?",
      textConfirm: "Gỡ quyền",
      textCancel: "Hủy",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        await admincontroller.revokeSellerRole(widget.user.id);
        Get.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Phân tích người dùng"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading stats: ${snapshot.error}"),
            );
          }

          final data = snapshot.data ?? {};

          final orders = (data['orders'] is List)
              ? (data['orders'] as List).whereType<Order>().toList()
              : <Order>[];

          final behaviors = (data['behaviors'] is List)
              ? (data['behaviors'] as List)
              : [];

          Map<String, double> categoryInterests = {};
          if (data['category_interests'] is Map) {
            final rawMap = data['category_interests'] as Map;
            rawMap.forEach((key, value) {
              if (value is num) {
                categoryInterests[key.toString()] = value.toDouble();
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(context, widget.user, data, isDark),
                const SizedBox(height: 24),
                Text(
                  "Mức độ quan tâm (Dựa theo điểm hành vi)",
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 16),
                _buildCategoryPieChart(context, categoryInterests, isDark),
                const SizedBox(height: 24),
                Text("Hành vi người dùng gần đây", style: AppTextStyles.h3),
                const SizedBox(height: 8),
                _buildBehaviorHistoryList(context, behaviors, isDark),
                const SizedBox(height: 24),
                Text("Đơn hàng gần đây", style: AppTextStyles.h3),
                const SizedBox(height: 10),
                _buildRecentOrders(context, orders, isDark),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    UserProfile user,
    Map<String, dynamic> stats,
    bool isDark,
  ) {
    final isSeller = user.role?.toLowerCase() == 'seller';

    final totalSpent = (stats['total_spent'] as num?)?.toDouble() ?? 0.0;
    final totalOrders = (stats['total_orders'] as num?)?.toInt() ?? 0;
    final interactionCount = (stats['behaviors'] as List?)?.length ?? 0;
    final priceFormatter = NumberFormat("#,###", "vi_VN");

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundImage: user.userImage != null
                    ? NetworkImage(user.userImage!)
                    : null,
                child: user.userImage == null
                    ? const Icon(Icons.person, size: 35)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName ?? "Unknown",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email ?? "",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSeller
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (user.role ?? 'USER').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSeller ? Colors.orange : Colors.blue,
                            ),
                          ),
                        ),

                        if (isSeller) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _confirmRevokeSeller,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.5),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.remove_circle_outline,
                                    size: 10,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Gỡ quyền",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat(
                "Tổng tiền đã mua",
                "${priceFormatter.format(totalSpent)}VND",
                Colors.green,
              ),
              _buildQuickStat("Tổng đơn hàng", "$totalOrders", Colors.blue),
              _buildQuickStat(
                "Hành vi",
                "$interactionCount",
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCategoryPieChart(
    BuildContext context,
    Map<String, double> data,
    bool isDark,
  ) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "No interest data yet",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    List<Color> colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.green,
      Colors.red,
      Colors.teal,
    ];
    int colorIndex = 0;
    double total = data.values.fold(0, (sum, val) => sum + val);

    var sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedEntries.length > 5)
      sortedEntries = sortedEntries.take(5).toList();

    List<PieChartSectionData> sections = sortedEntries.map((entry) {
      final percent = (entry.value / total) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percent.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: _buildBadge(entry.key),
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
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

  // --- WIDGET: LỊCH SỬ TƯƠNG TÁC ---
  Widget _buildBehaviorHistoryList(
    BuildContext context,
    List<dynamic> behaviors,
    bool isDark,
  ) {
    if (behaviors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Text(
          "User has no recent interactions.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: behaviors.length > 10 ? 10 : behaviors.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = behaviors[index];
          final product = item['products'];
          final action = item['action_type'] ?? 'unknown';
          final score = item['score'] ?? 0;
          final date =
              DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();

          String? imageUrl;
          if (product != null && product['images'] != null) {
            if (product['images'] is List &&
                (product['images'] as List).isNotEmpty) {
              imageUrl = (product['images'] as List)[0].toString();
            }
          }

          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 20),
                    ),
            ),
            title: Text(
              product?['name'] ?? 'Unknown Product',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "${_getActionLabel(action)} • ${DateFormat('HH:mm dd/MM').format(date.toLocal())}",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: score > 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${score > 0 ? '+' : ''}$score đ",
                style: TextStyle(
                  color: score > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'view':
        return 'Viewed';
      case 'cart':
        return 'Added to Cart';
      case 'wishlist':
        return 'Liked';
      case 'unwishlist':
        return 'Unliked';
      case 'order':
        return 'Purchased';
      default:
        return action.capitalizeFirst ?? action;
    }
  }

  // --- WIDGET: LỊCH SỬ ĐƠN HÀNG ---
  Widget _buildRecentOrders(
    BuildContext context,
    List<Order> orders,
    bool isDark,
  ) {
    final priceFormatter = NumberFormat("#,###", "vi_VN");
    if (orders.isEmpty) return const Center(child: Text("No orders yet."));
    return Column(
      children: orders
          .take(5)
          .map(
            (order) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.blue),
                ),
                title: Text(
                  "Order #${order.orderNumber}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(order.orderDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${priceFormatter.format(order.totalAmount)} VND",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      order.status.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
