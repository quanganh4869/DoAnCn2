import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/features/notification/view/notification_utils.dart';
import 'package:ecomerceapp/features/notification/models/notification_type.dart';
import 'package:ecomerceapp/features/notification/view/notification_detail_screen.dart';
import 'package:ecomerceapp/features/notification/controller/notification_controller.dart';

class NotificationScreen extends StatelessWidget {
  NotificationScreen({super.key});

  final NotificationController controller = Get.put(NotificationController());
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
        ),
        title: Obx(() => Text(
          "Thông báo của ${authController.userName}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
        )),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => controller.markAllAsRead(),
            child: Text(
              "Mark all as read",
              style: AppTextStyles.withColor(
                AppTextStyles.bodyMedium,
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text("No notifications yet", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) =>
              _buildNotificationCard(context, controller.notifications[index]),
        );
      }),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationItem notification,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        // Darker background if unread to make it stand out
        color: notification.isRead
            ? Theme.of(context).cardColor
            : Theme.of(context).primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
        // Add a border if unread
        border: !notification.isRead
            ? Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),

        // --- ON TAP EVENT ---
        onTap: () {
          // 1. Mark as read immediately
          if (!notification.isRead) {
            controller.markAsRead(notification.id);
          }
          // 2. Navigate to detail screen
          Get.to(() => NotificationDetailScreen(notification: notification));
        },

        leading: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: NotificationUtils.getIconBackgroundColor(
              context,
              notification.type,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            NotificationUtils.getNotificationIcon(notification.type),
            color: NotificationUtils.getIconColor(context, notification.type),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 16,
            // Bold if unread
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.withColor(
                AppTextStyles.bodySmall,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "${notification.date.hour}:${notification.date.minute.toString().padLeft(2, '0')} ${notification.date.day}/${notification.date.month}",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                // Blue dot for unread status
                if (!notification.isRead) ...[
                  const Spacer(),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  )
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}