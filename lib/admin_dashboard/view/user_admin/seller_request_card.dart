import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/admin_dashboard/controller/admin_controller.dart';
import 'package:ecomerceapp/admin_dashboard/view/user_admin/userdetail_request_screen.dart';

class SellerRequestsCard extends StatelessWidget {
  const SellerRequestsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Obx(() {
      // 1. Trạng thái Loading
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // 2. Trạng thái Trống
      if (controller.pendingRequests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "Không có yêu cầu nào chờ duyệt",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        );
      }

      // 3. Danh sách yêu cầu
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.pendingRequests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          // request ở đây chính là UserProfile
          final request = controller.pendingRequests[index];

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias, // Để hiệu ứng gợn sóng không bị tràn
            child: InkWell(
              // === SỰ KIỆN BẤM VÀO THẺ -> XEM CHI TIẾT ===
              onTap: () {
                Get.to(() => UserDetailRequestScreen(request: request));
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Avatar & Tên Shop
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            request.userImage ?? "https://cdn-icons-png.flaticon.com/512/1995/1995574.png"
                          ),
                          radius: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.storeName ?? "Chưa đặt tên Shop",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Chủ shop: ${request.fullName ?? 'Ẩn danh'}",
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                          ),
                          child: const Text(
                            "Chờ duyệt",
                            style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Thông tin tóm tắt
                    _infoRow(Icons.email, "Email KD:", request.businessEmail ?? request.email ?? "N/A"),
                    const SizedBox(height: 8),
                    _infoRow(Icons.phone, "SĐT Shop:", request.shopPhone ?? request.phone ?? "N/A"),
                    const SizedBox(height: 8),
                    _infoRow(Icons.location_on, "Địa chỉ:", request.shopAddress ?? "N/A"),
                    const SizedBox(height: 8),
                    // Giới hạn mô tả 1 dòng
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.description, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text("Mô tả: ", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Expanded(
                          child: Text(
                            request.storeDescription ?? "Không có mô tả",
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Nút hành động nhanh
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmAction(
                              context,
                              controller,
                              request.id, // ID User
                              request.storeName ?? "Shop",
                              false // Từ chối
                            ),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text("Từ chối", style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _confirmAction(
                              context,
                              controller,
                              request.id, // ID User
                              request.storeName ?? "Shop",
                              true // Duyệt
                            ),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text("Duyệt Shop", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  // Widget hiển thị dòng thông tin nhỏ
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text("$label ", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  // Dialog xác nhận
  void _confirmAction(BuildContext context, AdminController controller, String userId, String shopName, bool isApprove) {
    Get.defaultDialog(
      title: isApprove ? "Duyệt Shop?" : "Từ chối Shop?",
      middleText: isApprove
          ? "Bạn có chắc muốn cấp quyền bán hàng cho '$shopName'?"
          : "Bạn có chắc muốn từ chối yêu cầu của '$shopName'?",
      textConfirm: isApprove ? "Duyệt Ngay" : "Từ Chối",
      textCancel: "Hủy",
      confirmTextColor: Colors.white,
      buttonColor: isApprove ? Colors.green : Colors.red,
      onConfirm: () {
        Get.back(); // Đóng dialog
        // Gọi hàm xử lý trong Controller
        controller.approveOrRejectSeller(userId, isApprove);
      }
    );
  }
}