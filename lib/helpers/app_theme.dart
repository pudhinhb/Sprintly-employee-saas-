import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFFF3F7FF),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF0F172A)),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 2,
      shadowColor: const Color(0xFF94A3B8).withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge:
          TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
      displayMedium:
          TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
      displaySmall:
          TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
      headlineLarge:
          TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
      headlineMedium:
          TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
      headlineSmall:
          TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
      titleLarge:
          TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
      titleMedium:
          TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
      titleSmall:
          TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: Color(0xFF475569)),
      bodyMedium: TextStyle(color: Color(0xFF475569)),
      bodySmall: TextStyle(color: Color(0xFF94A3B8)),
      labelLarge: TextStyle(color: Color(0xFF0F172A)),
      labelMedium: TextStyle(color: Color(0xFF475569)),
      labelSmall: TextStyle(color: Color(0xFF94A3B8)),
    ),

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0F172A),
      secondary: Color(0xFF38BDF8),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFF3F7FF),
      error: Color(0xFFFF4C4C),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF0F172A),
      onBackground: Color(0xFF0F172A),
      onError: Colors.white,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0xFF94A3B8).withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );

  // Dark Theme Colors
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF0F172A),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Color(0xFFE2E8F0),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFFE2E8F0)),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge:
          TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.bold),
      displayMedium:
          TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.bold),
      displaySmall:
          TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.bold),
      headlineLarge:
          TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
      headlineMedium:
          TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
      headlineSmall:
          TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
      titleLarge:
          TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w500),
      titleMedium:
          TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w500),
      titleSmall:
          TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: Color(0xFFCBD5E1)),
      bodyMedium: TextStyle(color: Color(0xFFCBD5E1)),
      bodySmall: TextStyle(color: Color(0xFF94A3B8)),
      labelLarge: TextStyle(color: Color(0xFFE2E8F0)),
      labelMedium: TextStyle(color: Color(0xFFCBD5E1)),
      labelSmall: TextStyle(color: Color(0xFF94A3B8)),
    ),

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF38BDF8),
      secondary: Color(0xFF0EA5E9),
      surface: Color(0xFF1E293B),
      background: Color(0xFF0F172A),
      error: Color(0xFFFF4C4C),
      onPrimary: Color(0xFF0F172A),
      onSecondary: Colors.white,
      onSurface: Color(0xFFE2E8F0),
      onBackground: Color(0xFFE2E8F0),
      onError: Colors.white,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF334155),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF38BDF8),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}

class ThemeColors {
  static Color primary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color secondary(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color background(BuildContext context) {
    return Theme.of(context).colorScheme.background;
  }

  static Color error(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  static Color onPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }

  static Color onSecondary(BuildContext context) {
    return Theme.of(context).colorScheme.onSecondary;
  }

  static Color onSurface(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color onBackground(BuildContext context) {
    return Theme.of(context).colorScheme.onBackground;
  }

  static Color onError(BuildContext context) {
    return Theme.of(context).colorScheme.onError;
  }

  // Status colors that work in both themes
  static const Color success = Color(0xFF28C76F);
  static const Color warning = Color(0xFFFF8A00);
  static const Color info = Color(0xFF38BDF8);

  // Gradient colors for 3D effects
  static List<Color> primaryGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        const Color(0xFF38BDF8),
        const Color(0xFF0EA5E9),
      ];
    }
    return [
      const Color(0xFF0F172A),
      const Color(0xFF334155),
    ];
  }

  static List<Color> surfaceGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        const Color(0xFF1E293B),
        const Color(0xFF334155),
      ];
    }
    return [
      const Color(0xFFFFFFFF),
      const Color(0xFFF3F7FF),
    ];
  }

  static Color shadowColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.black.withOpacity(0.5)
        : const Color(0xFF94A3B8).withOpacity(0.3);
  }
}
