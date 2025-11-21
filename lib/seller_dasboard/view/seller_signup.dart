import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/seller_dasboard/controller/seller_controller.dart';

class SellerSignup extends StatefulWidget {
  const SellerSignup({super.key});

  @override
  State<SellerSignup> createState() => _SellerSignupState();
}

class _SellerSignupState extends State<SellerSignup> {
  final SellerController controller = Get.find<SellerController>();
  final AuthController authController = Get.find<AuthController>();

  final _formKey = GlobalKey<FormState>();

  // Controllers cho 5 trường thông tin cần thiết
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Tự động điền thông tin có sẵn từ User Profile (nếu có) để tiện cho người dùng
    final user = authController.userProfile;
    if (user != null) {
      _emailController.text = user.email ?? "";
      _phoneController.text = user.phone ?? "";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor = isDark ? Colors.grey[800] : Colors.grey[50];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Đăng ký Mở Shop",
          style: AppTextStyles.h3.copyWith(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => navigator?.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Header minh họa
              Center(
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    // Sử dụng withValues thay cho withOpacity (đã deprecated ở Flutter mới)
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.store_rounded, size: 50, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                "Thông tin cơ bản",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Text(
                "Điền đầy đủ thông tin để chúng tôi liên hệ và xác thực cửa hàng của bạn.",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),

              // 1. Tên Shop
              _buildLabel("Tên cửa hàng"),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration("Nhập tên shop của bạn", Icons.store, inputFillColor),
                validator: (value) => (value == null || value.length < 3) ? "Tên shop phải từ 3 ký tự" : null,
              ),
              const SizedBox(height: 16),

              // 2. Email Kinh Doanh
              _buildLabel("Email liên hệ"),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration("Email kinh doanh", Icons.email, inputFillColor),
                validator: (value) => (value == null || !value.contains('@')) ? "Email không hợp lệ" : null,
              ),
              const SizedBox(height: 16),

              // 3. Số điện thoại Shop
              _buildLabel("Số điện thoại Shop"),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration("SĐT liên hệ đơn hàng", Icons.phone, inputFillColor),
                validator: (value) => (value == null || value.length < 9) ? "SĐT không hợp lệ" : null,
              ),
              const SizedBox(height: 16),

              // 4. Địa chỉ kho/shop
              _buildLabel("Địa chỉ kho/cửa hàng"),
              TextFormField(
                controller: _addressController,
                decoration: _buildInputDecoration("Địa chỉ lấy hàng", Icons.location_on, inputFillColor),
                validator: (value) => (value == null || value.isEmpty) ? "Vui lòng nhập địa chỉ" : null,
              ),
              const SizedBox(height: 16),

              // 5. Mô tả
              _buildLabel("Mô tả cửa hàng"),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: _buildInputDecoration("Giới thiệu ngắn về sản phẩm...", Icons.description, inputFillColor),
                validator: (value) => (value == null || value.isEmpty) ? "Hãy viết mô tả ngắn" : null,
              ),

              const SizedBox(height: 32),

              // Nút Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Đăng Ký Ngay",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                )),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Gọi hàm registerSeller trong controller với đầy đủ 5 tham số
      final success = await controller.registerSeller(
        storeName: _nameController.text.trim(),
        businessEmail: _emailController.text.trim(),
        shopPhone: _phoneController.text.trim(),
        shopAddress: _addressController.text.trim(),
        description: _descController.text.trim(),
      );

      if (success) {
        Get.back(); // Quay lại màn hình Account sau khi thành công
      }
    }
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, Color? fillColor) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
    );
  }
}