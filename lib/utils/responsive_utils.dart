import 'package:flutter/material.dart';

/// Comprehensive responsive utility class for consistent design across all screen sizes.
///
/// Breakpoint tiers (width):
///   mobile     :   0 – 549
///   tablet     : 550 – 899
///   laptop     : 900 – 1399  (small‑laptop: 900–1023, laptop: 1024–1399)
///   desktop    : 1400 – 1920
///   4K         : 1921+
class ResponsiveUtils {
  // ── Screen size breakpoints ──────────────────────────────────────────
  static const double mobileBreakpoint = 550;
  static const double tabletBreakpoint = 900;
  static const double smallLaptopBreakpoint = 1024;
  static const double laptopBreakpoint = 1400;
  static const double desktopBreakpoint = 1920;

  // ── Core responsive size (all other helpers delegate here) ───────────
  static double getResponsiveSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
    double? laptop,
    double? fourK,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return fourK ?? desktop;
    } else if (width >= laptopBreakpoint) {
      return desktop;
    } else if (width >= tabletBreakpoint) {
      return laptop ?? tablet;
    } else if (width >= mobileBreakpoint) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // ── Responsive padding ──────────────────────────────────────────────
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
    EdgeInsets? laptop,
    EdgeInsets? fourK,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return fourK ?? desktop ?? const EdgeInsets.all(24);
    } else if (width >= laptopBreakpoint) {
      return desktop ?? const EdgeInsets.all(24);
    } else if (width >= tabletBreakpoint) {
      return laptop ?? tablet ?? const EdgeInsets.all(20);
    } else if (width >= mobileBreakpoint) {
      return tablet ?? const EdgeInsets.all(16);
    } else {
      return mobile ?? const EdgeInsets.all(12);
    }
  }

  // ── Responsive margin ───────────────────────────────────────────────
  static EdgeInsets getResponsiveMargin(
    BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
    EdgeInsets? laptop,
    EdgeInsets? fourK,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return fourK ?? desktop ?? const EdgeInsets.all(16);
    } else if (width >= laptopBreakpoint) {
      return desktop ?? const EdgeInsets.all(16);
    } else if (width >= tabletBreakpoint) {
      return laptop ?? tablet ?? const EdgeInsets.all(12);
    } else if (width >= mobileBreakpoint) {
      return tablet ?? const EdgeInsets.all(8);
    } else {
      return mobile ?? const EdgeInsets.all(4);
    }
  }

  // ── Responsive font size ────────────────────────────────────────────
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
    double? laptop,
    double? fourK,
  }) {
    return getResponsiveSize(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      laptop: laptop,
      fourK: fourK,
    );
  }

  // ── Responsive icon size ────────────────────────────────────────────
  static double getResponsiveIconSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
    double? laptop,
    double? fourK,
  }) {
    return getResponsiveSize(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      laptop: laptop,
      fourK: fourK,
    );
  }

  // ── Responsive spacing ──────────────────────────────────────────────
  static double getResponsiveSpacing(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
    double? laptop,
    double? fourK,
  }) {
    return getResponsiveSize(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      laptop: laptop,
      fourK: fourK,
    );
  }

  // ── Responsive border radius ────────────────────────────────────────
  static double getResponsiveBorderRadius(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
    double? laptop,
    double? fourK,
  }) {
    return getResponsiveSize(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      laptop: laptop,
      fourK: fourK,
    );
  }

  // ── Screen type detection ───────────────────────────────────────────
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Small laptop: 900 – 1023 (narrow laptop / large tablet territory)
  static bool isSmallLaptop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < smallLaptopBreakpoint;
  }

  /// Laptop: 900 – 1399 (everything between tablet and desktop)
  static bool isLaptop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < laptopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= laptopBreakpoint;
  }

  static bool isFourK(BuildContext context) {
    return MediaQuery.of(context).size.width > desktopBreakpoint;
  }

  /// Large desktop: > 1920
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > desktopBreakpoint;
  }

  // ── Responsive layout widget ────────────────────────────────────────
  static Widget responsiveLayout({
    required BuildContext context,
    required Widget mobile,
    required Widget tablet,
    required Widget desktop,
    Widget? laptop,
    Widget? fourK,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return fourK ?? desktop;
    } else if (width >= laptopBreakpoint) {
      return desktop;
    } else if (width >= tabletBreakpoint) {
      return laptop ?? tablet;
    } else if (width >= mobileBreakpoint) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // ── Responsive grid columns ─────────────────────────────────────────
  static int getResponsiveGridColumns(
    BuildContext context, {
    required int mobile,
    required int tablet,
    required int desktop,
    int? laptop,
    int? fourK,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return fourK ?? desktop;
    } else if (width >= laptopBreakpoint) {
      return desktop;
    } else if (width >= tabletBreakpoint) {
      return laptop ?? tablet;
    } else if (width >= mobileBreakpoint) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // ── Responsive aspect ratio ─────────────────────────────────────────
  static double getResponsiveAspectRatio(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
    double? laptop,
    double? fourK,
  }) {
    return getResponsiveSize(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      laptop: laptop,
      fourK: fourK,
    );
  }

  // ── Responsive card dimensions ──────────────────────────────────────
  static Size getResponsiveCardSize(
    BuildContext context, {
    required Size mobile,
    required Size tablet,
    required Size desktop,
    Size? laptop,
    Size? fourK,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return fourK ?? desktop;
    } else if (width >= laptopBreakpoint) {
      return desktop;
    } else if (width >= tabletBreakpoint) {
      return laptop ?? tablet;
    } else if (width >= mobileBreakpoint) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // ── Responsive button size ──────────────────────────────────────────
  static Size getResponsiveButtonSize(
    BuildContext context, {
    required Size mobile,
    required Size tablet,
    required Size desktop,
    Size? laptop,
    Size? fourK,
  }) {
    return getResponsiveCardSize(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      laptop: laptop,
      fourK: fourK,
    );
  }

  // ── Responsive image dimensions ─────────────────────────────────────
  static double getResponsiveImageDimension(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
    double? laptop,
    double? fourK,
  }) {
    return getResponsiveSize(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      laptop: laptop,
      fourK: fourK,
    );
  }

  // ── Responsive container constraints ────────────────────────────────
  static BoxConstraints getResponsiveConstraints(
    BuildContext context, {
    required BoxConstraints mobile,
    required BoxConstraints tablet,
    required BoxConstraints desktop,
    BoxConstraints? laptop,
    BoxConstraints? fourK,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return fourK ?? desktop;
    } else if (width >= laptopBreakpoint) {
      return desktop;
    } else if (width >= tabletBreakpoint) {
      return laptop ?? tablet;
    } else if (width >= mobileBreakpoint) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // ── Responsive flex factor ──────────────────────────────────────────
  static int getResponsiveFlex(
    BuildContext context, {
    required int mobile,
    required int tablet,
    required int desktop,
    int? laptop,
    int? fourK,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return fourK ?? desktop;
    } else if (width >= laptopBreakpoint) {
      return desktop;
    } else if (width >= tabletBreakpoint) {
      return laptop ?? tablet;
    } else if (width >= mobileBreakpoint) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // ── Responsive animation duration ───────────────────────────────────
  static Duration getResponsiveDuration(
    BuildContext context, {
    required Duration mobile,
    required Duration tablet,
    required Duration desktop,
    Duration? laptop,
    Duration? fourK,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return fourK ?? desktop;
    } else if (width >= laptopBreakpoint) {
      return desktop;
    } else if (width >= tabletBreakpoint) {
      return laptop ?? tablet;
    } else if (width >= mobileBreakpoint) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // ── Responsive shadow ───────────────────────────────────────────────
  static List<BoxShadow> getResponsiveShadow(
    BuildContext context, {
    required List<BoxShadow> mobile,
    required List<BoxShadow> tablet,
    required List<BoxShadow> desktop,
    List<BoxShadow>? laptop,
    List<BoxShadow>? fourK,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return fourK ?? desktop;
    } else if (width >= laptopBreakpoint) {
      return desktop;
    } else if (width >= tabletBreakpoint) {
      return laptop ?? tablet;
    } else if (width >= mobileBreakpoint) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // ── Responsive gradient stops ───────────────────────────────────────
  static List<double> getResponsiveGradientStops(
    BuildContext context, {
    required List<double> mobile,
    required List<double> tablet,
    required List<double> desktop,
    List<double>? laptop,
    List<double>? fourK,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return fourK ?? desktop;
    } else if (width >= laptopBreakpoint) {
      return desktop;
    } else if (width >= tabletBreakpoint) {
      return laptop ?? tablet;
    } else if (width >= mobileBreakpoint) {
      return tablet;
    } else {
      return mobile;
    }
  }
}
