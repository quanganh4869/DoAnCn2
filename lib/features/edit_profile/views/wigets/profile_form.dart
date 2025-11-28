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
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (_authController.userProfile != null) {
      final profile = _authController.userProfile!;
      _fullNameController.text = profile.fullName ?? '';
      _phoneController.text = profile.phone ?? '';
    } else {
      _fullNameController.text = _authController.currentUser?.email ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final bool success = await _authController.updateProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (success) {
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final userProfile = _authController.userProfile;
      if (userProfile == null) {
        return const Center(child: CircularProgressIndicator());
      }
      _fullNameController.text = userProfile.fullName ?? _fullNameController.text;
      _phoneController.text = userProfile.phone ?? _phoneController.text;

      return Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _buildTextfieldContainer(
                context,
                isDark,
                CustomTextfield(
                  label: "Tên người dùng",
                  prefixIcon: Icons.person_outline,
                  controller: _fullNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên đầy đủ.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
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
              _buildTextfieldContainer(
                context,
                isDark,
                CustomTextfield(
                  label: "SĐT",
                  prefixIcon: Icons.phone_outlined,
                  controller: _phoneController,
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Lưu thay đổi",
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