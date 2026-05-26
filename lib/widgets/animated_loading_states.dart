import 'package:flutter/material.dart';
import 'package:webnox_taskops/helpers/common_colors.dart';

class SkeletonLoader extends StatefulWidget {
  final double height;
  final double width;
  final double borderRadius;
  final Color? color;

  const SkeletonLoader({
    super.key,
    this.height = 20,
    this.width = double.infinity,
    this.borderRadius = 4,
    this.color,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                widget.color ??
                    (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : Colors.grey[300]!),
                widget.color?.withOpacity(0.6) ??
                    (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[600]!
                        : Colors.grey[100]!),
                widget.color ??
                    (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : Colors.grey[300]!),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TaskCardSkeleton extends StatelessWidget {
  final bool isMobile;
  final bool isSmallMobile;

  const TaskCardSkeleton({
    super.key,
    this.isMobile = false,
    this.isSmallMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isSmallMobile
            ? 6
            : isMobile
                ? 8
                : 10,
        horizontal: isSmallMobile
            ? 4
            : isMobile
                ? 6
                : 8,
      ),
      padding: EdgeInsets.all(isSmallMobile
          ? 12
          : isMobile
              ? 14
              : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isSmallMobile
            ? 8
            : isMobile
                ? 10
                : 12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title skeleton
          SkeletonLoader(
            height: isSmallMobile
                ? 16
                : isMobile
                    ? 18
                    : 20,
            width: double.infinity,
            borderRadius: 4,
          ),
          SizedBox(
              height: isSmallMobile
                  ? 8
                  : isMobile
                      ? 10
                      : 12),

          // Description skeleton
          SkeletonLoader(
            height: isSmallMobile
                ? 12
                : isMobile
                    ? 14
                    : 16,
            width: MediaQuery.of(context).size.width * 0.7,
            borderRadius: 4,
          ),
          SizedBox(
              height: isSmallMobile
                  ? 8
                  : isMobile
                      ? 10
                      : 12),

          // Bottom row with status and buttons
          Row(
            children: [
              // Status skeleton
              SkeletonLoader(
                height: isSmallMobile
                    ? 20
                    : isMobile
                        ? 24
                        : 28,
                width: isSmallMobile
                    ? 60
                    : isMobile
                        ? 70
                        : 80,
                borderRadius: isSmallMobile
                    ? 10
                    : isMobile
                        ? 12
                        : 14,
              ),
              const Spacer(),
              // Button skeletons
              SkeletonLoader(
                height: isSmallMobile
                    ? 28
                    : isMobile
                        ? 32
                        : 36,
                width: isSmallMobile
                    ? 60
                    : isMobile
                        ? 70
                        : 80,
                borderRadius: isSmallMobile
                    ? 6
                    : isMobile
                        ? 8
                        : 10,
              ),
              SizedBox(
                  width: isSmallMobile
                      ? 6
                      : isMobile
                          ? 8
                          : 10),
              SkeletonLoader(
                height: isSmallMobile
                    ? 28
                    : isMobile
                        ? 32
                        : 36,
                width: isSmallMobile
                    ? 60
                    : isMobile
                        ? 70
                        : 80,
                borderRadius: isSmallMobile
                    ? 6
                    : isMobile
                        ? 8
                        : 10,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmployeeCardSkeleton extends StatelessWidget {
  final bool isMobile;
  final bool isSmallMobile;

  const EmployeeCardSkeleton({
    super.key,
    this.isMobile = false,
    this.isSmallMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isSmallMobile
            ? 6
            : isMobile
                ? 8
                : 10,
        horizontal: isSmallMobile
            ? 4
            : isMobile
                ? 6
                : 8,
      ),
      padding: EdgeInsets.all(isSmallMobile
          ? 12
          : isMobile
              ? 14
              : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isSmallMobile
            ? 8
            : isMobile
                ? 10
                : 12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar skeleton
          SkeletonLoader(
            height: isSmallMobile
                ? 40
                : isMobile
                    ? 45
                    : 50,
            width: isSmallMobile
                ? 40
                : isMobile
                    ? 45
                    : 50,
            borderRadius: 25,
          ),
          SizedBox(
              width: isSmallMobile
                  ? 12
                  : isMobile
                      ? 14
                      : 16),

          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name skeleton
                SkeletonLoader(
                  height: isSmallMobile
                      ? 16
                      : isMobile
                          ? 18
                          : 20,
                  width: MediaQuery.of(context).size.width * 0.4,
                  borderRadius: 4,
                ),
                SizedBox(
                    height: isSmallMobile
                        ? 6
                        : isMobile
                            ? 8
                            : 10),

                // Role skeleton
                SkeletonLoader(
                  height: isSmallMobile
                      ? 20
                      : isMobile
                          ? 24
                          : 28,
                  width: MediaQuery.of(context).size.width * 0.3,
                  borderRadius: isSmallMobile
                      ? 10
                      : isMobile
                          ? 12
                          : 14,
                ),
                SizedBox(
                    height: isSmallMobile
                        ? 6
                        : isMobile
                            ? 8
                            : 10),

                // Phone skeleton
                SkeletonLoader(
                  height: isSmallMobile
                      ? 12
                      : isMobile
                          ? 14
                          : 16,
                  width: MediaQuery.of(context).size.width * 0.35,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MetricCardSkeleton extends StatelessWidget {
  final bool isMobile;
  final bool isSmallMobile;

  const MetricCardSkeleton({
    super.key,
    this.isMobile = false,
    this.isSmallMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile
          ? 16
          : isMobile
              ? 18
              : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isSmallMobile
            ? 8
            : isMobile
                ? 10
                : 12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallCard = constraints.maxHeight < 100;
          final iconHeight = isSmallCard
              ? (isSmallMobile
                  ? 24.0
                  : isMobile
                      ? 28.0
                      : 28.0) // Reduced max to 28
              : (isSmallMobile
                  ? 32.0
                  : isMobile
                      ? 36.0
                      : 40.0);
          final iconWidth = iconHeight;
          final spacing1 = isSmallCard
              ? (isSmallMobile
                  ? 4.0
                  : isMobile
                      ? 6.0
                      : 6.0) // Reduced max to 6
              : (isSmallMobile
                  ? 8.0
                  : isMobile
                      ? 10.0
                      : 12.0);
          final valueHeight = isSmallCard
              ? (isSmallMobile
                  ? 16.0
                  : isMobile
                      ? 18.0
                      : 18.0) // Reduced max to 18
              : (isSmallMobile
                  ? 20.0
                  : isMobile
                      ? 22.0
                      : 24.0);
          final spacing2 = isSmallCard
              ? (isSmallMobile
                  ? 2.0
                  : isMobile
                      ? 3.0
                      : 3.0) // Reduced max to 3
              : (isSmallMobile
                  ? 4.0
                  : isMobile
                      ? 6.0
                      : 8.0);
          final labelHeight = isSmallCard
              ? (isSmallMobile
                  ? 12.0
                  : isMobile
                      ? 14.0
                      : 12.0) // Reduced max to 12
              : (isSmallMobile
                  ? 14.0
                  : isMobile
                      ? 16.0
                      : 18.0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon skeleton
              SkeletonLoader(
                height: iconHeight,
                width: iconWidth,
                borderRadius: 8,
              ),
              SizedBox(height: spacing1),

              // Value skeleton
              SkeletonLoader(
                height: valueHeight,
                width: MediaQuery.of(context).size.width * 0.15,
                borderRadius: 4,
              ),
              SizedBox(height: spacing2),

              // Label skeleton
              Flexible(
                child: SkeletonLoader(
                  height: labelHeight,
                  width: MediaQuery.of(context).size.width * 0.2,
                  borderRadius: 4,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class EnhancedLoadingIndicator extends StatelessWidget {
  final String message;
  final bool showSpinner;
  final Color? color;
  final double size;

  const EnhancedLoadingIndicator({
    super.key,
    this.message = 'Loading...',
    this.showSpinner = true,
    this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showSpinner) ...[
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? CommonColors.primary,
                ),
                strokeWidth: size * 0.1,
              ),
            ),
            SizedBox(height: size * 0.4),
          ],
          Text(
            message,
            style: TextStyle(
              fontSize: size * 0.4,
              color: color ?? CommonColors.primary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PullToRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;

  const PullToRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? CommonColors.primary,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      child: child,
    );
  }
}

class IPhoneLoadingIndicator extends StatelessWidget {
  final String message;
  final bool showSpinner;
  final Color? color;
  final double size;
  final bool isDarkMode;

  const IPhoneLoadingIndicator({
    super.key,
    this.message = 'Loading...',
    this.showSpinner = true,
    this.color,
    this.size = 40,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showSpinner) ...[
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? theme.colorScheme.primary,
                  ),
                  strokeWidth: size * 0.08,
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ScreenLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String message;
  final Widget child;
  final Color? backgroundColor;
  final double opacity;

  const ScreenLoadingOverlay({
    super.key,
    required this.isLoading,
    this.message = 'Loading...',
    required this.child,
    this.backgroundColor,
    this.opacity = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: (backgroundColor ?? Theme.of(context).colorScheme.surface)
                .withOpacity(opacity),
            child: IPhoneLoadingIndicator(
              message: message,
              showSpinner: true,
              size: 48,
            ),
          ),
      ],
    );
  }
}

class ShimmerLoadingCard extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const ShimmerLoadingCard({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.borderRadius = 12,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      padding: padding ?? const EdgeInsets.all(16),
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: SkeletonLoader(
        height: height - 32,
        width: double.infinity,
        borderRadius: borderRadius - 4,
        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
      ),
    );
  }
}

class ListLoadingSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets? itemMargin;
  final EdgeInsets? itemPadding;

  const ListLoadingSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.itemMargin,
    this.itemPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerLoadingCard(
          height: itemHeight,
          margin: itemMargin,
          padding: itemPadding,
        );
      },
    );
  }
}

class GridLoadingSkeleton extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  final double itemHeight;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const GridLoadingSkeleton({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 6,
    this.itemHeight = 120,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerLoadingCard(
          height: itemHeight,
          borderRadius: 12,
        );
      },
    );
  }
}
