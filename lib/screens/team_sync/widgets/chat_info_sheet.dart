import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../model/team_sync_conversation.dart';
import '../../../model/team_sync_message.dart';
import '../../../api/endpoints/ai_chat_api.dart';

class ChatInfoSheet extends StatefulWidget {
  final TeamSyncConversation conversation;
  final List<TeamSyncMessage> messages;
  final Function(TeamSyncMessage) onMessageTap;
  final VoidCallback? onDeleteConversation;
  final VoidCallback? onLeaveGroup;
  final bool isDark;
  final VoidCallback onClose;

  final int initialIndex;

  const ChatInfoSheet({
    super.key,
    required this.conversation,
    required this.messages,
    required this.onMessageTap,
    required this.isDark,
    required this.onClose,
    this.initialIndex = 0,
    this.onDeleteConversation,
    this.onLeaveGroup,
  });

  @override
  State<ChatInfoSheet> createState() => _ChatInfoSheetState();
}

class _ChatInfoSheetState extends State<ChatInfoSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AiChatApi _aiApi = AiChatApi();
  String _aiInsights = "";
  bool _isLoadingAi = false;
  String _aiError = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 4, vsync: this, initialIndex: widget.initialIndex);
    _tabController.addListener(() {
      if (_tabController.index == 3 && _aiInsights.isEmpty && !_isLoadingAi) {
        _fetchAiInsights();
      }
    });
  }

  Future<void> _fetchAiInsights() async {
    setState(() {
      _isLoadingAi = true;
      _aiError = "";
    });

    try {
      final response = await _aiApi.sendMessage(
        "Analyze the conversation (ID: ${widget.conversation.id}) and provide a briefing for a user who wants to catch up. Highlight key points and action items.",
      );

      if (response.success && response.data != null) {
        setState(() {
          _aiInsights =
              response.data['response']?.toString() ?? "No insights yet.";
        });
      } else {
        setState(() {
          _aiError = response.error?.message ?? "Failed to load AI insights";
        });
      }
    } catch (e) {
      setState(() {
        _aiError = "Error: $e";
      });
    } finally {
      if (mounted) setState(() => _isLoadingAi = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryTextColor =
        widget.isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final secondaryTextColor =
        widget.isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final surfaceColor =
        widget.isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;
    final borderColor =
        widget.isDark ? AppTheme.darkBorderColor : const Color(0xFFE2E8F0);

    return Container(
      color: surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chat Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close, color: secondaryTextColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: secondaryTextColor,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  GoogleFonts.poppins(fontWeight: FontWeight.w500),
              indicatorColor: AppTheme.primaryColor,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Pinned'),
                Tab(text: 'Starred'),
                Tab(text: 'AI'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(primaryTextColor, secondaryTextColor),
                _buildMessageList(
                  widget.messages.where((m) => m.isPinned).toList(),
                  'No pinned messages',
                  primaryTextColor,
                  secondaryTextColor,
                  Icons.push_pin_outlined,
                ),
                _buildMessageList(
                  widget.messages.where((m) => m.isStarred).toList(),
                  'No starred messages',
                  primaryTextColor,
                  secondaryTextColor,
                  Icons.star_outline_rounded,
                ),
                _buildAiTab(primaryTextColor, secondaryTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(Color primaryTextColor, Color secondaryTextColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group/User Avatar & Name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: widget.conversation.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            widget.conversation.avatarUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(
                              (widget.conversation.effectiveDisplayName)[0]
                                  .toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          (widget.conversation.effectiveDisplayName)[0]
                              .toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.conversation.effectiveDisplayName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.conversation.type == ConversationType.group) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.conversation.isPublic
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.conversation.isPublic
                              ? Icons.public
                              : Icons.lock_outline,
                          size: 14,
                          color: widget.conversation.isPublic
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.conversation.isPublic ? 'Public' : 'Private',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.conversation.isPublic
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.conversation.participants.length > 2) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${widget.conversation.participants.length} members',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Invite Link (if applicable)
          if (widget.conversation.isPublic ||
              widget.conversation.inviteCode != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invite Link',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          widget.conversation.inviteCode != null
                              ? 'teamsync.app/join/${widget.conversation.inviteCode}'
                              : 'Generate invite link',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: secondaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final link = widget.conversation.inviteCode != null
                          ? 'teamsync.app/join/${widget.conversation.inviteCode}'
                          : '';
                      if (link.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invite link copied!')),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: Colors.blue,
                    ),
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Members Section
          if (widget.conversation.participants.isNotEmpty) ...[
            Text(
              'Members',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.conversation.participants.length,
              itemBuilder: (context, index) {
                final p = widget.conversation.participants[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        child: Text(
                          (p.userName ?? 'U')[0].toUpperCase(),
                          style:
                              TextStyle(fontSize: 12, color: primaryTextColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.userName ?? 'Unknown',
                              style: TextStyle(
                                  color: primaryTextColor, fontSize: 14),
                            ),
                            Text(
                              p.userType,
                              style: TextStyle(
                                  color: secondaryTextColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (p.userType.toLowerCase() == 'admin')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 32),

          // Actions
          if (widget.onDeleteConversation != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onDeleteConversation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Conversation'),
              ),
            ),

          if (widget.onLeaveGroup != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onLeaveGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Leave Group'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageList(List<TeamSyncMessage> list, String emptyText,
      Color primaryTextColor, Color secondaryTextColor, IconData emptyIcon) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 48,
              color: secondaryTextColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              emptyText,
              style: GoogleFonts.poppins(
                color: secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(0),
      itemCount: list.length,
      separatorBuilder: (context, index) => Divider(
        color: widget.isDark ? Colors.white10 : Colors.grey.shade100,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final message = list[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onMessageTap(message),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    radius: 20,
                    child: Text(
                      (message.senderName?.isNotEmpty == true
                              ? message.senderName![0]
                              : '?')
                          .toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                message.senderName ?? 'Unknown',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: primaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d')
                                  .format(message.createdAt.toLocal()),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.content ??
                              (message.fileUrl != null
                                  ? (message.messageType == 'image'
                                      ? '📷 Image'
                                      : '📎 File')
                                  : ''),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: secondaryTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiTab(Color primaryTextColor, Color secondaryTextColor) {
    if (_isLoadingAi) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_aiError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 16),
              Text(_aiError,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _fetchAiInsights, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Smart Briefing',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _aiInsights.isEmpty
                ? "AI is generating your briefing..."
                : _aiInsights,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: primaryTextColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
