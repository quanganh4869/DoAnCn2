import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/seller_dasboard/controller/seller_controller.dart';

class SellerRegistrationScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  final SellerController controller = Get.put(SellerController());

  SellerRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Seller Registration", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Start your business journey!", style: AppTextStyles.h2),
              const SizedBox(height: 10),
              Text("Fill in the details below to request admin approval.", style: AppTextStyles.bodyMedium),
              const SizedBox(height: 30),
              
              _buildTextField(context, "Shop Name", _shopNameController, isRequired: true),
              const SizedBox(height: 16),
              _buildTextField(context, "Business Email", _emailController, isRequired: true, isEmail: true),
              const SizedBox(height: 16),
              _buildTextField(context, "Phone Number", _phoneController, isRequired: true, isPhone: true),
              const SizedBox(height: 16),
              _buildTextField(context, "Shop Description", _descController, maxLines: 4),
              
              const SizedBox(height: 40),
              
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      bool success = await controller.registerSeller(
                        _shopNameController.text,
                        _descController.text,
                        _emailController.text,
                        _phoneController.text,
                      );
                      if (success) {
                        Get.back();
                        Get.snackbar("Success", "Application submitted! Waiting for approval.", backgroundColor: Colors.green, colorText: Colors.white);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: controller.isLoading.value 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Submit Application", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, TextEditingController controller, {bool isRequired = false, int maxLines = 1, bool isEmail = false, bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) return "$label is required";
        if (isEmail && value != null && !value.contains("@")) return "Invalid email";
        return null;
      },
    );
  }
}