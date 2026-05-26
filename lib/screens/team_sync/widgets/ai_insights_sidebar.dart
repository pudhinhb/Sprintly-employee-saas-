import 'package:flutter/material.dart';
import '../../../helpers/common_colors.dart';
import '../../../api/endpoints/ai_chat_api.dart';

class AiInsightsSidebar extends StatefulWidget {
  final String? conversationId;
  final String? initialPrompt;
  final VoidCallback onClose;
  final bool isDark;

  const AiInsightsSidebar({
    super.key,
    this.conversationId,
    this.initialPrompt,
    required this.onClose,
    required this.isDark,
  });

  @override
  State<AiInsightsSidebar> createState() => _AiInsightsSidebarState();
}

class _AiInsightsSidebarState extends State<AiInsightsSidebar> {
  final AiChatApi _aiApi = AiChatApi();
  String _insights = "";
  bool _isLoading = false;
  String _error = "";

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  @override
  void didUpdateWidget(AiInsightsSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _fetchInsights();
    }
  }

  Future<void> _fetchInsights({String? customPrompt}) async {
    if (widget.conversationId == null) return;

    setState(() {
      _isLoading = true;
      _error = "";
    });

    try {
      final prompt = customPrompt ??
          widget.initialPrompt ??
          "Analyze the conversation (ID: ${widget.conversationId}) and provide: 1. A summary of recent discussions. 2. Any pending action items or commitments. 3. Potential blockers mentioned.";

      final response = await _aiApi.sendMessage(prompt);

      if (response.success && response.data != null) {
        setState(() {
          _insights =
              response.data['response']?.toString() ?? "No insights available.";
        });
      } else {
        setState(() {
          _error = response.error?.message ?? "Failed to load insights";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = widget.isDark ? Colors.white70 : Colors.black54;
    final surfaceColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          left: BorderSide(
            color: widget.isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 20),
                  color: secondaryTextColor,
                ),
              ],
            ),
          ),

          Divider(
              height: 1,
              color: widget.isDark ? Colors.white10 : Colors.grey.shade200),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _error,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoBox(
                              'Conversation Intelligence',
                              'AI is analyzing your chat history to provide real-time assistance.',
                              Icons.lightbulb_outline,
                            ),
                            const SizedBox(height: 20),
                            _buildFormattedInsights(
                                _insights, textColor, secondaryTextColor),
                          ],
                        ),
                      ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'AI insights are generated automatically and may vary in accuracy.',
              style: TextStyle(
                color: secondaryTextColor.withOpacity(0.5),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CommonColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CommonColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: CommonColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: CommonColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedInsights(
      String text, Color textColor, Color secondaryTextColor) {
    // Simple markdown-ish formatting for keywords
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final isTitle =
            line.startsWith('###') || line.contains(':') && line.length < 30;
        final isBullet = line.startsWith('-') || line.startsWith('•');

        return Padding(
          padding: EdgeInsets.only(
            top: isTitle ? 12.0 : 4.0,
            bottom: isTitle ? 4.0 : 0.0,
            left: isBullet ? 8.0 : 0.0,
          ),
          child: Text(
            line.replaceAll('###', '').trim(),
            style: TextStyle(
              color: isTitle ? CommonColors.primary : textColor,
              fontSize: isTitle ? 14 : 13,
              fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
              height: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }
}
