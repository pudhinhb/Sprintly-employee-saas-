import 'package:flutter/material.dart';
import '../../helpers/common_colors.dart';
import '../../model/team_sync_conversation.dart';

/// User status options
final List<Map<String, dynamic>> statusOptions = [
  {
    'status': UserStatus.active,
    'label': 'Active',
    'icon': Icons.circle,
    'color': const Color(0xFF22C55E), // Green
  },
  {
    'status': UserStatus.away,
    'label': 'Away',
    'icon': Icons.circle,
    'color': const Color(0xFFF59E0B), // Orange
  },
  {
    'status': UserStatus.inBreak,
    'label': 'In Break',
    'icon': Icons.circle,
    'color': const Color(0xFFEF4444), // Red
  },
  {
    'status': UserStatus.offline,
    'label': 'Offline',
    'icon': Icons.circle,
    'color': const Color(0xFF94A3B8), // Gray
  },
];

/// User Status Selector Widget
class UserStatusSelector extends StatelessWidget {
  final UserStatus currentStatus;
  final Function(UserStatus) onStatusChanged;
  final bool isDark;
  final Color? textColor;
  final Color? popupColor;

  const UserStatusSelector({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
    required this.isDark,
    this.textColor,
    this.popupColor,
  });

  @override
  Widget build(BuildContext context) {
    final currentOption = statusOptions.firstWhere(
      (opt) => opt['status'] == currentStatus,
      orElse: () => statusOptions.first,
    );

    return PopupMenuButton<UserStatus>(
      onSelected: onStatusChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: popupColor ?? CommonColors.getCardColor(context),
      itemBuilder: (context) => statusOptions.map((option) {
        final isSelected = option['status'] == currentStatus;
        return PopupMenuItem<UserStatus>(
          value: option['status'] as UserStatus,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: option['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                option['label'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: textColor ?? CommonColors.getTextColor(context),
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(Icons.check, size: 18, color: CommonColors.primary),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (currentOption['color'] as Color).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (currentOption['color'] as Color).withOpacity(0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: currentOption['color'] as Color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              currentOption['label'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: currentOption['color'] as Color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: currentOption['color'] as Color,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact status indicator for header
class StatusIndicatorDot extends StatelessWidget {
  final UserStatus status;
  final double size;
  final Color? borderColor;

  const StatusIndicatorDot({
    super.key,
    required this.status,
    this.size = 10,
    this.borderColor,
  });

  Color get _color {
    switch (status) {
      case UserStatus.active:
        return const Color(0xFF22C55E);
      case UserStatus.away:
        return const Color(0xFFF59E0B);
      case UserStatus.inBreak:
      case UserStatus.inMeeting:
      case UserStatus.inLunch:
        return const Color(0xFFEF4444);
      case UserStatus.offline:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? Colors.white,
          width: 1.5,
        ),
      ),
    );
  }
}
