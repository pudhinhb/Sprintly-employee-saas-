import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;
import 'dart:async';

/// Service to manage fullscreen mode for web applications.
/// Uses the browser's Fullscreen API to enter and exit fullscreen mode.
class FullscreenService extends ChangeNotifier {
  static final FullscreenService _instance = FullscreenService._internal();

  factory FullscreenService() => _instance;

  FullscreenService._internal() {
    _initFullscreenListener();
  }

  bool _isFullscreen = false;
  StreamSubscription? _fullscreenChangeSubscription;

  /// Returns true if the app is currently in fullscreen mode
  bool get isFullscreen => _isFullscreen;

  /// Initialize listener for fullscreen change events
  void _initFullscreenListener() {
    if (kIsWeb) {
      // Listen for fullscreen change events from the browser
      _fullscreenChangeSubscription =
          html.document.onFullscreenChange.listen((_) {
        _updateFullscreenState();
      });

      // Also check initial state
      _updateFullscreenState();
    }
  }

  /// Update the fullscreen state based on the document's fullscreen element
  void _updateFullscreenState() {
    if (kIsWeb) {
      final isCurrentlyFullscreen = html.document.fullscreenElement != null;
      if (_isFullscreen != isCurrentlyFullscreen) {
        _isFullscreen = isCurrentlyFullscreen;
        notifyListeners();
      }
    }
  }

  /// Toggle fullscreen mode
  Future<void> toggleFullscreen() async {
    if (_isFullscreen) {
      await exitFullscreen();
    } else {
      await enterFullscreen();
    }
  }

  /// Enter fullscreen mode
  Future<void> enterFullscreen() async {
    if (kIsWeb) {
      try {
        html.document.documentElement?.requestFullscreen();
        _isFullscreen = true;
        notifyListeners();
      } catch (e) {
        debugPrint('Error entering fullscreen: $e');
      }
    }
  }

  /// Exit fullscreen mode
  Future<void> exitFullscreen() async {
    if (kIsWeb) {
      try {
        html.document.exitFullscreen();
        _isFullscreen = false;
        notifyListeners();
      } catch (e) {
        debugPrint('Error exiting fullscreen: $e');
      }
    }
  }

  /// Check if fullscreen is supported by the browser
  bool get isFullscreenSupported {
    if (kIsWeb) {
      return html.document.fullscreenEnabled ?? false;
    }
    return false;
  }

  @override
  void dispose() {
    _fullscreenChangeSubscription?.cancel();
    super.dispose();
  }
}
