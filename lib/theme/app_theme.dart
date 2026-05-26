import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color primaryBlue = Color(0xFF4285F4);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4285F4), Color(0xFF1967D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Color highPriority = Color(0xFFFB923C);
  static const Color mediumPriority = Color(0xFFFACC15);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color dangerRed = Color(0xFFDC2626);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF9FBFF);
  static const Color lightCardColor = Colors.white;
  static const Color lightAppBarColor = Colors.white;
  static const Color lightInputFill = Color(0xFFF3F4F6);

  // Dark Theme Colors
  // Dark Theme Colors - Premium Slate/Grey
  static const Color darkBackground =
      Color(0xFF111827); // Richer dark background
  static const Color darkCardColor =
      Color(0xFF1F2937); // Slightly lighter for cards
  static const Color darkAppBarColor = Color(0xFF111827); // Same as background
  static const Color darkInputFill = Color(0xFF374151); // Lighter for inputs

  // TeamSync / Chat widget color aliases
  static const Color primaryColor = primaryBlue;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color darkTextPrimary = Color(0xFFE2E8F0);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color surfaceColor = Colors.white;
  static const Color darkSurfaceColor = Color(0xFF1E293B);
  static const Color darkBorderColor = Color(0xFF334155);

  // Custom No Animation Builder
  static PageTransitionsBuilder get _noAnimationBuilder =>
      const _NoAnimationPageTransitionsBuilder();

  // Text Styles
  static TextTheme _buildTextTheme(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return TextTheme(
      // Headlines
      headlineLarge: GoogleFonts.lexend(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.lexend(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.lexend(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),

      // Titles
      titleLarge: GoogleFonts.lexend(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.lexend(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleSmall: GoogleFonts.lexend(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),

      // Body Text
      bodyLarge: GoogleFonts.lexend(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: bodyColor,
      ),
      bodyMedium: GoogleFonts.lexend(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: subtitleColor,
      ),
      bodySmall: GoogleFonts.lexend(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: subtitleColor,
      ),

      // Labels
      labelLarge: GoogleFonts.lexend(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelMedium: GoogleFonts.lexend(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: subtitleColor,
      ),
      labelSmall: GoogleFonts.lexend(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: subtitleColor,
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      brightness: Brightness.light,
      primary: primaryBlue,
      onPrimary: Colors.white,
      secondary: primaryBlue,
      onSecondary: Colors.white,
      surface: lightCardColor,
      onSurface: Colors.black,
      error: dangerRed,
      onError: Colors.white,
      background: lightBackground,
      onBackground: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _noAnimationBuilder,
          TargetPlatform.iOS: _noAnimationBuilder,
          TargetPlatform.linux: _noAnimationBuilder,
          TargetPlatform.macOS: _noAnimationBuilder,
          TargetPlatform.windows: _noAnimationBuilder,
        },
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: lightAppBarColor,
        foregroundColor: Colors.black,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.lexend(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: lightCardColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryBlue.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // Text Theme
      textTheme: _buildTextTheme(false),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: Colors.black54,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: lightInputFill,
        disabledColor: lightInputFill,
        selectedColor: primaryBlue,
        secondarySelectedColor: primaryBlue.withOpacity(0.12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightCardColor,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Scrollbar Theme (Web-specific)
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered)) {
            return primaryBlue.withOpacity(0.8);
          }
          return primaryBlue.withOpacity(0.4);
        }),
        trackColor: MaterialStateProperty.all(Colors.grey.withOpacity(0.1)),
        thickness: MaterialStateProperty.all(8.0),
        radius: const Radius.circular(4),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: primaryBlue,
      onPrimary: Colors.white,
      secondary: primaryBlue,
      onSecondary: Colors.white,
      surface: darkCardColor,
      onSurface: Colors.white,
      error: dangerRed,
      onError: Colors.white,
      background: darkBackground,
      onBackground: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _noAnimationBuilder,
          TargetPlatform.iOS: _noAnimationBuilder,
          TargetPlatform.linux: _noAnimationBuilder,
          TargetPlatform.macOS: _noAnimationBuilder,
          TargetPlatform.windows: _noAnimationBuilder,
        },
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkAppBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.lexend(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // Text Theme
      textTheme: _buildTextTheme(true),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: Colors.white70,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF374151),
        thickness: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: darkInputFill,
        disabledColor: darkInputFill,
        selectedColor: primaryBlue,
        secondarySelectedColor: primaryBlue.withOpacity(0.12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
        secondaryLabelStyle: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkCardColor,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Scrollbar Theme (Web-specific)
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered)) {
            return primaryBlue.withOpacity(0.8);
          }
          return primaryBlue.withOpacity(0.4);
        }),
        trackColor: MaterialStateProperty.all(Colors.grey.withOpacity(0.1)),
        thickness: MaterialStateProperty.all(8.0),
        radius: const Radius.circular(4),
      ),
    );
  }

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

  // Web-specific theme helpers
  static bool isWeb() {
    return identical(0, 0.0);
  }

  static double getWebScrollbarThickness() {
    return isWeb() ? 8.0 : 0.0;
  }

  static EdgeInsets getWebPadding(bool isDesktop) {
    if (!isWeb()) return EdgeInsets.zero;
    return EdgeInsets.symmetric(
      horizontal: isDesktop ? 24.0 : 16.0,
      vertical: isDesktop ? 16.0 : 12.0,
    );
  }

  static double getWebCardElevation(bool isDesktop) {
    if (!isWeb()) return 0.0;
    return isDesktop ? 2.0 : 1.0;
  }

  static BorderRadius getWebBorderRadius(bool isDesktop) {
    return BorderRadius.circular(isDesktop ? 12.0 : 8.0);
  }
}

class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
