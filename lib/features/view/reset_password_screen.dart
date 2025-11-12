import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/features/view/widgets/custom_textfield.dart';

class ResetPasswordScreen extends StatelessWidget {
  final String email;
  final TextEditingController _passwordController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();

  ResetPasswordScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CustomTextfield(
              label: "New Password",
              prefixIcon: Icons.lock_outline,
              controller: _passwordController,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final password = _passwordController.text.trim();
                  if (password.length < 6) {
                    Get.snackbar("Weak Password", "At least 6 characters",
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white);
                    return;
                  }

                  try {
                    await _authController.updatePassword(email,password);
                    Get.offAllNamed("/login");
                    Get.snackbar("Success", "Password reset successfully",
                        backgroundColor: Colors.green,
                        colorText: Colors.white);
                  } catch (e) {
                    Get.snackbar("Failed", e.toString(),
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white);
                  }
                },
                child: Text(
                  "Confirm",
                  style: AppTextStyles.withColor(
                      AppTextStyles.buttonMedium, Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
