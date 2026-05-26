import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../model/team_sync_message.dart';
import '../../../model/chat_theme_model.dart';

/// Message Bubble Widget for chat messages
class MessageBubble extends StatefulWidget {
  final TeamSyncMessage message;
  final bool isMe;
  final bool isDark;
  final Function(TeamSyncMessage)? onFileClick;
  final Function(String)? onReact;
  final VoidCallback? onReply;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;
  final VoidCallback? onForward;
  final VoidCallback? onPin;
  final Function(TeamSyncMessage)? onEdit;
  final VoidCallback? onStar;
  final TeamSyncMessage? repliedMessage;
  final ChatTheme? chatTheme;
  final String currentUserId;
  final Map<String, String>? userNames;
  final bool isGroup;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isDark,
    this.onFileClick,
    this.onReact,
    this.onReply,
    this.onCopy,
    this.onDelete,
    this.onDownload,
    this.onForward,
    this.onPin,
    this.onEdit,
    this.onStar,
    this.repliedMessage,
    this.chatTheme,
    required this.currentUserId,
    this.userNames,
    this.isGroup = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool get isDefaultTheme => widget.chatTheme?.id == 'default' || widget.chatTheme == null;
  
  Color get secondaryBubbleColor => isDefaultTheme
      ? (widget.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
      : (widget.chatTheme?.secondaryColor ?? (widget.isDark ? AppTheme.darkSurfaceColor : Colors.white));

  Color get myBubbleTextColor => isDefaultTheme ? Colors.white : (widget.chatTheme?.textColor ?? Colors.white);
  
  Color get otherBubbleTextColor => isDefaultTheme 
      ? (widget.isDark ? Colors.white : const Color(0xFF1E293B))
      : (widget.chatTheme?.textColor ?? (widget.isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary));

  Color get primaryThemeColor => widget.chatTheme?.primaryColor ?? AppTheme.primaryColor;


  @override
  Widget build(BuildContext context) {
    final primaryTextColor = widget.isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final secondaryTextColor = widget.isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    final isImage = widget.message.isImageMessage;


    return MouseRegion(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: widget.message.reactions.isNotEmpty ? 28 : 2,
          top: 22,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          children: [
            Row(
              mainAxisAlignment:
                  widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!widget.isMe) _buildAvatar(),
                if (!widget.isMe) const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isImage
                          ? 280
                          : MediaQuery.of(context).size.width * 0.65,
                    ),
                    decoration: BoxDecoration(
                      gradient: isImage
                          ? null
                          : widget.isMe
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    widget.chatTheme?.primaryColor ??
                                        AppTheme.primaryColor,
                                    (widget.chatTheme?.primaryColor ??
                                            AppTheme.primaryColor)
                                        .withValues(alpha: 0.85),
                                  ],
                                )
                              : null,
                      color: isImage
                          ? Colors.transparent
                          : widget.isMe
                              ? null // Handled by gradient
                              : secondaryBubbleColor,

                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
                        bottomRight: Radius.circular(widget.isMe ? 4 : 20),
                      ),
                      boxShadow: isImage
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: widget.isMe
                                    ? (widget.chatTheme?.primaryColor ??
                                            AppTheme.primaryColor)
                                        .withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: isImage
                              ? EdgeInsets.zero
                              : const EdgeInsets.only(right: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Reply Preview
                              if (widget.repliedMessage != null)
                                Container(
                                  margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: widget.isMe
                                        ? Colors.black.withValues(alpha: 0.1)
                                        : widget.isDark
                                            ? Colors.black
                                                .withValues(alpha: 0.2)
                                            : Colors.grey
                                                .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(
                                      left: BorderSide(
                                        color: widget.isMe
                                            ? Colors.white
                                                .withValues(alpha: 0.5)
                                            : AppTheme.primaryColor,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.repliedMessage!.senderName ??
                                            'User',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: widget.isMe
                                              ? Colors.white
                                                  .withValues(alpha: 0.9)
                                              : widget.chatTheme
                                                      ?.primaryColor ??
                                                  AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.repliedMessage!.content ??
                                            'Attachment',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: widget.isMe
                                              ? Colors.white
                                                  .withValues(alpha: 0.8)
                                              : secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Sender Name (for Group Chats)
                              if (widget.isGroup && !widget.isMe)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 8, 12, 0),
                                  child: Text(
                                    widget.message.senderName ?? 'User',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: primaryThemeColor,

                                    ),
                                  ),
                                ),

                              // Content based on message type
                              _buildMessageContent(context, primaryTextColor),

                              // Footer with time and status (Hidden for images as it's overlaid)
                              if (!isImage)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 4, 12, 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.message.isStarred) ...[
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      if (widget.message.isPinned) ...[
                                        Icon(
                                          Icons.push_pin_rounded,
                                          size: 14,
                                          color: widget.isMe
                                              ? Colors.white
                                                  .withValues(alpha: 0.7)
                                              : secondaryTextColor,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      if (widget.message.isEdited)
                                        Text(
                                          '(edited) ',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                            color: widget.isMe
                                                ? Colors.white
                                                    .withValues(alpha: 0.7)
                                                : secondaryTextColor,
                                          ),
                                        ),
                                      Text(
                                        DateFormat(
                                          'h:mm a',
                                        ).format(
                                            widget.message.createdAt.toLocal()),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: widget.isMe
                                              ? Colors.white
                                              : secondaryTextColor,
                                        ),
                                      ),
                                      if (widget.isMe) ...[
                                        const SizedBox(width: 4),
                                        _buildStatusIcon(),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Hover Menu Button (Arrow)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: _buildMessageMenuButton(secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.isMe) const SizedBox(width: 8),
                if (widget.isMe) _buildAvatar(),
              ],
            ),

            // Reactions - positioned outside below the message bubble
            if (widget.message.reactions.isNotEmpty)
              Positioned(
                bottom: -22,
                right: widget.isMe ? 16 : null,
                left: widget.isMe ? null : 50,
                child: _buildReactionsChip(),
              ),
          ],
        ),
      ),
    );
  }

  bool _canEdit() {
    if (!widget.isMe) return false;
    if (widget.onEdit == null) return false;

    final type = widget.message.messageType;
    if (type != 'text' && type != 'contact') return false;

    // Time check (UTC)
    final now = DateTime.now().toUtc();
    final createdAt = widget.message.createdAt.toUtc();
    final diffMinutes = now.difference(createdAt).inMinutes.abs();

    return diffMinutes < 60;
  }

  /// Check if message has a downloadable file (img, pdf, doc, docx only)
  bool get _isDownloadable {
    if (widget.message.fileUrl == null) return false;
    if (widget.message.isImageMessage) return true;
    if (widget.message.isFileMessage ||
        widget.message.messageType == 'document') {
      final name = widget.message.fileName ?? '';
      final ext = name.toLowerCase().split('.').lastOrNull ?? '';
      return ['pdf', 'doc', 'docx'].contains(ext);
    }
    return false;
  }

  void _showMessageInfo() {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    if (isDesktop) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (dialogContext, __, ___) => Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            child: SizedBox(
              width: 400,
              height: double.infinity,
              child: _buildMessageInfoContent(onClose: () {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              }),
            ),
          ),
        ),
        transitionBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(anim),
            child: child,
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor:
              widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          child: SizedBox(
            width: 400,
            child: _buildMessageInfoContent(
              isDialog: true,
              onClose: () {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ),
        ),
      );
    }
  }

  Widget _buildMessageInfoContent(
      {bool isDialog = false, VoidCallback? onClose}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Message Info',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close,
                    color: widget.isDark ? Colors.white70 : Colors.black54),
                onPressed: onClose ?? () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sent Time
          _buildInfoItem(
            Icons.access_time_rounded,
            'Sent Time',
            DateFormat('MMMM d, yyyy • h:mm a')
                .format(widget.message.createdAt.toLocal()),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          // Status List
          if (widget.message.statusList != null &&
              widget.message.statusList!.isNotEmpty) ...[
            Text(
              'Read Receipts',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.message.statusList!.map((info) {
              final isRead = info.readAt != null;
              final isDelivered = info.deliveredAt != null;
              final statusText = isRead
                  ? 'Read at ${DateFormat('h:mm a').format(info.readAt!.toLocal())}'
                  : (isDelivered
                      ? 'Delivered at ${DateFormat('h:mm a').format(info.deliveredAt!.toLocal())}'
                      : 'Sent');

              final statusIcon = isRead
                  ? Icons.done_all_rounded
                  : (isDelivered
                      ? Icons.done_all_rounded
                      : Icons.check_rounded);
              final iconColor = isRead
                  ? Colors.blue
                  : (isDelivered ? Colors.grey : Colors.grey);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 16, color: iconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'User (${info.userId}) - $statusText',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: widget.isDark
                                ? Colors.white70
                                : Colors.black87),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else
            _buildInfoItem(
              Icons.info_outline_rounded,
              'Status',
              widget.message.status.toString().split('.').last.toUpperCase(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.white10 : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 20,
              color: widget.isDark ? Colors.white70 : Colors.grey.shade700),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: widget.isDark ? Colors.white70 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: widget.isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(String value) {
    debugPrint('[MessageBubble] Menu selection: $value');

    switch (value) {
      case 'info':
        _showMessageInfo();
        return;
      case 'edit':
        if (widget.onEdit != null) widget.onEdit!(widget.message);
        return;
      case 'reply':
        if (widget.onReply != null) widget.onReply!();
        return;
      case 'copy':
        if (widget.onCopy != null) {
          widget.onCopy!();
        } else if (widget.message.content != null &&
            widget.message.content!.isNotEmpty) {
          Clipboard.setData(ClipboardData(text: widget.message.content!));
          debugPrint('[MessageBubble] Copied to clipboard');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Copied to clipboard', style: GoogleFonts.poppins()),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
        return;
      case 'forward':
        if (widget.onForward != null) widget.onForward!();
        return;
      case 'pin':
        if (widget.onPin != null) widget.onPin!();
        return;
      case 'star':
        if (widget.onStar != null) widget.onStar!();
        return;
      case 'delete':
        if (widget.onDelete != null) widget.onDelete!();
        return;
      case 'download':
        if (widget.onDownload != null) {
          widget.onDownload!();
        } else if (widget.onFileClick != null) {
          widget.onFileClick!(widget.message);
        }
        return;
      case 'react_like':
        widget.onReact?.call('👍');
        return;
      case 'react_love':
        widget.onReact?.call('❤️');
        return;
      case 'react_laugh':
        widget.onReact?.call('😂');
        return;
      case 'react_more':
        Future.delayed(Duration.zero, () {
          if (mounted) _showEmojiPicker(context);
        });
        return;
    }
  }

  Widget _buildMessageMenuButton(Color iconColor) {
    final hasFile = widget.message.fileUrl != null;
    final hasContent =
        widget.message.content != null && widget.message.content!.isNotEmpty;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: widget.isMe
            ? Colors.black.withOpacity(0.1)
            : Colors.white.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 20,
          color: widget.isMe ? Colors.white : iconColor,
        ),
        tooltip: 'Message options',
        elevation: 4,
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: _handleMenuSelection,
        itemBuilder: (context) {
          return [
            // Info (Me only)
            if (widget.isMe)
              PopupMenuItem<String>(
                value: 'info',
                child: _buildMenuItemContent(
                    Icons.info_outline_rounded, 'Info', iconColor),
              ),

            if (widget.isMe) const PopupMenuDivider(),

            // Edit
            if (_canEdit())
              PopupMenuItem<String>(
                value: 'edit',
                enabled: true,
                child: _buildMenuItemContent(
                    Icons.edit_rounded, 'Edit', iconColor),
              ),

            // Reply
            if (widget.onReply != null)
              PopupMenuItem<String>(
                value: 'reply',
                enabled: true,
                child: _buildMenuItemContent(
                    Icons.reply_rounded, 'Reply', iconColor),
              ),

            // Forward
            if (widget.onForward != null)
              PopupMenuItem<String>(
                value: 'forward',
                enabled: true,
                child: _buildMenuItemContent(
                    Icons.forward_rounded, 'Forward', iconColor),
              ),

            // Copy (Text only)
            if (hasContent)
              PopupMenuItem<String>(
                value: 'copy',
                enabled: true,
                child: _buildMenuItemContent(
                    Icons.copy_rounded, 'Copy', iconColor),
              ),

            // Download (Files only)
            if (hasFile &&
                _isDownloadable &&
                (widget.onDownload != null || widget.onFileClick != null))
              PopupMenuItem<String>(
                value: 'download',
                enabled: true,
                child: _buildMenuItemContent(
                    Icons.download_rounded, 'Download', iconColor),
              ),

            // Pin / Unpin
            if (widget.onPin != null)
              PopupMenuItem<String>(
                value: 'pin',
                enabled: true,
                child: _buildMenuItemContent(
                  widget.message.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  widget.message.isPinned ? 'Unpin' : 'Pin',
                  iconColor,
                ),
              ),

            // Star / Unstar
            if (widget.onStar != null)
              PopupMenuItem<String>(
                value: 'star',
                enabled: true,
                child: _buildMenuItemContent(
                  widget.message.isStarred
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  widget.message.isStarred ? 'Unstar' : 'Star',
                  iconColor,
                ),
              ),

            const PopupMenuDivider(),

            // Reactions
            if (widget.onReact != null)
              PopupMenuItem<String>(
                value: 'react_container',
                enabled: true,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildReactionOption('👍', 'react_like'),
                    _buildReactionOption('❤️', 'react_love'),
                    _buildReactionOption('😂', 'react_laugh'),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) _showEmojiPicker(context);
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_reaction_rounded,
                            size: 20, color: iconColor),
                      ),
                    ),
                  ],
                ),
              ),

            // Delete (Me only)
            if (widget.isMe && widget.onDelete != null) ...[
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'delete',
                enabled: true,
                child: _buildMenuItemContent(
                    Icons.delete_outline_rounded, 'Delete', Colors.red),
              ),
            ],
          ];
        },
      ),
    );
  }

  Widget _buildMenuItemContent(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: label == 'Delete' ? Colors.red : color),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: label == 'Delete'
                ? Colors.red
                : (widget.isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildReactionOption(String emoji, String value) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close menu
        _handleMenuSelection(value);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            width: 350,
            height: 400,
            child: emoji.EmojiPicker(
              onEmojiSelected: (category, em) {
                widget.onReact?.call(em.emoji);
                Navigator.pop(context);
              },
              config: emoji.Config(),
            ),
          ),
        );
      },
    );
  }

  /// Build reactions chip - displayed outside and below message bubble
  Widget _buildReactionsChip() {
    if (widget.message.reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions count
    final reactionCounts = <String, int>{};
    for (var r in widget.message.reactions) {
      reactionCounts[r.reaction] = (reactionCounts[r.reaction] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: widget.isDark ? Colors.white10 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactionCounts.entries.map((entry) {
          // Get names of reactors
          final reactors = widget.message.reactions
              .where((r) => r.reaction == entry.key)
              .toList();

          final names = reactors
              .map((r) {
                if (r.userId == widget.currentUserId) return 'You';
                return widget.userNames?[r.userId] ?? 'User';
              })
              .toSet()
              .join(', ');

          return GestureDetector(
            onTap: () => widget.onReact?.call(entry.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              color: Colors.transparent, // Hit test target
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    names,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: widget.isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvatar() {
    final name = widget.message.senderName ?? 'U';
    final initials = name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .toUpperCase();
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
    ];
    final colorIndex = name.length % colors.length;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[colorIndex],
            colors[colorIndex].withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: widget.message.senderImage != null
          ? ClipOval(
              child: Image.network(
                widget.message.senderImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
    );
  }

  Widget _buildMessageContent(BuildContext context, Color primaryTextColor) {
    if (widget.message.isTextMessage) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Text(
          widget.message.content ?? '',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: widget.isMe ? myBubbleTextColor : otherBubbleTextColor,
            height: 1.4,
          ),
        ),

      );
    }

    if (widget.message.isImageMessage) {
      return GestureDetector(
        onTap: () => widget.onFileClick?.call(widget.message),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 260,
                maxHeight: 350,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.message.fileUrl != null
                    ? Image.network(
                        widget.message.fileUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 260,
                            height: 200,
                            color: widget.isDark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          width: 260,
                          height: 200,
                          color: widget.isDark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 48),
                        ),
                      )
                    : Container(
                        width: 260,
                        height: 200,
                        color:
                            widget.isDark ? Colors.grey[800] : Colors.grey[200],
                        child: const Icon(Icons.image, size: 48),
                      ),
              ),
            ),
            // Overlay Footer
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.message.isStarred) ...[
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (widget.message.isPinned) ...[
                      const Icon(
                        Icons.push_pin_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      DateFormat('h:mm a')
                          .format(widget.message.createdAt.toLocal()),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.isMe) ...[
                      const SizedBox(width: 4),
                      _buildStatusIcon(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.message.isFileMessage ||
        widget.message.messageType == 'document') {
      return GestureDetector(
        onTap: () => widget.onFileClick?.call(widget.message),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.isMe
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(widget.message.fileName ?? ''),
                  color: widget.isMe ? Colors.white : AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.message.fileName ?? 'File',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: widget.isMe ? Colors.white : primaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.message.fileSize != null)
                      Text(
                        _formatFileSize(widget.message.fileSize!),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: widget.isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : (widget.isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.message.isContactMessage) {
      final phone = widget.message.contactPhone;
      final email = widget.message.contactEmail;
      final name = widget.message.contactName ?? 'Contact';
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.isMe
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: widget.isMe ? Colors.white : AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.isMe ? Colors.white : primaryTextColor,
                        ),
                      ),
                      if (phone != null)
                        Text(
                          phone,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: widget.isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : (widget.isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary),
                          ),
                        ),
                      if (email != null && email.isNotEmpty)
                        Text(
                          email,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: widget.isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : (widget.isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (phone != null && phone.isNotEmpty)
                  _ContactActionButton(
                    label: 'Call',
                    icon: Icons.call_rounded,
                    isMe: widget.isMe,
                    onTap: () async {
                      final uri = Uri(scheme: 'tel', path: phone.trim());
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                _ContactActionButton(
                  label: 'Add to contacts',
                  icon: Icons.contact_phone_rounded,
                  isMe: widget.isMe,
                  onTap: () {
                    final vCard = StringBuffer();
                    vCard.writeln('BEGIN:VCARD');
                    vCard.writeln('VERSION:3.0');
                    vCard.writeln('FN:$name');
                    vCard.writeln('N:$name;;;');
                    if (phone != null && phone.isNotEmpty) {
                      vCard.writeln('TEL;TYPE=CELL:$phone');
                    }
                    if (email != null && email.isNotEmpty) {
                      vCard.writeln('EMAIL:$email');
                    }
                    vCard.writeln('END:VCARD');
                    Clipboard.setData(
                      ClipboardData(text: vCard.toString()),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Contact copied. Paste into your contacts app to add.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default text
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Text(
        widget.message.content ?? '[Unsupported message type]',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: widget.isMe ? Colors.white : primaryTextColor,
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon = _getStatusIconData();
    Color color = Colors.transparent;

    switch (widget.message.status) {
      case MessageStatus.sending:
        color = Colors.white.withOpacity(0.5);
        break;
      case MessageStatus.sent:
      case MessageStatus.delivered:
        color = Colors.white; // Solid white for visibility
        break;
      case MessageStatus.read:
        // High contrast Bright Yellow for read receipts on blue/colored bubbles
        color = widget.chatTheme?.statusIconColor ?? const Color(0xFFFFD600);
        break;
      case MessageStatus.failed:
        color = Colors.redAccent;
        break;
    }

    return Icon(
      icon,
      size: 16,
      color: color,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 2,
          offset: const Offset(0.5, 0.5),
        ),
      ],
    );
  }

  IconData _getStatusIconData() {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return Icons.access_time_rounded;
      case MessageStatus.sent:
        return Icons.check_rounded;
      case MessageStatus.delivered:
      case MessageStatus.read:
        return Icons.done_all_rounded;
      case MessageStatus.failed:
        return Icons.error_outline_rounded;
    }
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;

    if (['pdf'].contains(ext)) return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(ext)) return Icons.description;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart;
    if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow;
    if (['zip', 'rar', '7z'].contains(ext)) return Icons.folder_zip;
    if (['mp3', 'wav', 'aac'].contains(ext)) return Icons.audio_file;
    if (['mp4', 'mov', 'avi'].contains(ext)) return Icons.video_file;

    return Icons.insert_drive_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Action button for contact message (Call, Add to contacts)
class _ContactActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isMe;
  final VoidCallback onTap;

  const _ContactActionButton({
    required this.label,
    required this.icon,
    required this.isMe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isMe
          ? Colors.white.withValues(alpha: 0.2)
          : AppTheme.primaryColor.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isMe ? Colors.white : AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isMe ? Colors.white : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
