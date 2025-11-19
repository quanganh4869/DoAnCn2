import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/features/view/widgets/custom_textfield.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  // 1. Khai báo TextEditingController
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // 2. Inject AuthController
  final AuthController _authController = Get.find<AuthController>();
  
  // Khai báo form key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // 3. Khởi tạo giá trị ban đầu khi widget được tạo
    // Dùng addListener để cập nhật controller khi profile thay đổi lần đầu hoặc sau đó
    _loadInitialData();
  }

  void _loadInitialData() {
    // Chỉ khởi tạo khi userProfile đã có giá trị
    if (_authController.userProfile != null) {
      final profile = _authController.userProfile!;
      _fullNameController.text = profile.fullName ?? '';
      _phoneController.text = profile.phone ?? '';
    } else {
      // Đảm bảo không bị null khi chưa load kịp
      _fullNameController.text = _authController.currentUser?.email ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  // Hàm xử lý khi nhấn nút Save
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final bool success = await _authController.updateProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        // Có thể thêm gender, userImage... nếu cần
      );
      
      if (success) {
        // Có thể navigate back hoặc làm gì đó sau khi thành công
        // Get.back(); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Sử dụng Obx để tự động rebuild khi _userProfile thay đổi
    return Obx(() {
      final userProfile = _authController.userProfile;
      
      // Nếu profile chưa load (null), hiển thị Loading hoặc Placeholder
      if (userProfile == null) {
        return const Center(child: CircularProgressIndicator());
      }
      
      // Khởi tạo lại giá trị (có thể dùng FutureBuilder hoặc cách khác tối ưu hơn, 
      // nhưng với Obx và GetX thì cách này cũng hoạt động nếu logic load rõ ràng)
      // Tải lại giá trị mỗi lần Obx rebuild
      _fullNameController.text = userProfile.fullName ?? _fullNameController.text;
      _phoneController.text = userProfile.phone ?? _phoneController.text;

      return Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // --- FULL NAME ---
              _buildTextfieldContainer(
                context,
                isDark,
                CustomTextfield(
                  label: "Full Name",
                  prefixIcon: Icons.person_outline,
                  controller: _fullNameController, // Dùng controller
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên đầy đủ.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // --- EMAIL (KHÔNG THỂ SỬA) ---
              _buildTextfieldContainer(
                context,
                isDark,
                CustomTextfield(
                  label: "Email",
                  prefixIcon: Icons.email_outlined,
                  initialValue: userProfile.email,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true,
                  textColor: Colors.grey, 
                ),
              ),
              const SizedBox(height: 16),
              
              // --- PHONE NUMBER ---
              _buildTextfieldContainer(
                context,
                isDark,
                CustomTextfield(
                  label: "Phone Number",
                  prefixIcon: Icons.phone_outlined,
                  controller: _phoneController, // Dùng controller
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số điện thoại.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // --- BUTTON SAVE CHANGES ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges, // Gọi hàm Save Changes
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Save Changes",
                    style: AppTextStyles.withColor(
                      AppTextStyles.h3,
                      isDark ? Colors.white : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
  
  // Hàm trợ giúp để giảm trùng lặp code cho Container Decoration
  Widget _buildTextfieldContainer(BuildContext context, bool isDark, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}