import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';

class DashboardOverviewScreen extends StatelessWidget {
  const DashboardOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Thống kê nhanh (Cards)
          Row(
            children: [
              Expanded(child: _buildStatCard(context, "Total Sales", "\$12,500", Colors.blue, Icons.attach_money)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(context, "Total Orders", "154", Colors.orange, Icons.shopping_cart)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(context, "Products", "45", Colors.purple, Icons.inventory)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(context, "Customers", "320", Colors.green, Icons.people)),
            ],
          ),

          const SizedBox(height: 30),

          // 2. Biểu đồ doanh thu (Bar Chart)
          Text("Weekly Revenue", style: AppTextStyles.h3),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                 BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12);
                        Widget text;
                        switch (value.toInt()) {
                          case 0: text = const Text('Mon', style: style); break;
                          case 1: text = const Text('Tue', style: style); break;
                          case 2: text = const Text('Wed', style: style); break;
                          case 3: text = const Text('Thu', style: style); break;
                          case 4: text = const Text('Fri', style: style); break;
                          case 5: text = const Text('Sat', style: style); break;
                          case 6: text = const Text('Sun', style: style); break;
                          default: text = const Text('', style: style);
                        }
                        return SideTitleWidget(axisSide: meta.axisSide, child: text);
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  _makeBarGroup(0, 5, Colors.blue),
                  _makeBarGroup(1, 10, Colors.blue),
                  _makeBarGroup(2, 14, Colors.blue),
                  _makeBarGroup(3, 18, Colors.orange), // Ngày cao điểm
                  _makeBarGroup(4, 13, Colors.blue),
                  _makeBarGroup(5, 10, Colors.blue),
                  _makeBarGroup(6, 15, Colors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: color.withOpacity(0.8), fontSize: 14)),
        ],
      ),
    );
  }
}