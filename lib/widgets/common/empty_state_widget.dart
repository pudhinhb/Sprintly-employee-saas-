import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../helpers/common_colors.dart';
import '../../utils/responsive_utils.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double? size;
  final double? fontSize;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.size,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/empty_box.json',
              width: size ??
                  ResponsiveUtils.getResponsiveSize(
                    context,
                    mobile: 200,
                    tablet: 220,
                    desktop: 250,
                  ),
              height: size ??
                  ResponsiveUtils.getResponsiveSize(
                    context,
                    mobile: 200,
                    tablet: 220,
                    desktop: 250,
                  ),
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: CommonColors.getTextColor(context),
                fontSize: fontSize ??
                    ResponsiveUtils.getResponsiveFontSize(context,
                        mobile: 16, tablet: 18, desktop: 20),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  color: CommonColors.getSecondaryTextColor(context),
                  fontSize: (fontSize ??
                          ResponsiveUtils.getResponsiveFontSize(context,
                              mobile: 16, tablet: 18, desktop: 20)) -
                      2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
