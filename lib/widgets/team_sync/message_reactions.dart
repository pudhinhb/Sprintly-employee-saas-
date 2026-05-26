import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/common_colors.dart';

/// Available reactions
const List<String> availableReactions = ['👍', '❤️', '😂', '😮', '😢', '😡'];

/// Popup menu for message actions (reply, react, copy, etc.)
class MessageActionsPopup extends StatelessWidget {
  final bool isDark;
  final bool isMe;
  final String messageId;
  final String? content;
  final VoidCallback onReply;
  final Function(String emoji) onReact;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  const MessageActionsPopup({
    super.key,
    required this.isDark,
    required this.isMe,
    required this.messageId,
    this.content,
    required this.onReply,
    required this.onReact,
    this.onCopy,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = CommonColors.getTextColor(context);
    final surfaceColor = CommonColors.getCardColor(context);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reaction row
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: availableReactions.map((emoji) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onReact(emoji);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            Divider(height: 1, color: borderColor),
            // Action items
            _buildActionItem(
              context: context,
              icon: Icons.reply_rounded,
              label: 'Reply',
              textColor: textColor,
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            if (content != null && content!.isNotEmpty)
              _buildActionItem(
                context: context,
                icon: Icons.copy_rounded,
                label: 'Copy',
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context);
                  if (content != null) {
                    Clipboard.setData(ClipboardData(text: content!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  }
                  onCopy?.call();
                },
              ),
            if (isMe && onDelete != null)
              _buildActionItem(
                context: context,
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                textColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Display reactions on a message
class MessageReactionsDisplay extends StatelessWidget {
  final List<Map<String, dynamic>> reactions;
  final bool isDark;
  final bool isMe;
  final VoidCallback? onTap;

  const MessageReactionsDisplay({
    super.key,
    required this.reactions,
    required this.isDark,
    required this.isMe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by emoji
    final grouped = <String, int>{};
    for (final reaction in reactions) {
      final emoji = reaction['reaction']?.toString() ?? '';
      if (emoji.isNotEmpty) {
        grouped[emoji] = (grouped[emoji] ?? 0) + 1;
      }
    }

    if (grouped.isEmpty) return const SizedBox.shrink();

    final surfaceColor = CommonColors.getCardColor(context);
    final secondaryTextColor = CommonColors.getSecondaryTextColor(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          left: isMe ? 0 : 8,
          right: isMe ? 8 : 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: surfaceColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: grouped.entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 14)),
                if (entry.value > 1) ...[
                  const SizedBox(width: 2),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Reply preview widget (shown above message input)
class ReplyPreview extends StatelessWidget {
  final String senderName;
  final String content;
  final bool isDark;
  final VoidCallback onCancel;

  const ReplyPreview({
    super.key,
    required this.senderName,
    required this.content,
    required this.isDark,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryTextColor = CommonColors.getSecondaryTextColor(context);
    final surfaceColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          left: BorderSide(color: CommonColors.primary, width: 4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 20, color: CommonColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to $senderName',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: secondaryTextColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

/// Quoted message in bubble (for replies)
class QuotedMessage extends StatelessWidget {
  final String senderName;
  final String content;
  final bool isDark;
  final bool isMe;
  final VoidCallback? onTap;

  const QuotedMessage({
    super.key,
    required this.senderName,
    required this.content,
    required this.isDark,
    required this.isMe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryTextColor = CommonColors.getSecondaryTextColor(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withOpacity(0.2)
              : (isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isMe ? Colors.white70 : CommonColors.primary,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              senderName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    isMe ? Colors.white.withOpacity(0.9) : CommonColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color:
                    isMe ? Colors.white.withOpacity(0.7) : secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show message actions popup
void showMessageActionsPopup({
  required BuildContext context,
  required bool isDark,
  required bool isMe,
  required String messageId,
  required String? content,
  required VoidCallback onReply,
  required Function(String emoji) onReact,
  VoidCallback? onCopy,
  VoidCallback? onDelete,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black26,
    builder: (context) => Center(
      child: MessageActionsPopup(
        isDark: isDark,
        isMe: isMe,
        messageId: messageId,
        content: content,
        onReply: onReply,
        onReact: onReact,
        onCopy: onCopy,
        onDelete: onDelete,
      ),
    ),
  );
}
