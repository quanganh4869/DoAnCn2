import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/features/notification/view/notification_utils.dart';
import 'package:ecomerceapp/features/notification/models/notification_type.dart';
import 'package:ecomerceapp/features/notification/view/notification_detail_screen.dart';
import 'package:ecomerceapp/features/notification/controller/notification_controller.dart';

class NotificationScreen extends StatelessWidget {
  final String filterRole;

  NotificationScreen({super.key, this.filterRole = 'user'});

  final NotificationController controller = Get.put(NotificationController());

  List<NotificationItem> _getFilteredList() {
    return controller.notifications.where((n) {
      final role = n.metadata?['role'];
      if (filterRole == 'seller') {
        return role == 'seller';
      } else {
        return role == 'user' || role == null;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        if (controller.isSelectionMode.value) {
          controller.exitSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Obx(() {
            final isSelection = controller.isSelectionMode.value;
            final selectedCount = controller.selectedIds.length;
            String title = filterRole == 'seller'
                ? "Seller Notifications"
                : "Notifications";
            if (isSelection) title = "$selectedCount selected";

            final currentList = _getFilteredList();

            return AppBar(
              leading: isSelection
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => controller.exitSelectionMode(),
                    )
                  : IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              centerTitle: true,
              actions: [
                if (isSelection) ...[
                  IconButton(
                    icon: Icon(
                      selectedCount == currentList.length &&
                              currentList.isNotEmpty
                          ? Icons.select_all
                          : Icons.deselect,
                      color: Theme.of(context).primaryColor,
                    ),
                    tooltip: "Chọn tất cả",
                    onPressed: () {
                      controller.toggleSelectAll(currentList);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () =>
                        _showDeleteConfirmDialog(context, isDeleteAll: false),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () => controller.markAllAsRead(),
                    child: Text(
                      "Đánh dấu đã đọc",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.red[400],
                    ),
                    tooltip: "Xóa tất cả",
                    onPressed: () =>
                        _showDeleteConfirmDialog(context, isDeleteAll: true),
                  ),
                ],
              ],
            );
          }),
        ),
        body: Obx(() {
          final filteredList = _getFilteredList();

          if (filteredList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Không có thông báo",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final notification = filteredList[index];

              if (controller.isSelectionMode.value) {
                return _buildNotificationCard(context, notification);
              }

              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.horizontal,
                onDismissed: (direction) {
                  controller.deleteNotification(notification.id);
                },
                background: _buildSwipeBackground(Alignment.centerLeft),
                secondaryBackground: _buildSwipeBackground(
                  Alignment.centerRight,
                ),
                child: _buildNotificationCard(context, notification),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildSwipeBackground(Alignment alignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context, {
    required bool isDeleteAll,
  }) {
    final count = isDeleteAll
        ? _getFilteredList().length
        : controller.selectedIds.length;

    if (count == 0) return;

    Get.dialog(
      AlertDialog(
        title: Text(isDeleteAll ? "Xóa thông báo ?" : "Xóa $count ?"),
        content: Text(
          isDeleteAll
              ? "Bạn có chắc xóa tất cả thông báo"
              : "Bạn có chắc xóa thông báo đã chọn?",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              if (isDeleteAll) {
                controller.deleteAllNotifications(filterRole);
              } else {
                controller.deleteSelectedNotifications();
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationItem notification,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isSelectionMode = controller.isSelectionMode.value;
      final isSelected = controller.selectedIds.contains(notification.id);

      return GestureDetector(
        onLongPress: () {
          if (!isSelectionMode) {
            controller.enterSelectionMode(notification.id);
          }
        },
        onTap: () {
          if (isSelectionMode) {
            controller.toggleItemSelection(notification.id);
          } else {
            if (!notification.isRead) controller.markAsRead(notification.id);
            Get.to(() => NotificationDetailScreen(notification: notification));
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.15)
                : (notification.isRead
                      ? Theme.of(context).cardColor
                      : Theme.of(context).primaryColor.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 1.5)
                : (!notification.isRead
                      ? Border.all(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.3),
                        )
                      : null),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelectionMode ? 48 : 0,
                child: isSelectionMode
                    ? Checkbox(
                        value: isSelected,
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: (val) =>
                            controller.toggleItemSelection(notification.id),
                      )
                    : null,
              ),
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                  leading: Container(
                    margin: const EdgeInsets.only(left: 16),
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
                      color: NotificationUtils.getIconColor(
                        context,
                        notification.type,
                      ),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
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
                      const SizedBox(height: 6),
                      Text(
                        "${notification.date.hour}:${notification.date.minute.toString().padLeft(2, '0')} ${notification.date.day}/${notification.date.month}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
