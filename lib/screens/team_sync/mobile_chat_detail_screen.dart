import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../../helpers/common_colors.dart';
import '../../model/team_sync_conversation.dart';
import '../../model/team_sync_message.dart';
import '../../model/chat_theme_model.dart';
import '../../providers/chat_theme_provider.dart';

import '../../view_model/team_sync_view_model.dart';
import '../../widgets/team_sync/skeleton_loaders.dart';

import '../../widgets/team_sync/chat_background.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_info_sheet.dart';
import 'widgets/chat_theme_selector.dart';
import 'widgets/file_upload_confirmation_dialog.dart';
import 'widgets/attachment_selector_dialog.dart';
import 'widgets/contact_picker_dialog.dart';
import '../../widgets/team_sync/file_preview_dialog.dart';

/// Mobile Chat Detail Screen - Separate screen for viewing chat on mobile/tablet
class MobileChatDetailScreen extends StatefulWidget {
  final TeamSyncConversation conversation;

  const MobileChatDetailScreen({super.key, required this.conversation});

  @override
  State<MobileChatDetailScreen> createState() => _MobileChatDetailScreenState();
}

class _MobileChatDetailScreenState extends State<MobileChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<TeamSyncMessage> _messages = [];
  bool _isLoadingMessages = true;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;

  Timer? _typingTimer;
  bool _isTyping = false;
  Map<String, String> _typingUsers = {};

  TeamSyncMessage? _replyingTo;

  StreamSubscription? _typingSubscription;
  StreamSubscription? _newMessageSubscription;
  StreamSubscription? _messageStatusSubscription;
  StreamSubscription? _themeUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _scrollController.addListener(_onScroll);
    _setupListeners();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _typingSubscription?.cancel();
    _newMessageSubscription?.cancel();
    _messageStatusSubscription?.cancel();
    _themeUpdateSubscription?.cancel();
    super.dispose();
  }

  void _setupListeners() {
    final teamSyncVM = context.read<TeamSyncViewModel>();

    _typingSubscription = teamSyncVM.typingEventsStream.listen((event) {
      final conversationId = event['conversationId'] as String?;
      if (conversationId == widget.conversation.id) {
        setState(() {
          _typingUsers = Map<String, String>.from(
            event['typingUsers'] as Map<String, String>? ?? {},
          );
        });
      }
    });

    _newMessageSubscription = teamSyncVM.newMessagesStream.listen((message) {
      if (message.conversationId == widget.conversation.id) {
        final alreadyExists = _messages.any((m) => m.id == message.id);
        if (!alreadyExists) {
          setState(() {
            _messages = [..._messages, message];
          });

          // Mark as read since user is actively viewing this conversation
          if (message.senderId != teamSyncVM.currentUserId ||
              message.senderType != teamSyncVM.currentUserType) {
            teamSyncVM.markMessageAsRead(message.id);
            teamSyncVM.markConversationAsRead(widget.conversation.id);
          }

          _scrollToBottom();
        }
      }
    });

    _messageStatusSubscription =
        teamSyncVM.messageStatusUpdatesStream.listen((data) {
      final messageId = data['messageId']?.toString();
      final statusStr = data['status']?.toString();
      final confirmedId = data['confirmedId']?.toString();
      if (messageId == null || statusStr == null) return;
      MessageStatus newStatus;
      switch (statusStr) {
        case 'sent':
          newStatus = MessageStatus.sent;
          break;
        case 'delivered':
          newStatus = MessageStatus.delivered;
          break;
        case 'read':
          newStatus = MessageStatus.read;
          break;
        default:
          return;
      }
      if (!mounted) return;
      setState(() {
        _messages = _messages.map((m) {
          if (m.id == messageId) {
            if (confirmedId != null && confirmedId.isNotEmpty) {
              return m.copyWith(id: confirmedId, status: newStatus);
            }
            return m.copyWith(status: newStatus);
          }
          return m;
        }).toList();
      });
    });
    _themeUpdateSubscription =
        teamSyncVM.themeUpdateStream.listen((data) async {
      final conversationId = data['conversationId']?.toString();
      final themeId = data['themeId']?.toString();

      if (conversationId != null &&
          themeId != null &&
          conversationId == widget.conversation.id) {
        final themeProvider = context.read<ChatThemeProvider>();
        await themeProvider.setConversationTheme(conversationId, themeId);
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoadingMessages = true);
    final teamSyncVM = context.read<TeamSyncViewModel>();

    try {
      final msgs = await teamSyncVM.loadMessages(widget.conversation.id);
      setState(() {
        _messages = msgs;
        _hasMoreMessages = msgs.length >= 20;
        _isLoadingMessages = false;
      });
      teamSyncVM.markConversationAsRead(widget.conversation.id);
    } catch (e) {
      debugPrint('[MobileChatDetail] Error loading messages: $e');
      setState(() => _isLoadingMessages = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _messages.isEmpty) return;

    setState(() => _isLoadingMore = true);
    final teamSyncVM = context.read<TeamSyncViewModel>();

    try {
      final oldestMessage = _messages.first;
      final olderMsgs = await teamSyncVM.loadMoreMessages(
        widget.conversation.id,
        oldestMessage.id,
      );

      setState(() {
        if (olderMsgs.isNotEmpty) {
          _messages = [...olderMsgs, ..._messages];
        }
        _hasMoreMessages = olderMsgs.length >= 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('[MobileChatDetail] Error loading more: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  void _handleTyping(String value) {
    final teamSyncVM = context.read<TeamSyncViewModel>();

    if (!_isTyping && value.isNotEmpty) {
      _isTyping = true;
      teamSyncVM.startTyping(widget.conversation.id);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        teamSyncVM.stopTyping();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _isTyping = false;

    final teamSyncVM = context.read<TeamSyncViewModel>();
    teamSyncVM.stopTyping();

    final replyToId = _replyingTo?.id;
    setState(() => _replyingTo = null);

    final optimisticMessage = await teamSyncVM.sendTextMessage(
      widget.conversation.id,
      content,
      replyToId: replyToId,
    );

    if (optimisticMessage != null) {
      setState(() {
        _messages = [..._messages, optimisticMessage];
      });
      _scrollToBottom();
    }
  }

  Future<void> _pickAndSendFile([FileType type = FileType.any]) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Pick Files (allow multiple)
    final result = await FilePicker.platform.pickFiles(
      type: type,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    // 2. Show Confirmation Dialog
    final dialogResult = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FileUploadConfirmationDialog(
        initialFiles: result.files,
        isDark: isDark,
      ),
    );

    if (dialogResult == null) return; // Cancelled

    final filesToSend = dialogResult['files'] as List<PlatformFile>;
    final caption = dialogResult['caption'] as String?;

    if (filesToSend.isEmpty) return;

    // 3. Process Files
    final teamSyncVM = context.read<TeamSyncViewModel>();

    for (final file in filesToSend) {
      if (file.bytes == null && file.path == null) continue;

      // Get file bytes
      List<int> fileBytes;
      if (file.bytes != null) {
        fileBytes = file.bytes!;
      } else {
        fileBytes = await File(file.path!).readAsBytes();
      }

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploading ${file.name}...')),
        );
      }

      // Upload file
      final uploadResult = await teamSyncVM.uploadFile(
        fileBytes: Uint8List.fromList(fileBytes),
        fileName: file.name,
      );

      if (uploadResult == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload ${file.name}')),
          );
        }
        continue;
      }

      // Determine message type
      String messageType = 'file';
      final ext = file.name.toLowerCase().split('.').last;
      if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
        messageType = 'image';
      } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
        messageType = 'video';
      } else if (['mp3', 'wav', 'aac', 'm4a', 'ogg'].contains(ext)) {
        messageType = 'audio';
      } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx']
          .contains(ext)) {
        messageType = 'document';
      }

      // Send message
      final optimisticMessage = await teamSyncVM.sendFileMessage(
        widget.conversation.id,
        fileUrl: uploadResult['url'] as String,
        fileName: file.name,
        fileSize: file.size,
        messageType: messageType,
        fileMimeType: file.extension,
      );

      if (optimisticMessage != null) {
        setState(() {
          _messages = [..._messages, optimisticMessage];
        });
      }
    }

    // 4. Send Caption (if any)
    if (caption != null && caption.isNotEmpty) {
      final optimisticCaption = await teamSyncVM.sendTextMessage(
        widget.conversation.id,
        caption,
      );
      if (optimisticCaption != null) {
        setState(() {
          _messages = [..._messages, optimisticCaption];
        });
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayName = widget.conversation.effectiveDisplayName;
    final isOnline = widget.conversation.otherUserOnline ?? false;

    return Consumer2<TeamSyncViewModel, ChatThemeProvider>(
      builder: (context, viewModel, themeProvider, _) {
        final currentTheme =
            themeProvider.getThemeForConversation(widget.conversation.id);
        final textColor = currentTheme.textColor;
        final secondaryTextColor = currentTheme.timestampColor;

        return Scaffold(
          backgroundColor: currentTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: textColor,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                _buildAvatar(
                  name: displayName,
                  imageUrl: widget.conversation.effectiveDisplayImage,
                  isOnline: isOnline,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_typingUsers.isNotEmpty)
                        Text(
                          '${_typingUsers.values.first} is typing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: CommonColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Text(
                          isOnline
                              ? 'Online'
                              : widget.conversation.otherUserLastSeen != null
                                  ? 'Last seen: ${DateFormat('MMM d, h:mm a').format(widget.conversation.otherUserLastSeen!.toLocal())}'
                                  : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOnline
                                ? const Color(0xFF22C55E)
                                : secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Info button
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      height: MediaQuery.of(context).size.height * 0.85,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      child: ChatInfoSheet(
                        conversation: widget.conversation,
                        messages: _messages,
                        initialIndex: 0,
                        isDark: isDark,
                        onClose: () => Navigator.pop(context),
                        onMessageTap: (msg) {
                          Navigator.pop(context);
                          final index =
                              _messages.indexWhere((m) => m.id == msg.id);
                          if (index != -1 && _scrollController.hasClients) {
                            _scrollController.animateTo(
                              index * 120.0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        onDeleteConversation: () async {
                          Navigator.pop(context);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Conversation'),
                              content: const Text(
                                  'Are you sure you want to delete this conversation?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            final vm = context.read<TeamSyncViewModel>();
                            await vm.deleteConversation(widget.conversation.id);
                            if (mounted) Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.info_outline_rounded, color: textColor),
                tooltip: 'Chat Info',
              ),
              // Theme button
              IconButton(
                icon: Icon(Icons.palette_outlined, color: textColor),
                tooltip: 'Change Theme',
                onPressed: () => showChatThemeSelectorSheet(
                  context,
                  isDark,
                  conversationId: widget.conversation.id,
                ),
              ),
              IconButton(
                onPressed: _loadMessages,
                icon: Icon(Icons.refresh_rounded, color: textColor),
                tooltip: 'Refresh messages',
              ),
            ],
          ),
          extendBodyBehindAppBar: true,
          body: ChatBackground(
            theme: currentTheme,
            child: SafeArea(
              child: Column(
                children: [
                  // Messages
                  Expanded(
                    child: _isLoadingMessages
                        ? MessageSkeletonLoader(isDark: isDark)
                        : _messages.isEmpty
                            ? _buildEmptyState(secondaryTextColor)
                            : _buildMessageListView(
                                viewModel, isDark, currentTheme),
                  ),
                  _buildMessageInput(viewModel, currentTheme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String text;
    if (dateOnly == today) {
      text = 'Today';
    } else if (dateOnly == yesterday) {
      text = 'Yesterday';
    } else {
      text = DateFormat('MMMM d, yyyy').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CommonColors.getSecondaryTextColor(context),
          ),
        ),
      ),
    );
  }

  // _showThemeSelector - replaced by showChatThemeSelectorSheet from ported widget
  // _buildMessageBubble - replaced by MessageBubble widget from ported widget
  // _buildMessageContent - now handled by MessageBubble widget internally

  // _buildMessageStatus and _getAvatarColor - now handled by MessageBubble widget internally

  Widget _buildAvatar({
    required String name,
    String? imageUrl,
    bool isOnline = false,
    double size = 48,
  }) {
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFFF59E0B),
    ];

    final colorIndex = name.hashCode % colors.length;
    final bgColor = colors[colorIndex.abs()];

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(Color secondaryTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: secondaryTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start the conversation!',
            style: TextStyle(
              fontSize: 12,
              color: secondaryTextColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageListView(
    TeamSyncViewModel viewModel,
    bool isDark,
    ChatTheme currentTheme,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == viewModel.currentUserId &&
            message.senderType == viewModel.currentUserType;

        // Date Header Logic
        bool showDateHeader = false;
        if (index == 0) {
          showDateHeader = true;
        } else {
          final prevMessage = _messages[index - 1];
          final prevDate = DateTime(prevMessage.createdAt.year,
              prevMessage.createdAt.month, prevMessage.createdAt.day);
          final currDate = DateTime(message.createdAt.year,
              message.createdAt.month, message.createdAt.day);
          if (currDate != prevDate) {
            showDateHeader = true;
          }
        }

        // Find replied message
        final repliedMsg = message.replyToId != null
            ? _messages.where((m) => m.id == message.replyToId).firstOrNull
            : null;

        return Column(
          children: [
            if (showDateHeader) _buildDateHeader(message.createdAt),
            MessageBubble(
              chatTheme: currentTheme,
              repliedMessage: repliedMsg,
              message: message,
              isMe: isMe,
              isDark: isDark,
              currentUserId: viewModel.currentUserId ?? '',
              userNames: {
                for (var u in viewModel.chatUsers) u.id: u.name,
              },
              onFileClick: (msg) => showDialog(
                context: context,
                builder: (ctx) => FilePreviewDialog(message: msg),
              ),
              onReply: () => setState(() => _replyingTo = message),
              onReact: (reaction) async {
                final myId = viewModel.currentUserId;
                final myType = viewModel.currentUserType;
                final currentReactions =
                    List<MessageReaction>.from(message.reactions);
                final existingReaction =
                    currentReactions.where((r) => r.userId == myId).firstOrNull;
                if (existingReaction != null) {
                  final withoutExisting =
                      currentReactions.where((r) => r.userId != myId).toList();
                  if (existingReaction.reaction == reaction) {
                    // Same reaction → toggle off
                    setState(() {
                      _messages = _messages
                          .map((m) => m.id == message.id
                              ? message.copyWith(reactions: withoutExisting)
                              : m)
                          .toList();
                    });
                    await viewModel.removeReaction(message.id, reaction);
                  } else {
                    // Different reaction → swap
                    final newReactions = [
                      ...withoutExisting,
                      MessageReaction(
                          reaction: reaction,
                          userId: myId ?? '',
                          userType: myType ?? ''),
                    ];
                    setState(() {
                      _messages = _messages
                          .map((m) => m.id == message.id
                              ? message.copyWith(reactions: newReactions)
                              : m)
                          .toList();
                    });
                    await viewModel.removeReaction(
                        message.id, existingReaction.reaction);
                    await viewModel.addReaction(message.id, reaction);
                  }
                } else {
                  // No existing → add
                  final newReactions = [
                    ...currentReactions,
                    MessageReaction(
                        reaction: reaction,
                        userId: myId ?? '',
                        userType: myType ?? ''),
                  ];
                  setState(() {
                    _messages = _messages
                        .map((m) => m.id == message.id
                            ? message.copyWith(reactions: newReactions)
                            : m)
                        .toList();
                  });
                  await viewModel.addReaction(message.id, reaction);
                }
              },
              onDownload: () async {
                if (message.fileUrl == null) return;
                try {
                  await launchUrl(Uri.parse(message.fileUrl!),
                      mode: LaunchMode.externalApplication);
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not download')),
                    );
                  }
                }
              },
              onPin: () async {
                final newPinned = !message.isPinned;
                setState(() {
                  _messages = _messages
                      .map((m) => m.id == message.id
                          ? m.copyWith(isPinned: newPinned)
                          : m)
                      .toList();
                });
                if (newPinned) {
                  await viewModel.pinMessage(
                      widget.conversation.id, message.id);
                } else {
                  await viewModel.unpinMessage(widget.conversation.id);
                }
              },
              onStar: () async {
                final newStarred = !message.isStarred;
                setState(() {
                  _messages = _messages
                      .map((m) => m.id == message.id
                          ? m.copyWith(isStarred: newStarred)
                          : m)
                      .toList();
                });
                if (newStarred) {
                  await viewModel.starMessage(message.id);
                } else {
                  await viewModel.unstarMessage(message.id);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageInput(TeamSyncViewModel viewModel, ChatTheme theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0);
    final secondaryTextColor = theme.timestampColor;
    final textColor = theme.textColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CommonColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Replying to ${_replyingTo!.senderName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: CommonColors.primary,
                        ),
                      ),
                      Text(
                        _replyingTo!.content ?? 'Attachment',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _replyingTo = null),
                  icon: Icon(
                    Icons.close_rounded,
                    color: secondaryTextColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: () async {
                    final AttachmentType? type =
                        await showDialog<AttachmentType>(
                      context: context,
                      builder: (context) =>
                          AttachmentSelectorDialog(isDark: isDark),
                    );

                    if (type != null) {
                      if (type == AttachmentType.contact) {
                        if (mounted) {
                          final Map<String, dynamic>? contactData =
                              await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) =>
                                ContactPickerDialog(isDark: isDark),
                          );

                          if (contactData != null && mounted) {
                            final vm = context.read<TeamSyncViewModel>();
                            final optimisticMessage =
                                await vm.sendContactMessage(
                              widget.conversation.id,
                              contactName: contactData['name'] as String,
                              contactPhone: contactData['phone'] as String?,
                              contactEmail: contactData['email'] as String?,
                            );

                            if (optimisticMessage != null) {
                              setState(() {
                                _messages = [..._messages, optimisticMessage];
                              });
                            }
                          }
                        }
                      } else {
                        _pickAndSendFile(
                          type == AttachmentType.image
                              ? FileType.image
                              : FileType.any,
                        );
                      }
                    }
                  },
                  icon: Icon(
                    Icons.attach_file_rounded,
                    color: secondaryTextColor,
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onChanged: _handleTyping,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: CommonColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
