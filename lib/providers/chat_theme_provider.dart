import 'dart:convert';
import 'package:flutter/material.dart';
import '../model/chat_theme_model.dart';
import '../services/local_storage_service.dart';

class ChatThemeProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService = LocalStorageService();
  late ChatTheme _currentTheme;
  Map<String, String> _conversationThemes = {};

  ChatTheme get currentTheme => _currentTheme;

  // Predefined Premium Themes (Categorized)
  static const List<ChatTheme> availableThemes = [
    // --- THEMES ---
    ChatTheme(
      id: 'default',
      name: 'Default (Blue)',
      category: ChatThemeCategory.color,
      primaryColor: Color(0xFF3B82F6),
      secondaryColor: Color(0xFFF1F5F9),
      backgroundColor: Colors.white,
      textColor: Color(0xFF1E293B),
      timestampColor: Color(0xFF64748B),
      statusIconColor: Color(0xFFFFB300), // Amber for visibility on blue
    ),
    ChatTheme(
      id: 'galaxy',
      name: 'Galaxy',
      category: ChatThemeCategory.theme,
      primaryColor: Color(0xFF6366F1),
      bubbleGradient: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
      secondaryColor: Color(0xFF334155),
      backgroundColor: Color(0xFF0F172A),
      backgroundType: ChatBackgroundType.gradient,
      backgroundGradient: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
      textColor: Colors.white,
      timestampColor: Color(0xFF94A3B8),
      statusIconColor: Color(0xFF4ADE80), // Bright Green for visibility
    ),
    ChatTheme(
      id: 'love',
      name: 'Love',
      category: ChatThemeCategory.theme,
      primaryColor: Color(0xFFEF4444),
      bubbleGradient: [Color(0xFFF43F5E), Color(0xFFEF4444)],
      secondaryColor: Color(0xFFFEE2E2),
      backgroundColor: Color(0xFFFFF1F2),
      textColor: Color(0xFF881337),
      timestampColor: Color(0xFFFB7185),
      statusIconColor: Color(0xFFFACC15), // Amber/Yellow for Love theme
    ),
    ChatTheme(
      id: 'tie_dye',
      name: 'Tie-dye',
      category: ChatThemeCategory.theme,
      primaryColor: Color(0xFFEC4899),
      bubbleGradient: [Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
      secondaryColor: Color(0xFFF0F9FF),
      backgroundColor: Color(0xFFFDF2F8),
      backgroundType: ChatBackgroundType.gradient,
      backgroundGradient: [Color(0xFFFDF2F8), Color(0xFFECFEFF)],
      textColor: Color(0xFF831843),
      timestampColor: Color(0xFFDB2777),
      statusIconColor: Color(0xFFFFCC00), // Distinct amber
    ),

    // --- GRADIENTS ---
    ChatTheme(
      id: 'synthwave',
      name: 'Synthwave',
      category: ChatThemeCategory.gradient,
      primaryColor: Color(0xFFD946EF),
      bubbleGradient: [Color(0xFFF02E65), Color(0xFFBC2CEF)],
      secondaryColor: Color(0xFF1E293B),
      backgroundColor: Color(0xFF020617),
      backgroundType: ChatBackgroundType.gradient,
      backgroundGradient: [Color(0xFF020617), Color(0xFF0F172A)],
      textColor: Colors.white,
      timestampColor: Color(0xFF94A3B8),
      statusIconColor: Color(0xFF00FFCC), // Neon cyan for synthwave
    ),
    ChatTheme(
      id: 'ocean_blue',
      name: 'Ocean',
      category: ChatThemeCategory.gradient,
      primaryColor: Color(0xFF0EA5E9),
      bubbleGradient: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
      secondaryColor: Color(0xFFF1F5F9),
      backgroundColor: Colors.white,
      backgroundType: ChatBackgroundType.gradient,
      backgroundGradient: [Color(0xFFE0F2FE), Colors.white],
      textColor: Color(0xFF0C4A6E),
      timestampColor: Color(0xFF0EA5E9),
      statusIconColor: Color(0xFFFACC15), // Amber for visibility on blue
    ),

    // --- COLORS ---

    ChatTheme(
      id: 'forest',
      name: 'Forest Green',
      category: ChatThemeCategory.color,
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFFECFDF5),
      backgroundColor: Color(0xFFF0FDF4),
      textColor: Color(0xFF064E3B),
      timestampColor: Color(0xFF6B7280),
      statusIconColor: Color(0xFFFFD600), // Yellow for visibility on green
    ),
  ];

  ChatThemeProvider() {
    _loadThemes();
  }

  void _loadThemes() {
    final savedThemeId = _localStorageService.chatTheme;
    _currentTheme = availableThemes.firstWhere(
      (theme) => theme.id == savedThemeId,
      orElse: () => availableThemes.first,
    );

    try {
      final jsonStr = _localStorageService.conversationThemes;
      _conversationThemes = Map<String, String>.from(jsonDecode(jsonStr));
    } catch (e) {
      _conversationThemes = {};
    }
    notifyListeners();
  }

  ChatTheme getThemeForConversation(String? conversationId) {
    if (conversationId == null) return _currentTheme;
    final themeId = _conversationThemes[conversationId];
    if (themeId == null) return _currentTheme;
    return availableThemes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => _currentTheme,
    );
  }

  Future<void> setTheme(String themeId) => setGlobalTheme(themeId);

  Future<void> setGlobalTheme(String themeId) async {
    _currentTheme = availableThemes.firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => availableThemes.first,
    );
    await _localStorageService.saveChatTheme(themeId);
    notifyListeners();
  }

  Future<void> setConversationTheme(
      String conversationId, String themeId) async {
    _conversationThemes[conversationId] = themeId;
    await _localStorageService
        .saveConversationThemes(jsonEncode(_conversationThemes));
    notifyListeners();
  }
}
