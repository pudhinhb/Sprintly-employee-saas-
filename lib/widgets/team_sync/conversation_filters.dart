import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../helpers/common_colors.dart';

/// Conversation filter types
enum ConversationFilter {
  all,
  unread,
  groups,
  direct,
}

extension ConversationFilterExtension on ConversationFilter {
  String get displayName {
    switch (this) {
      case ConversationFilter.all:
        return 'All';
      case ConversationFilter.unread:
        return 'Unread';
      case ConversationFilter.groups:
        return 'Groups';
      case ConversationFilter.direct:
        return 'Direct';
    }
  }

  IconData get icon {
    switch (this) {
      case ConversationFilter.all:
        return Icons.chat_bubble_outline;
      case ConversationFilter.unread:
        return Icons.mark_chat_unread_outlined;
      case ConversationFilter.groups:
        return Icons.group_outlined;
      case ConversationFilter.direct:
        return Icons.person_outline;
    }
  }
}

/// Filter chips for conversation filtering
class ConversationFilterChips extends StatelessWidget {
  final ConversationFilter selectedFilter;
  final ValueChanged<ConversationFilter> onFilterChanged;
  final bool isDark;
  final int unreadCount;
  final Color? textColor;
  final Color? secondaryTextColor;

  const ConversationFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.isDark,
    this.unreadCount = 0,
    this.textColor,
    this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: ConversationFilter.values.map((filter) {
            final isSelected = selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                filter: filter,
                isSelected: isSelected,
                isDark: isDark,
                badgeCount:
                    filter == ConversationFilter.unread ? unreadCount : 0,
                onTap: () => onFilterChanged(filter),
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final ConversationFilter filter;
  final bool isSelected;
  final bool isDark;
  final int badgeCount;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? secondaryTextColor;

  const _FilterChip({
    required this.filter,
    required this.isSelected,
    required this.isDark,
    required this.badgeCount,
    required this.onTap,
    this.textColor,
    this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = CommonColors.primary;
    final effectiveTextColor = textColor ?? CommonColors.getTextColor(context);
    final effectiveSecondaryTextColor =
        secondaryTextColor ?? CommonColors.getSecondaryTextColor(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.15)
              : effectiveTextColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filter.icon,
              size: 16,
              color: isSelected ? primaryColor : effectiveSecondaryTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              filter.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : effectiveTextColor,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
