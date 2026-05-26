import 'package:flutter/material.dart';

enum ChatThemeCategory { theme, gradient, color }

enum ChatBackgroundType { color, gradient, image }

class ChatTheme {
  final String id;
  final String name;
  final ChatThemeCategory category;
  final Color primaryColor; // My message bubble fallback
  final List<Color>? bubbleGradient; // My message bubble gradient
  final Color secondaryColor; // Other message bubble fallback
  final List<Color>? secondaryBubbleGradient; // Other message bubble gradient
  final Color backgroundColor; // Screen background fallback
  final ChatBackgroundType backgroundType;
  final List<Color>? backgroundGradient; // Optional gradient for background
  final String? backgroundImage; // Optional background pattern/image asset path
  final Color textColor; // Text color on background
  final Color timestampColor; // Time text color
  final Color statusIconColor; // Status icon color (ticks)

  const ChatTheme({
    required this.id,
    required this.name,
    this.category = ChatThemeCategory.theme,
    required this.primaryColor,
    this.bubbleGradient,
    required this.secondaryColor,
    this.secondaryBubbleGradient,
    required this.backgroundColor,
    this.backgroundType = ChatBackgroundType.color,
    this.backgroundGradient,
    this.backgroundImage,
    required this.textColor,
    required this.timestampColor,
    required this.statusIconColor,
  });
}
