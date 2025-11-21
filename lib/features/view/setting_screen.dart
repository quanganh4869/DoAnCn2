import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/theme_controller.dart';
import 'package:ecomerceapp/features/view/privacy_policy.dart';
import 'package:ecomerceapp/features/view/term_of_service.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

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
          "Settings",
          style: AppTextStyles.withColor(
            AppTextStyles.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(context, "Appearance", [_buildThemeToggle(context)]),
            _buildSection(context, "Notifications", [
              _buildSwitchTile(
                context,
                "Push Notifications",
                "Receive push notifications",
                true,
              ),
              _buildSwitchTile(
                context,
                "Email Notifications",
                "Receive email notifications",
                false,
              ),
            ]),
            _buildSection(context, "Privacy", [
              _buildNavigationTile(
                context,
                "Privacy Policy",
                "View our privacy policy",
                Icons.privacy_tip_outlined,
                onTap: () => Get.to(() => const PrivacyPolicy()),
              ),
              _buildNavigationTile(
                context,
                "Terms of Service",
                "Read our terms of service",
                Icons.description_outlined,
                onTap: () => Get.to(() => const TermOfService()),
              ),
            ]),
            _buildSection(context, "About", [
              _buildNavigationTile(
                context,
                "App Version",
                "V3.6",
                Icons.info_outline,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // SECTION WRAPPER
  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              title,
              style: AppTextStyles.withColor(
                AppTextStyles.h3,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // THEME TOGGLE
  Widget _buildThemeToggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GetBuilder<ThemeController>(
      builder: (controller) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(
            controller.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).primaryColor,
          ),
          title: Text(
            "Dark Mode",
            style: AppTextStyles.withColor(
              AppTextStyles.bodyMedium,
              Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          trailing: Switch(
            value: controller.isDarkMode,
            onChanged: (value) {
              controller.toggleTheme();
            },
            activeColor: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  // SWITCH TILE
  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    bool initialValue,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: AppTextStyles.withColor(
            AppTextStyles.bodyMedium,
            Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.withColor(
            AppTextStyles.bodySmall,
            isDark ? Colors.grey[400]! : Colors.grey[600]!,
          ),
        ),
        trailing: Switch.adaptive(
          value: initialValue,
          onChanged: (value) {},
          activeColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  // NAVIGATION TILE (đã fix cú pháp - thêm onTap)
  Widget _buildNavigationTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(
          title,
          style: AppTextStyles.withColor(
            AppTextStyles.bodyMedium,
            Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.withColor(
            AppTextStyles.bodySmall,
            isDark ? Colors.grey[400]! : Colors.grey[600]!,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        onTap: onTap,
      ),
    );
  }
}
