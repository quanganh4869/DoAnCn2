import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';

class TermOfService extends StatelessWidget {
  const TermOfService({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          "Privacy Policy",
          style: AppTextStyles.withColor(
            AppTextStyles.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: AppTextStyles.withColor(
                AppTextStyles.h3,
                isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Welcome to EcomerceApp. By using our app you agree to these Terms of Service. '
              'Please read them carefully before making purchases or using our services.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '1. Using the Service',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You agree to provide accurate information, to comply with applicable laws, '
              'and not to use the service for illegal activities. Accounts are for personal use unless '
              'explicitly stated otherwise.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '2. Orders & Payments',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All orders are subject to acceptance and availability. Prices may change and we may '
              'limit quantities. Payment processing is handled by secure third-party providers.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '3. Returns & Refunds',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Our return policy is available in the Returns section. Refunds are issued after '
              'we inspect returned items and confirm they meet the return criteria.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '4. Intellectual Property',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All content, trademarks, and data on this app are the property of EcomerceApp or its licensors. '
              'You may not reproduce or distribute content without permission.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '5. Limitation of Liability',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'To the fullest extent permitted by law, EcomerceApp is not liable for indirect, '
              'special, or consequential damages arising from the use of the app.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '6. Changes to Terms',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'We may update these terms occasionally. Continued use after changes constitutes acceptance. '
              'If a change is material, we will try to provide notice in advance.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Accept & Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
