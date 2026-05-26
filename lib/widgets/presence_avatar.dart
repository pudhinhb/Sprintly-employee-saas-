import 'package:flutter/material.dart';
import 'package:webnox_taskops/helpers/common_colors.dart';

/// A reusable avatar widget with presence indicator dot
/// Shows online (green), away (yellow), or offline (gray) status
class PresenceAvatar extends StatelessWidget {
  /// The user ID to show presence for
  final String userId;

  /// Radius of the avatar circle
  final double radius;

  /// Optional profile image URL
  final String? imageUrl;

  /// Fallback text to show in avatar (usually first letter of name)
  final String fallbackText;

  /// Optional background color for avatar when no image
  final Color? backgroundColor;

  /// Whether to show the presence dot
  final bool showPresenceDot;

  /// Is the user online?
  final bool isOnline;

  const PresenceAvatar({
    super.key,
    required this.userId,
    required this.fallbackText,
    this.radius = 20,
    this.imageUrl,
    this.backgroundColor,
    this.showPresenceDot = true,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isOnline ? 'Online' : 'Offline',
      waitDuration: const Duration(milliseconds: 500),
      child: Stack(
        children: [
          // Avatar circle
          CircleAvatar(
            radius: radius,
            backgroundColor:
                backgroundColor ?? CommonColors.primary.withOpacity(0.1),
            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                ? NetworkImage(imageUrl!)
                : null,
            child: imageUrl == null || imageUrl!.isEmpty
                ? Text(
                    fallbackText.isNotEmpty
                        ? fallbackText.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: radius * 0.8,
                      fontWeight: FontWeight.bold,
                      color: CommonColors.primary,
                    ),
                  )
                : null,
          ),

          // Presence indicator dot
          if (showPresenceDot)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: radius * 0.5,
                height: radius * 0.5,
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFF22C55E) // Green - online
                      : const Color(0xFF9CA3AF), // Gray - offline
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: radius * 0.08,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A simpler version that takes isOnline directly
class PresenceAvatarDirect extends StatelessWidget {
  final bool isOnline;
  final double radius;
  final String? imageUrl;
  final String fallbackText;
  final Color? backgroundColor;
  final bool showPresenceDot;

  const PresenceAvatarDirect({
    super.key,
    this.isOnline = false,
    required this.fallbackText,
    this.radius = 20,
    this.imageUrl,
    this.backgroundColor,
    this.showPresenceDot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isOnline ? 'Online' : 'Offline',
      waitDuration: const Duration(milliseconds: 500),
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor:
                backgroundColor ?? CommonColors.primary.withOpacity(0.1),
            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                ? NetworkImage(imageUrl!)
                : null,
            child: imageUrl == null || imageUrl!.isEmpty
                ? Text(
                    fallbackText.isNotEmpty
                        ? fallbackText.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: radius * 0.8,
                      fontWeight: FontWeight.bold,
                      color: CommonColors.primary,
                    ),
                  )
                : null,
          ),
          if (showPresenceDot)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: radius * 0.5,
                height: radius * 0.5,
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFF22C55E) // Green
                      : const Color(0xFF9CA3AF), // Gray
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: radius * 0.08,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
