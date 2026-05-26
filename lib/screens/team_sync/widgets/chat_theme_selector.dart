import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../model/chat_theme_model.dart';
import '../../../providers/chat_theme_provider.dart';
import '../../../services/chat_repository.dart';

/// A beautiful theme selector widget for chat customization
/// Shows as side sheet on desktop, bottom sheet on mobile
class ChatThemeSelector extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onClose;
  final VoidCallback? onApply;
  final String?
      conversationId; // Optional: save theme to backend for this conversation

  const ChatThemeSelector({
    super.key,
    required this.isDark,
    this.onClose,
    this.onApply,
    this.conversationId,
  });

  @override
  State<ChatThemeSelector> createState() => _ChatThemeSelectorState();
}

class _ChatThemeSelectorState extends State<ChatThemeSelector> {
  ChatTheme? _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = context.read<ChatThemeProvider>().currentTheme;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ChatThemeProvider>();
    final currentTheme = themeProvider.currentTheme;
    final themeToPreview = _selectedTheme ?? currentTheme;

    final surfaceColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDark ? Colors.white12 : Colors.grey.shade200;
    final primaryTextColor = widget.isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = widget.isDark ? Colors.white60 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          left: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.palette_rounded,
                    color: themeToPreview.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat Theme',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        'Customize your chat appearance',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close, color: secondaryTextColor),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Theme Selection Grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Theme',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Theme Grid
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: ChatThemeProvider.availableThemes.map((theme) {
                      final isSelected = themeToPreview.id == theme.id;
                      return _ThemeCard(
                        theme: theme,
                        isDark: widget.isDark,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedTheme = theme),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Preview Section
                  Text(
                    'Preview',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildPreview(themeToPreview),
                ],
              ),
            ),
          ),

          // Footer with buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                top: BorderSide(color: borderColor, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Clear/Reset Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _selectedTheme =
                          ChatThemeProvider.availableThemes.first);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      'Reset',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondaryTextColor,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Apply Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_selectedTheme != null) {
                        // Save locally via Provider
                        final provider = context.read<ChatThemeProvider>();
                        await provider.setTheme(_selectedTheme!.id);

                        // Save to backend if conversationId is provided
                        if (widget.conversationId != null) {
                          final chatRepo = ChatRepository();
                          await chatRepo.updateConversationTheme(
                            conversationId: widget.conversationId!,
                            themeId: _selectedTheme!.id,
                          );
                        }
                      }
                      widget.onApply?.call();
                      widget.onClose?.call();
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      'Apply Theme',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeToPreview.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ChatTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Other person's message
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'J',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.secondaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    'Hey! How are you doing today? 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // My message
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                "I'm doing great! Thanks for asking 🎉",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual theme card widget
class _ThemeCard extends StatelessWidget {
  final ChatTheme theme;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color Preview Circles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.secondaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Theme name
            Text(
              theme.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? theme.primaryColor
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: theme.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Show theme selector as a side sheet for desktop
Future<void> showChatThemeSelector(BuildContext context, bool isDark,
    {String? conversationId}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, _, __) => Align(
      alignment: Alignment.centerRight,
      child: Material(
        elevation: 16,
        color: Colors.transparent,
        child: SizedBox(
          width: 380,
          height: double.infinity,
          child: ChatThemeSelector(
            isDark: isDark,
            conversationId: conversationId,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

/// Show theme selector as a bottom sheet for mobile
Future<void> showChatThemeSelectorSheet(BuildContext context, bool isDark,
    {String? conversationId}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ChatThemeSelector(
        isDark: isDark,
        conversationId: conversationId,
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    ),
  );
}
