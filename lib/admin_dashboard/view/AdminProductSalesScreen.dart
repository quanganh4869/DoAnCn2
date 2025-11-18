import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/admin_dashboard/controller/admin_controller.dart';
// import 'package:fl_chart/fl_chart.dart'; // Cần thư viện biểu đồ

class AdminProductSalesScreen extends StatelessWidget {
  AdminProductSalesScreen({super.key});
  final AdminController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    // Tải dữ liệu biểu đồ
    controller.fetchDailySalesData(); 
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BIỂU ĐỒ MUA HÀNG TRONG NGÀY
          const Text("Daily User Purchases (Last 7 Days)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: Obx(() => Center(
              child: controller.salesData.isEmpty && !controller.isLoading.value
                  ? const Text("No sales data available.")
                  : const Text("Placeholder for Line Chart (Need fl_chart or similar)"),
            )),
          ),

          const SizedBox(height: 30),
          const Divider(),

          // LỌC SẢN PHẨM BÁN TRONG NGÀY
          const Text("Top Selling Products (Today)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Nút Chọn Ngày (MOCK)
          ElevatedButton.icon(
            onPressed: () {
              // Logic chọn ngày và gọi controller.fetchTopSellingProducts()
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(DateFormat('MMM dd, yyyy').format(DateTime.now())),
          ),
          
          const SizedBox(height: 16),

          // Danh sách Sản phẩm bán chạy (Placeholder)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) => const ListTile(
              title: Text("Product Name [MOCK]"),
              subtitle: Text("Quantity Sold: 50"),
              trailing: Text("\$1,200"),
            ),
          ),
        ],
      ),
    );
  }
}