import 'package:flutter/material.dart';

class CommonColors {
  // Primary Color Palette
  static const Color primary = Color(0xFF4285F4); // Primary Blue
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4285F4), Color(0xFF1967D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Color highPriority = Color(0xFFFB923C); // High Priority Orange
  static const Color mediumPriority =
      Color(0xFFFACC15); // Medium Priority Yellow
  static const Color successGreen = Color(0xFF22C55E); // Success Green
  static const Color dangerRed = Color(0xFFDC2626); // Danger Red

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightCardColor = Colors.white;
  static const Color lightAppBarColor = Colors.white;
  static const Color lightInputFill = Color(0xFFF3F4F6);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0E0E0E);
  static const Color darkCardColor = Color(0xFF1C1C1E);
  static const Color darkAppBarColor = Color(0xFF121212);
  static const Color darkInputFill = Color(0xFF1C1C1E);

  // Legacy Support - Dynamic colors based on context
  static Color get backgroundColor => lightBackground;
  static Color get cardBackground => lightCardColor;
  static Color get sidebarBackground => lightBackground;
  static Color get inputBackground => lightInputFill;

  // Text Colors
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black87;
  static const Color textTertiary = Colors.black54;

  // Status Colors (updated to match new palette)
  static const Color error = dangerRed;
  static const Color success = successGreen;
  static const Color warning = highPriority;
  static const Color info = primary;

  // Priority Colors (updated)
  static const Color priorityHigh = dangerRed;
  static const Color priorityMedium = highPriority;
  static const Color priorityLow = successGreen;

  // Legacy colors for backward compatibility
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static Color get lightPrimary => primary.withOpacity(0.2);
  static const Color skyBlue = Color(0xFFE0F2FE);
  static const Color transparent = Colors.transparent;
  static const Color textButtonBg = Color(0xFFF1F5F9);
  static const Color textButtonText = Color(0xFF1E293B);

  // Additional colors for modern dashboard
  static const Color accent = Color(0xFF3B82F6);
  static const Color darkSidebar = Color(0xFF0F0F0F);
  static const Color darkCard = Color(0xFF121212);
  static const Color darkInput = Color(0xFF1A1A1A);
  static const Color darkShadow = Color(0xFF000000);
  static const Color cardShadow = Color(0xFF1E293B);

  // Status colors (consistent with new palette)
  static const Color red = dangerRed;
  static const Color green = successGreen;
  static const Color orange = highPriority;
  static const Color blue = primary;
  static const Color yellow = mediumPriority;
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);
  static const Color teal = Color(0xFF14B8A6);
  static const Color indigo = Color(0xFF6366F1);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color lime = Color(0xFF84CC16);
  static const Color amber = Color(0xFFF59E0B);
  static const Color brown = Color(0xFFA3A3A3);

  // Helper methods for priority colors
  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 3:
        return dangerRed;
      case 2:
        return highPriority;
      case 1:
        return mediumPriority;
      default:
        return successGreen;
    }
  }

  static String getPriorityText(int priority) {
    switch (priority) {
      case 3:
        return 'High';
      case 2:
        return 'Medium';
      case 1:
        return 'Low';
      default:
        return 'Normal';
    }
  }

  // Theme-aware colors (for use with context)
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardColor
        : lightCardColor;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
  }
}
