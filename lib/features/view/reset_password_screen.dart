import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/features/view/signin_screen.dart';
import 'package:ecomerceapp/features/view/signup_screen.dart';
import 'package:ecomerceapp/features/view/widgets/custom_textfield.dart';

class ResetPasswordScreen extends StatelessWidget {
  final String email;
  final TextEditingController _passwordController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();

  ResetPasswordScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _emailController = TextEditingController(
      text: email ?? "",
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Enter your new password for:",
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // 🔹 Input password
            CustomTextfield(
              label: "New Password",
              prefixIcon: Icons.lock_clock_outlined,
              keyboardType: TextInputType.visiblePassword,
              isPassword: true,
              controller: _passwordController,
            ),
            const SizedBox(height: 32),

            // 🔹 Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final password = _passwordController.text.trim();

                  if (password.isEmpty) {
                    Get.snackbar(
                      "Missing Password",
                      "Please enter your new password",
                      backgroundColor: Colors.redAccent,
                      colorText: Colors.white,
                    );
                    return;
                  }
                  if (password.length < 6) {
                    Get.snackbar(
                      "Weak Password",
                      "Password must be at least 6 characters",
                      backgroundColor: Colors.redAccent,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  try {
                    await _authController.updatePassword(password);

                    Get.offAll(() => SigninScreen(email: email));
                    Get.snackbar(
                      "Success",
                      "Password reset successfully",
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } catch (e) {
                    Get.snackbar(
                      "Failed",
                      e.toString(),
                      backgroundColor: Colors.redAccent,
                      colorText: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Update Password",
                  style: AppTextStyles.withColor(
                    AppTextStyles.buttonMedium,
                    Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
