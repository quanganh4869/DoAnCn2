import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/features/myorders/model/order.dart';
import 'package:ecomerceapp/admin_dashboard/controller/admin_controller.dart';

class AdminHomePage extends StatelessWidget {
  AdminHomePage({super.key});
  final AdminController controller = Get.find<AdminController>();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchDashboardStats();
    });
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => controller.fetchDashboardStats(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tổng quan hệ thống",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Obx(
                () => GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  childAspectRatio: 1.5,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      "tổng doanh thu",
                      currencyFormat.format(
                        controller.totalPlatformRevenue.value,
                      ),
                      Icons.attach_money,
                      Colors.blue,
                      isDark,
                    ),
                    _buildStatCard(
                      "Tổng số người dùng",
                      "${controller.totalUsersCount.value}",
                      Icons.people_alt_rounded,
                      Colors.purple,
                      isDark,
                    ),
                    _buildStatCard(
                      "Tổng số đơn hàng",
                      "${controller.totalOrdersCount.value}",
                      Icons.shopping_bag_rounded,
                      Colors.orange,
                      isDark,
                    ),
                    _buildStatCard(
                      "Yêu cầu Seller",
                      "${controller.pendingRequests.length}",
                      Icons.storefront_rounded,
                      Colors.redAccent,
                      isDark,
                      isAlert: controller.pendingRequests.isNotEmpty,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Text(
                "Xu hướng doanh thu (7 ngày gần đây)",
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 16),
              _buildRevenueChartContainer(context, isDark),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Các đơn hàng gần đây", style: AppTextStyles.h3),
                  TextButton(onPressed: () {}, child: const Text("Xem tất cả")),
                ],
              ),
              const SizedBox(height: 10),
              _buildRecentOrdersList(context, isDark),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark, {
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isAlert
            ? Border.all(color: Colors.red, width: 1.5)
            : Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (isAlert)
                const Icon(Icons.circle, color: Colors.red, size: 10),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChartContainer(BuildContext context, bool isDark) {
    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        List<FlSpot> spots = [];
        for (int i = 0; i < controller.monthlyRevenue.length; i++) {
          spots.add(FlSpot(i.toDouble(), controller.monthlyRevenue[i]));
        }

        double maxY = 0;
        for (var val in controller.monthlyRevenue) {
          if (val > maxY) maxY = val;
        }
        if (maxY == 0) maxY = 100;

        return LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY * 1.2,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "D${value.toInt() + 1}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.1),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.3),
                      Colors.blue.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Widget các đơn hàng gần đây
  Widget _buildRecentOrdersList(BuildContext context, bool isDark) {
    final priceFormatter = NumberFormat("#,###", "vi_VN");

    return Obx(() {
      if (controller.recentOrders.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            "No recent transactions found.",
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.recentOrders.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
          itemBuilder: (context, index) {
            final order = controller.recentOrders[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.grey[100],
                child: const Icon(Icons.receipt_long, color: Colors.black54),
              ),
              title: Text(
                order.orderNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                DateFormat('dd/MM HH:mm').format(order.orderDate),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${priceFormatter.format(order.totalAmount)}VND",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(order.status),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.completed:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
