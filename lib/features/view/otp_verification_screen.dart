// import 'package:get/get.dart';
// import 'package:flutter/material.dart';
// import 'package:ecomerceapp/utils/app_textstyles.dart';
// import 'package:ecomerceapp/controller/auth_controller.dart';
// import 'package:ecomerceapp/features/view/reset_password_screen.dart';
// import 'package:ecomerceapp/features/view/widgets/custom_textfield.dart';

// class OtpVerificationScreen extends StatelessWidget {
//   final String email;
//   final TextEditingController _otpController = TextEditingController();
//   final AuthController _authController = Get.find<AuthController>();

//   OtpVerificationScreen({super.key, required this.email});

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Verify OTP"), centerTitle: true),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Enter the OTP sent to $email",
//               style: AppTextStyles.withColor(
//                 AppTextStyles.bodyLarge,
//                 isDark ? Colors.grey[300]! : Colors.grey[700]!,
//               ),
//             ),
//             const SizedBox(height: 24),
//             CustomTextfield(
//               label: "OTP",
//               prefixIcon: Icons.lock_outline,
//               controller: _otpController,
//             ),
//             const SizedBox(height: 32),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () async {
//                   final otp = _otpController.text.trim();
//                   if (otp.isEmpty) {
//                     Get.snackbar(
//                       "Error",
//                       "Please enter OTP",
//                       backgroundColor: Colors.redAccent,
//                       colorText: Colors.white,
//                     );
//                     return;
//                   }

//                   final isValid = await _authController.verifyOtp(email, otp);
//                   if (isValid) {
//                     Get.to(() => ResetPasswordScreen(email: email));
//                   } else {
//                     Get.snackbar(
//                       "Invalid OTP",
//                       "Please check your OTP and try again",
//                       backgroundColor: Colors.redAccent,
//                       colorText: Colors.white,
//                     );
//                   }
//                 },
//                 child: Text(
//                   "Verify OTP",
//                   style: AppTextStyles.withColor(
//                     AppTextStyles.buttonMedium,
//                     Theme.of(context).primaryColor,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
