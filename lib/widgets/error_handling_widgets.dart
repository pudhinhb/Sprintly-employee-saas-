import 'package:flutter/material.dart';
import 'package:webnox_taskops/helpers/common_colors.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? icon;
  final bool showRetry;
  final VoidCallback? onRetry;
  final bool isMobile;
  final bool isSmallMobile;

  const ErrorDisplayWidget({
    super.key,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.icon,
    this.showRetry = false,
    this.onRetry,
    this.isMobile = false,
    this.isSmallMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallMobile
            ? 16
            : isMobile
                ? 20
                : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon
            Container(
              padding: EdgeInsets.all(isSmallMobile
                  ? 16
                  : isMobile
                      ? 20
                      : 24),
              decoration: BoxDecoration(
                color: CommonColors.dangerRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: isSmallMobile
                    ? 48
                    : isMobile
                        ? 56
                        : 64,
                color: CommonColors.dangerRed,
              ),
            ),

            SizedBox(
                height: isSmallMobile
                    ? 16
                    : isMobile
                        ? 20
                        : 24),

            // Error Title
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallMobile
                    ? 18
                    : isMobile
                        ? 20
                        : 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(
                height: isSmallMobile
                    ? 8
                    : isMobile
                        ? 12
                        : 16),

            // Error Message
            Text(
              message,
              style: TextStyle(
                fontSize: isSmallMobile
                    ? 14
                    : isMobile
                        ? 16
                        : 18,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(
                height: isSmallMobile
                    ? 20
                    : isMobile
                        ? 24
                        : 32),

            // Action Buttons
            if (showRetry || onAction != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showRetry)
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: isSmallMobile
                              ? 14
                              : isMobile
                                  ? 16
                                  : 18,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CommonColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallMobile
                              ? 16
                              : isMobile
                                  ? 20
                                  : 24,
                          vertical: isSmallMobile
                              ? 10
                              : isMobile
                                  ? 12
                                  : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isSmallMobile
                                ? 6
                                : isMobile
                                    ? 8
                                    : 10,
                          ),
                        ),
                      ),
                    ),
                  if (showRetry && onAction != null)
                    SizedBox(
                        width: isSmallMobile
                            ? 12
                            : isMobile
                                ? 16
                                : 20),
                  if (onAction != null)
                    ElevatedButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.settings, size: 18),
                      label: Text(
                        actionText ?? 'Settings',
                        style: TextStyle(
                          fontSize: isSmallMobile
                              ? 14
                              : isMobile
                                  ? 16
                                  : 18,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[800],
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallMobile
                              ? 16
                              : isMobile
                                  ? 20
                                  : 24,
                          vertical: isSmallMobile
                              ? 10
                              : isMobile
                                  ? 12
                                  : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isSmallMobile
                                ? 6
                                : isMobile
                                    ? 8
                                    : 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final bool isMobile;
  final bool isSmallMobile;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.isMobile = false,
    this.isSmallMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorDisplayWidget(
      title: 'Network Error',
      message:
          'Unable to connect to the server. Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      showRetry: true,
      onRetry: onRetry,
      isMobile: isMobile,
      isSmallMobile: isSmallMobile,
    );
  }
}

class DataNotFoundWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRefresh;
  final bool isMobile;
  final bool isSmallMobile;

  const DataNotFoundWidget({
    super.key,
    this.message = 'No data found',
    this.onRefresh,
    this.isMobile = false,
    this.isSmallMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorDisplayWidget(
      title: 'No Data Found',
      message: message,
      icon: Icons.inbox_outlined,
      showRetry: onRefresh != null,
      onRetry: onRefresh,
      isMobile: isMobile,
      isSmallMobile: isSmallMobile,
    );
  }
}

class PermissionErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onSettings;
  final bool isMobile;
  final bool isSmallMobile;

  const PermissionErrorWidget({
    super.key,
    this.message = 'You don\'t have permission to access this feature.',
    this.onSettings,
    this.isMobile = false,
    this.isSmallMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorDisplayWidget(
      title: 'Permission Denied',
      message: message,
      icon: Icons.lock_outline,
      actionText: 'Contact Admin',
      onAction: onSettings,
      isMobile: isMobile,
      isSmallMobile: isSmallMobile,
    );
  }
}

class ServerErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isMobile;
  final bool isSmallMobile;

  const ServerErrorWidget({
    super.key,
    this.message = 'Something went wrong on our end. Please try again later.',
    this.onRetry,
    this.isMobile = false,
    this.isSmallMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorDisplayWidget(
      title: 'Server Error',
      message: message,
      icon: Icons.cloud_off,
      showRetry: true,
      onRetry: onRetry,
      isMobile: isMobile,
      isSmallMobile: isSmallMobile,
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final bool isMobile;
  final bool isSmallMobile;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionText,
    this.onAction,
    this.isMobile = false,
    this.isSmallMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallMobile
            ? 16
            : isMobile
                ? 20
                : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty State Icon
            Container(
              padding: EdgeInsets.all(isSmallMobile
                  ? 16
                  : isMobile
                      ? 20
                      : 24),
              decoration: BoxDecoration(
                color: CommonColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: isSmallMobile
                    ? 48
                    : isMobile
                        ? 56
                        : 64,
                color: CommonColors.primary,
              ),
            ),

            SizedBox(
                height: isSmallMobile
                    ? 16
                    : isMobile
                        ? 20
                        : 24),

            // Empty State Title
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallMobile
                    ? 18
                    : isMobile
                        ? 20
                        : 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(
                height: isSmallMobile
                    ? 8
                    : isMobile
                        ? 12
                        : 16),

            // Empty State Message
            Text(
              message,
              style: TextStyle(
                fontSize: isSmallMobile
                    ? 14
                    : isMobile
                        ? 16
                        : 18,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            if (onAction != null) ...[
              SizedBox(
                  height: isSmallMobile
                      ? 20
                      : isMobile
                          ? 24
                          : 32),

              // Action Button
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  actionText ?? 'Get Started',
                  style: TextStyle(
                    fontSize: isSmallMobile
                        ? 14
                        : isMobile
                            ? 16
                            : 18,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CommonColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile
                        ? 20
                        : isMobile
                            ? 24
                            : 28,
                    vertical: isSmallMobile
                        ? 12
                        : isMobile
                            ? 14
                            : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      isSmallMobile
                          ? 8
                          : isMobile
                              ? 10
                              : 12,
                    ),
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

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }

      return ErrorDisplayWidget(
        title: 'Something went wrong',
        message: 'An unexpected error occurred. Please try restarting the app.',
        icon: Icons.bug_report,
        showRetry: true,
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }

    return widget.child;
  }
}
