import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/dashboard_controller.dart';

class DashboardOverviewScreen extends StatelessWidget {
  DashboardOverviewScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceFormatter = NumberFormat("#,###", "vi_VN");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thống kê"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchDashboardData(),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard(context, "Doanh thu", priceFormatter.format(controller.totalRevenue.value), Colors.blue, Icons.attach_money, isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(context, "Đơn hàng", "${controller.totalOrders.value}", Colors.orange, Icons.shopping_bag_outlined, isDark)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard(context, "Sản phẩm bán", "${controller.totalProductsSold.value}", Colors.purple, Icons.inventory_2_outlined, isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    context,
                    "Đánh giá (${controller.totalReviews.value})",
                    controller.averageRating.value == 0 ? "0.0" : controller.averageRating.value.toStringAsFixed(1),
                    Colors.green,
                    Icons.star_border,
                    isDark
                  )),
                ],
              ),

              const SizedBox(height: 30),

              Text("Doanh thu 7 ngày qua", style: AppTextStyles.h3),
              const SizedBox(height: 16),
              _buildChartContainer(
                context, isDark,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: controller.maxRevenueY.value,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            priceFormatter.format(rod.toY),
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= controller.bottomTitles.length) return const SizedBox.shrink();
                            final title = controller.bottomTitles[index] ?? '';
                            return SideTitleWidget(axisSide: meta.axisSide, child: Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[600]))));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
                    barGroups: controller.weeklyRevenueSpots.map((group) {
                      return BarChartGroupData(
                        x: group.x,
                        barRods: group.barRods.map((rod) {
                          return rod.copyWith(
                            backDrawRodData: BackgroundBarChartRodData(show: true, toY: controller.maxRevenueY.value, color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.05)),
                            width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade700], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- MỚI: 3. LINE CHART (ĐIỂM ĐÁNH GIÁ THEO NGÀY) ---
              Text("Xu hướng đánh giá (7 ngày)", style: AppTextStyles.h3),
              const SizedBox(height: 16),
              _buildChartContainer(
                context, isDark,
                child: LineChart(
                  LineChartData(
                    minY: 0, maxY: 5, // Rating từ 0 đến 5
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            return LineTooltipItem(
                              "${barSpot.y.toStringAsFixed(1)} ⭐",
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= controller.ratingBottomTitles.length) return const SizedBox.shrink();
                            final title = controller.ratingBottomTitles[index] ?? '';
                            return SideTitleWidget(axisSide: meta.axisSide, child: Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[600]))));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
                    lineBarsData: [
                      LineChartBarData(
                        spots: controller.weeklyRatingSpots.toList(),
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.green, strokeWidth: 2, strokeColor: Colors.white)),
                        belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 4. PIE CHARTS
              Text("Phân bổ sản phẩm", style: AppTextStyles.h3),
              const SizedBox(height: 16),

              _buildPieChartCard(context, "Bán trong hôm nay", controller.dailyProductSections, "Chưa có đơn hàng hôm nay"),
              const SizedBox(height: 16),
              _buildPieChartCard(context, "Tất cả thời gian", controller.allTimeProductSections, "Chưa có dữ liệu"),

              const SizedBox(height: 50),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildChartContainer(BuildContext context, bool isDark, {required Widget child}) {
    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 15, offset: const Offset(0, 5))
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: child,
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: color.withOpacity(0.1)),
        gradient: LinearGradient(colors: [color.withOpacity(0.05), color.withOpacity(0.15)], begin: Alignment.topLeft, end: Alignment.bottomRight)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(BuildContext context, String title, List<PieChartSectionData> sections, String emptyMsg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Icon(Icons.pie_chart_outline, color: Colors.grey[400], size: 20)]),
          const SizedBox(height: 30),
          SizedBox(height: 200, child: sections.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.data_usage, size: 48, color: Colors.grey[300]), const SizedBox(height: 12), Text(emptyMsg, style: TextStyle(color: Colors.grey[500], fontSize: 14))])) : PieChart(PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 4, borderData: FlBorderData(show: false)))),
        ],
      ),
    );
  }
}