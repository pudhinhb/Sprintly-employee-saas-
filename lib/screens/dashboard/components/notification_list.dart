import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webnox_taskops/models/notification_model.dart' as model;
import 'package:webnox_taskops/view_model/auth_view_model.dart';
import 'package:webnox_taskops/view_model/notification_view_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationList extends StatefulWidget {
  const NotificationList({super.key});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      final userId = authVM.localStorage.userId;
      if (userId.isNotEmpty) {
        Provider.of<NotificationViewModel>(context, listen: false)
            .fetchNotifications(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.notifications.isEmpty) {
          return const SizedBox.shrink(); // Hide if empty
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (viewModel.notifications.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        final authVM =
                            Provider.of<AuthViewModel>(context, listen: false);
                        viewModel.markAllAsRead(authVM.localStorage.userId);
                      },
                      child: Text(
                        'Mark all as read',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: viewModel.notifications.length,
              itemBuilder: (context, index) {
                final notification = viewModel.notifications[index];
                return _buildNotificationItem(context, notification, viewModel);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(BuildContext context,
      model.Notification notification, NotificationViewModel viewModel) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    return Card(
      elevation: 0,
      color: notification.isRead
          ? Colors.transparent
          : Theme.of(context).primaryColor.withOpacity(0.05),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.notifications_outlined,
          color: notification.isRead
              ? Colors.grey
              : Theme.of(context).primaryColor,
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(notification.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        onTap: () {
          if (!notification.isRead) {
            viewModel.markAsRead(
                notification.notificationId, authVM.localStorage.userId);
          }
        },
      ),
    );
  }
}
