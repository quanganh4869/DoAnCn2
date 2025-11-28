import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/user_profile.dart';
import 'package:ecomerceapp/admin_dashboard/controller/admin_controller.dart';

class UserDetailRequestScreen extends StatelessWidget {
  final UserProfile request;

  const UserDetailRequestScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết Yêu cầu"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Thông tin Người đăng ký"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(
                      request.userImage ?? "https://cdn-icons-png.flaticon.com/512/1995/1995574.png"
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.fullName ?? "Chưa cập nhật tên",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text("Email cá nhân: ${request.email ?? 'N/A'}"),
                        Text("SĐT cá nhân: ${request.phone ?? 'N/A'}"),
                        const SizedBox(height: 4),
                        Text("ID: ${request.id}", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle("Thông tin Shop đăng ký"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.store, "Tên Shop", request.storeName ?? "Chưa đặt tên"),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.email_outlined, "Email Kinh Doanh", request.businessEmail ?? "Chưa cập nhật"),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.phone_in_talk, "SĐT Shop", request.shopPhone ?? "Chưa cập nhật"),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.location_on_outlined, "Địa chỉ kho", request.shopAddress ?? "Chưa cập nhật"),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.description_outlined, "Mô tả", request.storeDescription ?? "Không có mô tả", isMultiLine: true),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _confirmAction(context, controller, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("TỪ CHỐI", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _confirmAction(context, controller, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Text("CHẤP NHẬN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isMultiLine = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                maxLines: isMultiLine ? 10 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmAction(BuildContext context, AdminController controller, bool isApprove) {
    Get.defaultDialog(
      title: isApprove ? "Xác nhận Duyệt" : "Xác nhận Từ chối",
      middleText: isApprove
          ? "Bạn có chắc muốn cấp quyền bán hàng cho '${request.storeName}'?"
          : "Bạn có chắc muốn từ chối yêu cầu này?",
      textConfirm: "Đồng ý",
      textCancel: "Hủy",
      confirmTextColor: Colors.white,
      buttonColor: isApprove ? Colors.green : Colors.red,
      onConfirm: () async {
        Get.back(); // Đóng dialog
        Get.back(); // Đóng màn hình chi tiết luôn

        // Gọi controller xử lý
        await controller.approveOrRejectSeller(request.id, isApprove);
      }
    );
  }
}