import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webnox_taskops/services/fullscreen_service.dart';
import 'package:webnox_taskops/helpers/common_colors.dart';

/// A toggle button widget for entering and exiting fullscreen mode.
/// Only visible on web platforms where fullscreen is supported.
class FullscreenToggleButton extends StatefulWidget {
  /// Optional custom icon size
  final double? iconSize;

  /// Optional custom icon color
  final Color? iconColor;

  /// Whether to show a border around the button
  final bool showBorder;

  /// Optional callback when fullscreen state changes
  final VoidCallback? onToggle;

  const FullscreenToggleButton({
    super.key,
    this.iconSize,
    this.iconColor,
    this.showBorder = false,
    this.onToggle,
  });

  @override
  State<FullscreenToggleButton> createState() => _FullscreenToggleButtonState();
}

class _FullscreenToggleButtonState extends State<FullscreenToggleButton> {
  final FullscreenService _fullscreenService = FullscreenService();

  @override
  void initState() {
    super.initState();
    _fullscreenService.addListener(_onFullscreenChange);
  }

  @override
  void dispose() {
    _fullscreenService.removeListener(_onFullscreenChange);
    super.dispose();
  }

  void _onFullscreenChange() {
    if (mounted) {
      setState(() {});
      widget.onToggle?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show on web platform where fullscreen is supported
    if (!kIsWeb || !_fullscreenService.isFullscreenSupported) {
      return const SizedBox.shrink();
    }

    final iconColor = widget.iconColor ?? CommonColors.getTextColor(context);
    final iconSize = widget.iconSize ?? 24.0;

    final button = IconButton(
      onPressed: () async {
        await _fullscreenService.toggleFullscreen();
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: Icon(
          _fullscreenService.isFullscreen
              ? Icons.fullscreen_exit
              : Icons.fullscreen,
          key: ValueKey(_fullscreenService.isFullscreen),
          color: iconColor,
          size: iconSize,
        ),
      ),
      tooltip: _fullscreenService.isFullscreen
          ? 'Exit Fullscreen (Esc)'
          : 'Enter Fullscreen',
    );

    if (widget.showBorder) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: iconColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: button,
      );
    }

    return button;
  }
}

/// A compact version of the fullscreen toggle button
class CompactFullscreenToggle extends StatefulWidget {
  final double? size;
  final Color? color;
  final VoidCallback? onPressed;

  const CompactFullscreenToggle({
    super.key,
    this.size,
    this.color,
    this.onPressed,
  });

  @override
  State<CompactFullscreenToggle> createState() =>
      _CompactFullscreenToggleState();
}

class _CompactFullscreenToggleState extends State<CompactFullscreenToggle> {
  final FullscreenService _fullscreenService = FullscreenService();

  @override
  void initState() {
    super.initState();
    _fullscreenService.addListener(_onFullscreenChange);
  }

  @override
  void dispose() {
    _fullscreenService.removeListener(_onFullscreenChange);
    super.dispose();
  }

  void _onFullscreenChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show on web platform where fullscreen is supported
    if (!kIsWeb || !_fullscreenService.isFullscreenSupported) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: () async {
        await _fullscreenService.toggleFullscreen();
        widget.onPressed?.call();
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          _fullscreenService.isFullscreen
              ? Icons.fullscreen_exit
              : Icons.fullscreen,
          key: ValueKey(_fullscreenService.isFullscreen),
          color: widget.color ?? Theme.of(context).colorScheme.onSurface,
          size: widget.size ?? 24,
        ),
      ),
      tooltip: _fullscreenService.isFullscreen
          ? 'Exit Fullscreen (Esc)'
          : 'Enter Fullscreen',
    );
  }
}
