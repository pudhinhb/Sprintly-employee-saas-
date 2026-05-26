import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:webnox_taskops/view_model/announcement_view_model.dart';
import 'package:webnox_taskops/view_model/notification_view_model.dart';
import 'package:webnox_taskops/models/notification_model.dart' as notif;
import 'package:webnox_taskops/helpers/common_colors.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:webnox_taskops/view_model/auth_view_model.dart';

/// Announcement popup widget shown when notification bell is clicked
class AnnouncementPopup extends StatelessWidget {
  const AnnouncementPopup({super.key});

  static void show(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset position =
        button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx - 280,
        position.dy + button.size.height + 8,
        position.dx + button.size.width,
        position.dy + button.size.height + 400,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      constraints: const BoxConstraints(
        minWidth: 320,
        maxWidth: 380,
        maxHeight: 450,
      ),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: const _AnnouncementPopupContent(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _AnnouncementPopupContent();
  }
}

class _AnnouncementPopupContent extends StatefulWidget {
  const _AnnouncementPopupContent();

  @override
  State<_AnnouncementPopupContent> createState() =>
      _AnnouncementPopupContentState();
}

class _AnnouncementPopupContentState extends State<_AnnouncementPopupContent> {
  // Collapsible state
  bool _isAnnouncementsExpanded = true;
  bool _isNotificationsExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('DEBUG: AnnouncementPopup postFrameCallback');
      context.read<AnnouncementViewModel>().fetchAnnouncements();
      final authVM = context.read<AuthViewModel>();
      final userId = authVM.localStorage.userId;
      print('DEBUG: Auth userId: "$userId"');

      if (userId.isNotEmpty) {
        print('DEBUG: Calling fetchNotifications for user: $userId');
        context.read<NotificationViewModel>().fetchNotifications(userId);
      } else {
        print('DEBUG: UserId is empty, skipping fetchNotifications');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AnnouncementViewModel, NotificationViewModel>(
      builder: (context, announcementVM, notificationVM, child) {
        return Container(
          width: 350,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Updates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (announcementVM.announcements.isNotEmpty ||
                        notificationVM.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          '${announcementVM.announcements.length + notificationVM.unreadCount} New',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Announcements Section
                      if (announcementVM.announcements.isNotEmpty) ...[
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isAnnouncementsExpanded =
                                  !_isAnnouncementsExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'ANNOUNCEMENTS',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                Icon(
                                  _isAnnouncementsExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isAnnouncementsExpanded)
                          _buildAnnouncementContent(context, announcementVM),
                      ],

                      if (announcementVM.announcements.isNotEmpty)
                        Divider(height: 1),

                      // Notifications Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'NOTIFICATIONS',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            if (notificationVM.notifications.isNotEmpty)
                              InkWell(
                                onTap: () async {
                                  final authVM = context.read<AuthViewModel>();
                                  if (authVM.localStorage.userId.isNotEmpty) {
                                    await notificationVM.markAllAsRead(
                                        authVM.localStorage.userId);
                                  }
                                },
                                child: Text(
                                  'Mark all as read',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isNotificationsExpanded =
                                      !_isNotificationsExpanded;
                                });
                              },
                              child: Icon(
                                _isNotificationsExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isNotificationsExpanded)
                        _buildNotificationContent(context, notificationVM),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementContent(
      BuildContext context, AnnouncementViewModel viewModel) {
    if (viewModel.isLoading)
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2)));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount:
          viewModel.announcements.take(3).length, // Show max 3 announcements
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: Colors.grey.withOpacity(0.1),
      ),
      itemBuilder: (context, index) {
        final announcement = viewModel.announcements[index];
        return _AnnouncementCard(announcement: announcement);
      },
    );
  }

  Widget _buildNotificationContent(
      BuildContext context, NotificationViewModel viewModel) {
    if (viewModel.isLoading && viewModel.notifications.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (viewModel.notifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No notifications',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: viewModel.notifications.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: Colors.grey.withOpacity(0.1),
      ),
      itemBuilder: (context, index) {
        final notification = viewModel.notifications[index];
        return _NotificationCard(
            notification: notification, viewModel: viewModel);
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return InkWell(
      onTap: () => _showAnnouncementDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    announcement.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: CommonColors.getTextColor(context),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(announcement.announcementDate),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement.content,
              style: TextStyle(
                fontSize: 13,
                color: CommonColors.getTextColor(context).withOpacity(0.7),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (announcement.createdAt != null) ...[
                  Icon(Icons.access_time_rounded,
                      size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    timeFormat.format(announcement.createdAt!),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (announcement.createdBy.isNotEmpty) ...[
                  const Text('•',
                      style: TextStyle(color: Colors.grey, fontSize: 10)),
                  const SizedBox(width: 6),
                  Icon(Icons.person_outline_rounded,
                      size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      announcement.createdBy,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey[400]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                announcement.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CommonColors.getTextColor(context),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    DateFormat('MMMM d, yyyy')
                        .format(announcement.announcementDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Text(
                    announcement.content,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          CommonColors.getTextColor(context).withOpacity(0.8),
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              if (announcement.createdBy.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey[200],
                      child:
                          Icon(Icons.person, size: 14, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Posted by ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    Text(
                      announcement.createdBy,
                      style: TextStyle(
                        fontSize: 12,
                        color: CommonColors.getTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final notif.Notification notification;
  final NotificationViewModel viewModel;

  const _NotificationCard(
      {required this.notification, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    // Dynamic style based on read status
    // Unread: Bold title, Primary color dot
    // Read: Normal title, No dot, Transparent background
    final bool isUnread = !notification.isRead;

    return InkWell(
      onTap: () {
        if (isUnread) {
          viewModel.markAsRead(
              notification.notificationId, authVM.localStorage.userId);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? Theme.of(context)
                  .primaryColor
                  .withOpacity(0.05) // Highlight unread
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 20,
              color: isUnread ? Theme.of(context).primaryColor : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isUnread
                          ? FontWeight.w700 // BOLD for unread
                          : FontWeight.w400, // NORMAL for read
                      color: CommonColors.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          CommonColors.getTextColor(context).withOpacity(0.7),
                      fontWeight:
                          isUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      viewModel.markAsRead(notification.notificationId,
                          authVM.localStorage.userId);
                    },
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                      semanticLabel: 'Mark as read',
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
