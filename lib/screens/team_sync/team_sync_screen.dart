import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../../helpers/common_colors.dart';
import '../../model/team_sync_conversation.dart';
import '../../model/team_sync_message.dart';

import '../../model/chat_theme_model.dart';
import '../../providers/chat_theme_provider.dart';
import '../../services/local_storage_service.dart';
import '../../view_model/auth_view_model.dart';
import '../../view_model/team_sync_view_model.dart';
import '../../api/endpoints/ai_chat_api.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/team_sync/conversation_filters.dart';
import '../../widgets/team_sync/skeleton_loaders.dart';
import '../../widgets/team_sync/create_group_dialog.dart';
import '../../widgets/team_sync/file_preview_dialog.dart';
import '../../widgets/team_sync/user_status_selector.dart';
import 'dart:io';
import '../../widgets/team_sync/chat_background.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_info_sheet.dart';
import 'widgets/chat_theme_selector.dart';
import 'widgets/file_upload_confirmation_dialog.dart';
import 'widgets/ai_insights_sidebar.dart';
import 'widgets/attachment_selector_dialog.dart';
import 'widgets/contact_picker_dialog.dart';
import 'mobile_chat_detail_screen.dart';

/// TeamSync Screen - Main chat interface (cloned from admin)
class TeamSyncScreen extends StatefulWidget {
  const TeamSyncScreen({super.key});

  @override
  State<TeamSyncScreen> createState() => _TeamSyncScreenState();
}

class _TeamSyncScreenState extends State<TeamSyncScreen> {
  TeamSyncConversation? _selectedConversation;
  List<TeamSyncMessage> _messages = [];
  bool _isLoadingMessages = false;
  bool _showUserList = false;

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  Timer? _typingTimer;
  bool _isTyping = false;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _newMessageSubscription;
  StreamSubscription? _messageStatusSubscription;
  StreamSubscription? _themeUpdateSubscription;

  // New features state
  ConversationFilter _selectedFilter = ConversationFilter.all;
  TeamSyncMessage? _replyingTo;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;
  Map<String, String> _typingUsers = {}; // userKey -> userName
  UserStatus _currentUserStatus = UserStatus.active; // User status
  bool _showScrollToBottom = false; // Scroll-to-bottom button visibility
  bool _showEmojiPicker = false;
  late FocusNode _focusNode;

  final AiChatApi _aiApi = AiChatApi();
  bool _isRefining = false;
  bool _showAiSidebar = false;
  String? _aiPrompt;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(onKeyEvent: (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        // BuildContext is available here since it's a closure, but safe to check mounted?
        // _sendMessage calls sync code then async. It's fine.
        _sendMessage();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    });
    _scrollController.addListener(_onScroll);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showEmojiPicker = false);
      }
    });
    _initializeChat();
    // Defer stream setup to after first frame so context and Provider are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupTypingListener();
      _setupNewMessageListener();
      _setupMessageStatusListener();
      _setupThemeUpdateListener();
    });
  }

  /// Listen to message status updates (delivered/read) to update received icon in real-time
  void _setupMessageStatusListener() {
    if (!mounted) return;
    try {
      final teamSyncVM = context.read<TeamSyncViewModel>();
      _messageStatusSubscription =
          teamSyncVM.messageStatusUpdatesStream.listen((data) {
        if (!mounted) return;
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
        setState(() {
          _messages = _messages.map((m) {
            if (m.id == messageId) {
              // If confirmedId is provided, swap the temp ID with the real one
              if (confirmedId != null && confirmedId.isNotEmpty) {
                return m.copyWith(id: confirmedId, status: newStatus);
              }
              return m.copyWith(status: newStatus);
            }
            return m;
          }).toList();
        });
      });
    } catch (e, st) {
      debugPrint('TeamSync: message status stream setup failed: $e');
      debugPrint('$st');
    }
  }

  void _setupThemeUpdateListener() {
    if (!mounted) return;
    try {
      final teamSyncVM = context.read<TeamSyncViewModel>();
      final themeProvider = context.read<ChatThemeProvider>();
      _themeUpdateSubscription =
          teamSyncVM.themeUpdateStream.listen((data) async {
        if (!mounted) return;
        final conversationId = data['conversationId']?.toString();
        final themeId = data['themeId']?.toString();

        if (conversationId != null && themeId != null) {
          // Update themeProvider with notifyPeer = false to avoid loops
          await themeProvider.setConversationTheme(conversationId, themeId);
          if (mounted) setState(() {});
        }
      });
    } catch (e) {
      debugPrint('TeamSync: theme update stream setup failed: $e');
    }
  }

  /// Listen to typing events from the ViewModel
  void _setupTypingListener() {
    if (!mounted) return;
    final teamSyncVM = context.read<TeamSyncViewModel>();
    _typingSubscription = teamSyncVM.typingEventsStream.listen((event) {
      final conversationId = event['conversationId'] as String?;

      // Only update if this is for the currently selected conversation
      if (conversationId != null &&
          _selectedConversation != null &&
          conversationId == _selectedConversation!.id) {
        setState(() {
          _typingUsers = Map<String, String>.from(
            event['typingUsers'] as Map<String, String>? ?? {},
          );
        });
      }
    });
  }

  /// Listen to new messages from WebSocket to update chat area in real-time
  void _setupNewMessageListener() {
    if (!mounted) return;
    final teamSyncVM = context.read<TeamSyncViewModel>();
    _newMessageSubscription = teamSyncVM.newMessagesStream.listen((message) {
      // Only add to _messages if this message is for the currently selected conversation
      if (_selectedConversation != null &&
          message.conversationId == _selectedConversation!.id) {
        // Check if message already exists (avoid duplicates)
        final alreadyExists = _messages.any((m) => m.id == message.id);
        if (!alreadyExists) {
          setState(() {
            _messages = [..._messages, message];
          });

          // Mark as read since user is actively viewing this conversation
          if (message.senderId != teamSyncVM.currentUserId ||
              message.senderType != teamSyncVM.currentUserType) {
            teamSyncVM.markMessageAsRead(message.id);
            teamSyncVM.markConversationAsRead(_selectedConversation!.id);
          }

          // Scroll to bottom for new message
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
      }
    });
  }

  Future<void> _initializeChat() async {
    final authVM = context.read<AuthViewModel>();
    final teamSyncVM = context.read<TeamSyncViewModel>();
    final localStorage = LocalStorageService();

    // Skip if already initialized
    if (teamSyncVM.isInitialized && teamSyncVM.isConnected) {
      return;
    }

    // Prefer cached profile if available for speed
    final cachedProfile = authVM.currentUserProfile;
    String? name = cachedProfile?.name;
    String? image = cachedProfile?.img;
    String? uId = cachedProfile?.employeeId;

    if (uId == null || name == null) {
      final employeeDetails = await authVM.getCurrentEmployeeDetails();
      uId ??= employeeDetails?['employee_id'] as String?;
      name ??=
          employeeDetails?['employeeName'] ?? employeeDetails?['employee_name'];
      image ??=
          employeeDetails?['employeeImg'] ?? employeeDetails?['employee_img'];
    }

    final token = localStorage.accessToken;

    if (uId != null && token.isNotEmpty) {
      await teamSyncVM.initialize(
        token: token,
        userId: uId,
        userType: 'Employee',
        userName: name,
        userImage: image,
      );
    }
  }

  /// Handle scroll for pagination - load more messages when reaching top
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Load more when scrolled near the top (older messages)
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 100 &&
        !_isLoadingMore &&
        _hasMoreMessages &&
        _messages.isNotEmpty &&
        _selectedConversation != null) {
      _loadMoreMessages();
    }

    // Toggle scroll-to-bottom button
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Show button if we are more than 500px away from the bottom (newest messages)
    final showButton = (maxScroll - currentScroll) > 500;

    if (showButton != _showScrollToBottom) {
      setState(() => _showScrollToBottom = showButton);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildDateHeader(DateTime date, {ChatTheme? theme}) {
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

    final secondaryTextColor = theme?.id == 'default' || theme == null
        ? CommonColors.getSecondaryTextColor(context)
        : theme.timestampColor;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme?.backgroundColor.withOpacity(0.1) ??
              (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Future<void> _loadMoreMessages() async {
    if (_messages.isEmpty) return;

    setState(() => _isLoadingMore = true);

    final teamSyncVM = context.read<TeamSyncViewModel>();
    final oldestMessage = _messages.first;

    final olderMsgs = await teamSyncVM.loadMoreMessages(
      _selectedConversation!.id,
      oldestMessage.id,
    );

    setState(() {
      if (olderMsgs.isNotEmpty) {
        _messages = [...olderMsgs, ..._messages];
      }
      _hasMoreMessages = olderMsgs.length >= 20;
      _isLoadingMore = false;
    });
  }

  @override
  void dispose() {
    _typingSubscription?.cancel();
    _newMessageSubscription?.cancel();
    _messageStatusSubscription?.cancel();
    _themeUpdateSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _selectConversation(TeamSyncConversation conversation) async {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    // On mobile/tablet, navigate to full-screen chat detail
    if (isMobile || isTablet) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              MobileChatDetailScreen(conversation: conversation),
        ),
      );
      return;
    }

    // On desktop, show chat in the side panel
    setState(() {
      _selectedConversation = conversation;
      _isLoadingMessages = true;
      _messages = [];
      _hasMoreMessages = true;
      _replyingTo = null;
      // Clear typing users for the previous conversation
      _typingUsers = {};
    });

    final teamSyncVM = context.read<TeamSyncViewModel>();
    final messages = await teamSyncVM.loadMessages(conversation.id);

    // Load initial typing state for this conversation
    final typingUsers = teamSyncVM.getTypingUsers(conversation.id);

    setState(() {
      _messages = messages;
      _isLoadingMessages = false;
      _typingUsers = Map<String, String>.from(typingUsers);
    });

    // Mark as read
    teamSyncVM.markConversationAsRead(conversation.id);

    // Scroll to bottom
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

  void _handleTyping() {
    final teamSyncVM = context.read<TeamSyncViewModel>();

    if (_selectedConversation != null && !_isTyping) {
      _isTyping = true;
      teamSyncVM.startTyping(_selectedConversation!.id);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      teamSyncVM.stopTyping();
    });
  }

  /// Get formatted typing indicator text
  String _getTypingText() {
    if (_typingUsers.isEmpty) return '';

    final names = _typingUsers.values.toList();
    if (names.length == 1) {
      return '${names.first} is typing...';
    } else if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    } else {
      return '${names[0]} and ${names.length - 1} others are typing...';
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _selectedConversation == null) return;

    _messageController.clear();
    _typingTimer?.cancel();
    _isTyping = false;

    final teamSyncVM = context.read<TeamSyncViewModel>();
    teamSyncVM.stopTyping();

    // Handle reply
    final replyToId = _replyingTo?.id;
    setState(() => _replyingTo = null);

    final optimisticMessage = await teamSyncVM.sendTextMessage(
      _selectedConversation!.id,
      content,
      replyToId: replyToId,
    );

    if (optimisticMessage != null) {
      setState(() {
        _messages = [..._messages, optimisticMessage];
      });

      // Scroll to bottom
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
  }

  /// Pick and send a file
  /// Pick and send a file
  Future<void> _pickAndSendFile([FileType type = FileType.any]) async {
    if (_selectedConversation == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      // 1. Pick Files
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: true,
        withData: true,
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

      final teamSyncVM = context.read<TeamSyncViewModel>();

      // 3. Process Files
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
          mimeType:
              file.extension != null ? _getMimeType(file.extension!) : null,
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
          _selectedConversation!.id,
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
          _selectedConversation!.id,
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
    } catch (e) {
      debugPrint('[TeamSync] Error picking/sending file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _getMimeType(String extension) {
    final mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'mp4': 'video/mp4',
      'mp3': 'audio/mpeg',
    };
    return mimeTypes[extension.toLowerCase()] ?? 'application/octet-stream';
  }

  /// Create a group chat
  Future<void> _createGroup() async {
    final teamSyncVM = context.read<TeamSyncViewModel>();

    // Ensure we have users
    if (teamSyncVM.chatUsers.isEmpty) {
      await teamSyncVM.loadChatUsers();
    }

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          CreateGroupDialog(availableUsers: teamSyncVM.chatUsers),
    );

    if (result != null && mounted) {
      final conversation = await teamSyncVM.createGroupConversation(
        name: result['name'] as String,
        description: result['description'] as String?,
        participants: (result['participants'] as List<TeamSyncUser>)
            .map((u) => {'userId': u.id, 'userType': u.userType})
            .toList(),
        isPublic: result['isPublic'] as bool? ?? false,
      );

      if (conversation != null) {
        await _selectConversation(conversation);
      }
    }
  }

  /// Show file preview dialog

  void _onEmojiSelected(Emoji emoji) {
    _messageController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
  }

  void _onBackspacePressed() {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final cursorPosition = selection.baseOffset;

    if (cursorPosition < 0) return;

    if (selection.start != selection.end) {
      // Delete selection
      final newText = text.replaceRange(selection.start, selection.end, '');
      _messageController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
    } else if (cursorPosition > 0) {
      // Delete character before cursor
      final newText = text.replaceRange(cursorPosition - 1, cursorPosition, '');
      _messageController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorPosition - 1),
      );
    }
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<TeamSyncViewModel, ChatThemeProvider>(
      builder: (context, viewModel, themeProvider, child) {
        final currentTheme =
            themeProvider.getThemeForConversation(_selectedConversation?.id);

        if (viewModel.isLoading && viewModel.conversations.isEmpty) {
          return Scaffold(body: _buildLoadingState(context));
        }

        if (viewModel.error != null) {
          return Scaffold(body: _buildErrorState(context, viewModel));
        }

        return Scaffold(
          backgroundColor: currentTheme.backgroundColor,
          body: ChatBackground(
            theme: currentTheme,
            child: Builder(
              builder: (context) {
                // Mobile layout
                if (isMobile) {
                  return _selectedConversation != null
                      ? _buildChatArea(context, viewModel, isDark,
                          isMobile: true)
                      : _showUserList
                          ? _buildUserListOverlay(context, viewModel, isDark)
                          : _buildConversationList(
                              context,
                              viewModel,
                              isDark,
                              fullScreen: true,
                            );
                }

                // Desktop/Tablet layout
                return Row(
                  children: [
                    // Sidebar
                    SizedBox(
                      width: isTablet ? 280 : 320,
                      child: _showUserList
                          ? _buildUserListOverlay(context, viewModel, isDark)
                          : _buildConversationList(context, viewModel, isDark),
                    ),

                    // Vertical Divider
                    Container(
                      width: 1,
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),

                    // Chat area
                    Expanded(
                      child: _selectedConversation != null
                          ? _buildChatArea(context, viewModel, isDark)
                          : _buildWelcomeState(context, isDark,
                              theme: currentTheme),
                    ),

                    // AI Sidebar
                    if (_showAiSidebar && _selectedConversation != null)
                      SizedBox(
                        width: isTablet ? 300 : 350,
                        child: AiInsightsSidebar(
                          key: ValueKey(
                              '${_selectedConversation!.id}_$_aiPrompt'),
                          conversationId: _selectedConversation!.id,
                          initialPrompt: _aiPrompt,
                          onClose: () => setState(() => _showAiSidebar = false),
                          isDark: isDark,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: CommonColors.primary),
          const SizedBox(height: 16),
          customTextWithClip(
            text: 'Loading TeamSync...',
            textColor: CommonColors.getSecondaryTextColor(context),
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, TeamSyncViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          customTextWithClip(
            text: 'Something went wrong',
            textColor: CommonColors.getTextColor(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          customTextWithClip(
            text: viewModel.error ?? 'Unknown error',
            textColor: CommonColors.getSecondaryTextColor(context),
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              viewModel.clearError();
              _initializeChat();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CommonColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState(BuildContext context, bool isDark,
      {ChatTheme? theme}) {
    final textColor = theme?.id == 'default' || theme == null
        ? CommonColors.getTextColor(context)
        : theme.textColor;
    final secondaryTextColor = theme?.id == 'default' || theme == null
        ? CommonColors.getSecondaryTextColor(context)
        : theme.timestampColor;

    return Container(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CommonColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: CommonColors.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            customTextWithClip(
              text: 'Welcome to TeamSync',
              textColor: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            customTextWithClip(
              text: 'Select a conversation to start chatting',
              textColor: secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListOverlay(
    BuildContext context,
    TeamSyncViewModel viewModel,
    bool isDark,
  ) {
    final themeProvider = context.read<ChatThemeProvider>();
    final currentTheme =
        themeProvider.getThemeForConversation(_selectedConversation?.id);

    // Dynamic colors for default theme to respect dark mode
    final textColor = currentTheme.id == 'default' 
        ? (isDark ? Colors.white : currentTheme.textColor) 
        : currentTheme.textColor;
    final secondaryTextColor = currentTheme.id == 'default'
        ? (isDark ? Colors.white70 : currentTheme.timestampColor)
        : currentTheme.timestampColor;
    final surfaceColor = currentTheme.id == 'default'
        ? (isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.grey.shade100)
        : textColor.withOpacity(0.1);


    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _showUserList = false),
                  icon: Icon(Icons.arrow_back, color: textColor),
                ),
                const SizedBox(width: 8),
                customTextWithClip(
                  text: 'New Chat',
                  textColor: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: secondaryTextColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(color: textColor, fontSize: 14),
            ),
          ),
          // User list
          Expanded(
            child: Builder(
              builder: (context) {
                final filteredUsers = viewModel.chatUsers.where((user) {
                  if (_searchController.text.isEmpty) return true;
                  final search = _searchController.text.toLowerCase();
                  return user.name.toLowerCase().contains(search);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 48,
                          color: secondaryTextColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        customTextWithClip(
                          text: 'No users found',
                          textColor: secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserTile(context, user, viewModel, isDark,
                        theme: currentTheme,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(
    BuildContext context,
    TeamSyncUser user,
    TeamSyncViewModel viewModel,
    bool isDark, {
    ChatTheme? theme,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: CommonColors.primary.withOpacity(0.2),
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '',
          style: TextStyle(color: CommonColors.primary),
        ),
      ),
      title: customTextWithClip(
        text: user.name,
        textColor: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      subtitle: customTextWithClip(
        text: user.designation ?? 'Employee',
        textColor: secondaryTextColor,
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      onTap: () async {
        final conversation = await viewModel.getOrCreateConversation(
          userId: user.id,
          userType: user.userType,
        );
        if (conversation != null) {
          setState(() {
            _selectedConversation = conversation;
            _showUserList = false;
          });
        }
      },
    );
  }

  Widget _buildConversationList(
    BuildContext context,
    TeamSyncViewModel viewModel,
    bool isDark, {
    bool fullScreen = false,
  }) {
    final themeProvider = context.read<ChatThemeProvider>();
    final currentTheme =
        themeProvider.getThemeForConversation(_selectedConversation?.id);

    // Dynamic colors for default theme to respect dark mode
    final textColor = currentTheme.id == 'default' 
        ? (isDark ? Colors.white : currentTheme.textColor) 
        : currentTheme.textColor;
    final secondaryTextColor = currentTheme.id == 'default'
        ? (isDark ? Colors.white70 : currentTheme.timestampColor)
        : currentTheme.timestampColor;
    final surfaceColor = currentTheme.id == 'default'
        ? (isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.grey.shade100)
        : textColor.withOpacity(0.1);
    final popupColor = currentTheme.id == 'default'
        ? Theme.of(context).cardColor
        : currentTheme.backgroundColor.withOpacity(0.95);


    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: customTextWithClip(
                    text: 'TeamSync',
                    textColor: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // User Status Selector
                UserStatusSelector(
                  currentStatus: _currentUserStatus,
                  onStatusChanged: (status) {
                    setState(() => _currentUserStatus = status);
                    // TODO: Send status update to server when API is ready
                    debugPrint('Status changed to: ${status.displayName}');
                  },
                  isDark: isDark,
                  textColor: textColor,
                  popupColor: popupColor,
                ),
                const SizedBox(width: 8),
                // New chat / Create group popup menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'chat') {
                      setState(() => _showUserList = true);
                    } else if (value == 'group') {
                      _createGroup();
                    }
                  },
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: popupColor,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'chat',
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, color: textColor),
                          const SizedBox(width: 12),
                          Text('New Chat', style: TextStyle(color: textColor)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'group',
                      child: Row(
                        children: [
                          Icon(Icons.group_add_outlined, color: textColor),
                          const SizedBox(width: 12),
                          Text('Create Group',
                              style: TextStyle(color: textColor)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: CommonColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: CommonColors.primary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: TextStyle(color: secondaryTextColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(color: textColor, fontSize: 14),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ConversationFilterChips(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() => _selectedFilter = filter);
              },
              isDark: isDark,
              unreadCount: viewModel.totalUnreadCount,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 12),

          // Conversation list
          Expanded(
            child: Builder(
              builder: (context) {
                // Filter conversations
                final filteredConversations =
                    viewModel.conversations.where((c) {
                  // Apply search
                  if (_searchController.text.isNotEmpty) {
                    final search = _searchController.text.toLowerCase();
                    if (!c.effectiveDisplayName
                        .toLowerCase()
                        .contains(search)) {
                      return false;
                    }
                  }

                  // Apply filter
                  switch (_selectedFilter) {
                    case ConversationFilter.unread:
                      return c.unreadCount > 0;
                    case ConversationFilter.groups:
                      return c.type == ConversationType.group;
                    case ConversationFilter.direct:
                      return c.type == ConversationType.direct ||
                          c.isDirectMessage;
                    case ConversationFilter.all:
                      return true;
                  }
                }).toList();

                if (filteredConversations.isEmpty) {
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
                        customTextWithClip(
                          text: viewModel.conversations.isEmpty
                              ? 'No conversations yet'
                              : 'No matching conversations',
                          textColor: secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showUserList = true;
                              _selectedFilter = ConversationFilter.all;
                              _searchController.clear();
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Start a chat'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredConversations.length,
                  itemBuilder: (context, index) {
                    final conversation = filteredConversations[index];
                    return _buildConversationTile(
                      context,
                      conversation,
                      viewModel,
                      isDark,
                      theme: currentTheme,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    TeamSyncConversation conversation,
    TeamSyncViewModel viewModel,
    bool isDark, {
    ChatTheme? theme,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final isSelected = _selectedConversation?.id == conversation.id;

    final displayName = conversation.effectiveDisplayName;
    final initials = displayName
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => _selectConversation(conversation),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? CommonColors.primary.withOpacity(isDark ? 0.15 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? CommonColors.primary.withOpacity(0.2)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? CommonColors.primary.withOpacity(0.5)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: _getAvatarColor(displayName),
                      backgroundImage: conversation.effectiveDisplayImage !=
                              null
                          ? NetworkImage(conversation.effectiveDisplayImage!)
                          : null,
                      child: conversation.effectiveDisplayImage == null
                          ? Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            )
                          : null,
                    ),
                  ),
                  // Online indicator
                  if (conversation.otherUserOnline == true)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.lastMessageAt != null)
                          Text(
                            _formatTime(conversation.lastMessageAt!),
                            style: TextStyle(
                              color: conversation.unreadCount > 0
                                  ? CommonColors.primary
                                  : secondaryTextColor.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage?.content ??
                                conversation.otherUserDesignation ??
                                'Start a conversation',
                            style: TextStyle(
                              color: conversation.unreadCount > 0
                                  ? secondaryTextColor.withOpacity(0.9)
                                  : secondaryTextColor.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CommonColors.primary,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: CommonColors.primary.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              conversation.unreadCount > 99
                                  ? '99+'
                                  : conversation.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatArea(
    BuildContext context,
    TeamSyncViewModel viewModel,
    bool isDark, {
    bool isMobile = false,
  }) {
    final themeProvider = context.read<ChatThemeProvider>();
    final theme =
        themeProvider.getThemeForConversation(_selectedConversation?.id);
    
    // Dynamic colors for default theme to respect dark mode
    final textColor = theme.id == 'default' 
        ? (isDark ? Colors.white : theme.textColor) 
        : theme.textColor;
    final secondaryTextColor = theme.id == 'default'
        ? (isDark ? Colors.white70 : theme.timestampColor)
        : theme.timestampColor;
    final surfaceColor = theme.id == 'default'
        ? (isDark ? Theme.of(context).cardColor : Colors.white.withOpacity(0.8))
        : textColor.withOpacity(0.1);
    final popupColor = theme.id == 'default'
        ? Theme.of(context).cardColor
        : theme.backgroundColor.withOpacity(0.95);


    return Column(
      children: [
        // Glassmorphism Header
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.id == 'default'
                    ? Theme.of(context).scaffoldBackgroundColor.withOpacity(isDark ? 0.3 : 0.6)
                    : theme.backgroundColor.withOpacity(0.85),

                border: Border(
                  bottom: BorderSide(
                    color: theme.id == 'default'
                        ? (isDark ? Colors.white10 : Colors.grey.shade200)
                        : theme.textColor.withOpacity(0.1),
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    if (isMobile)
                      IconButton(
                        onPressed: () {
                          setState(() => _selectedConversation = null);
                        },
                        icon: Icon(Icons.arrow_back, color: textColor),
                      ),
                    // Avatar
                    InkWell(
                      onTap: () => _showChatInfo(isDark),
                      borderRadius: BorderRadius.circular(20),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: _getAvatarColor(
                          _selectedConversation!.effectiveDisplayName,
                        ),
                        backgroundImage:
                            _selectedConversation!.effectiveDisplayImage != null
                                ? NetworkImage(
                                    _selectedConversation!
                                        .effectiveDisplayImage!,
                                  )
                                : null,
                        child:
                            _selectedConversation!.effectiveDisplayImage == null
                                ? Text(
                                    _selectedConversation!.effectiveDisplayName
                                        .split(' ')
                                        .take(2)
                                        .map((e) => e.isNotEmpty ? e[0] : '')
                                        .join()
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showChatInfo(isDark),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedConversation!.effectiveDisplayName,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                if (_selectedConversation!.otherUserOnline ==
                                    true)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Text(
                                  _selectedConversation!.otherUserOnline == true
                                      ? 'Active now'
                                      : _selectedConversation!.isGroupChat
                                          ? '${_selectedConversation!.participants.length} members'
                                          : _selectedConversation!
                                                  .otherUserDesignation ??
                                              'Offline',
                                  style: TextStyle(
                                    color: _selectedConversation!
                                                .otherUserOnline ==
                                            true
                                        ? Colors.green.shade400
                                        : secondaryTextColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Action Group
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search
                        _buildHeaderAction(
                          icon: Icons.search_rounded,
                          color: textColor.withOpacity(0.7),
                          tooltip: 'Search',
                          onPressed: () {
                            // Placeholder for search
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Search is coming soon')),
                            );
                          },
                        ),

                        // AI Menu
                        PopupMenuButton<String>(
                          icon: Icon(Icons.lightbulb_rounded,
                              color: Colors.amber.shade700, size: 24),
                          tooltip: 'AI Actions',
                          offset: const Offset(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color:
                                    isDark ? Colors.white10 : Colors.black12),
                          ),
                          color: popupColor,
                          onSelected: (value) {
                            if (value == 'insights') {
                              setState(() => _showAiSidebar = !_showAiSidebar);
                            } else {
                              _handleAiAction(value);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'insights',
                              child: Row(
                                children: [
                                  Icon(Icons.lightbulb_rounded,
                                      color: Colors.amber.shade700, size: 20),
                                  const SizedBox(width: 12),
                                  Text('AI Insights',
                                      style: TextStyle(color: textColor)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'Catch-up',
                              child: Row(
                                children: [
                                  Icon(Icons.history_rounded,
                                      color: textColor.withOpacity(0.7),
                                      size: 20),
                                  const SizedBox(width: 12),
                                  Text('Catch-up',
                                      style: TextStyle(color: textColor)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'Summary',
                              child: Row(
                                children: [
                                  Icon(Icons.summarize_rounded,
                                      color: textColor.withOpacity(0.7),
                                      size: 20),
                                  const SizedBox(width: 12),
                                  Text('Summary',
                                      style: TextStyle(color: textColor)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // More Menu
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              color: textColor.withOpacity(0.7), size: 22),
                          tooltip: 'More options',
                          offset: const Offset(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color:
                                    isDark ? Colors.white10 : Colors.black12),
                          ),
                          color: popupColor,
                          onSelected: (value) {
                            if (value == 'theme') {
                              showChatThemeSelectorSheet(
                                context,
                                isDark,
                                conversationId: _selectedConversation!.id,
                              );
                            } else if (value == 'info') {
                              _showChatInfo(isDark);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'theme',
                              child: Row(
                                children: [
                                  Icon(Icons.palette_outlined,
                                      color: textColor.withOpacity(0.7),
                                      size: 20),
                                  const SizedBox(width: 12),
                                  Text('Theme',
                                      style: TextStyle(color: textColor)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'info',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      color: textColor.withOpacity(0.7),
                                      size: 20),
                                  const SizedBox(width: 12),
                                  Text('Chat Details',
                                      style: TextStyle(color: textColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Body
        Expanded(
          child: Stack(
            children: [
              _isLoadingMessages
                  ? MessageSkeletonLoader(isDark: isDark)
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: secondaryTextColor.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              customTextWithClip(
                                text: 'No messages yet',
                                textColor: secondaryTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                              const SizedBox(height: 4),
                              customTextWithClip(
                                text: 'Start the conversation!',
                                textColor: secondaryTextColor.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe = message.senderId ==
                                    viewModel.currentUserId &&
                                message.senderType == viewModel.currentUserType;

                            // Date Header Logic
                            bool showDateHeader = false;
                            if (index == 0) {
                              showDateHeader = true;
                            } else {
                              final prevMessage = _messages[index - 1];
                              final prevDate = DateTime(
                                  prevMessage.createdAt.year,
                                  prevMessage.createdAt.month,
                                  prevMessage.createdAt.day);
                              final currDate = DateTime(
                                  message.createdAt.year,
                                  message.createdAt.month,
                                  message.createdAt.day);
                              if (prevDate != currDate) {
                                showDateHeader = true;
                              }
                            }

                            // Find replied message
                            final repliedMsg = message.replyToId != null
                                ? _messages
                                    .where((m) => m.id == message.replyToId)
                                    .firstOrNull
                                : null;

                            final bubble = MessageBubble(
                              chatTheme: theme,
                              repliedMessage: repliedMsg,
                              message: message,
                              isMe: isMe,
                              isDark: isDark,
                              isGroup:
                                  _selectedConversation?.isGroupChat ?? false,
                              currentUserId: viewModel.currentUserId ?? '',
                              userNames: {
                                for (var u in viewModel.chatUsers) u.id: u.name,
                              },
                              onFileClick: (msg) => showDialog(
                                context: context,
                                builder: (ctx) =>
                                    FilePreviewDialog(message: msg),
                              ),
                              onReply: () =>
                                  setState(() => _replyingTo = message),
                              onReact: (reaction) async {
                                final myId = viewModel.currentUserId;
                                final myType = viewModel.currentUserType;
                                final currentReactions =
                                    List<MessageReaction>.from(
                                        message.reactions);
                                final existingReaction = currentReactions
                                    .where((r) => r.userId == myId)
                                    .firstOrNull;
                                if (existingReaction != null) {
                                  final withoutExisting = currentReactions
                                      .where((r) => r.userId != myId)
                                      .toList();
                                  if (existingReaction.reaction == reaction) {
                                    // Same reaction → toggle off
                                    setState(() {
                                      _messages = _messages
                                          .map((m) => m.id == message.id
                                              ? message.copyWith(
                                                  reactions: withoutExisting)
                                              : m)
                                          .toList();
                                    });
                                    await viewModel.removeReaction(
                                        message.id, reaction);
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
                                              ? message.copyWith(
                                                  reactions: newReactions)
                                              : m)
                                          .toList();
                                    });
                                    await viewModel.removeReaction(
                                        message.id, existingReaction.reaction);
                                    await viewModel.addReaction(
                                        message.id, reaction);
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
                                            ? message.copyWith(
                                                reactions: newReactions)
                                            : m)
                                        .toList();
                                  });
                                  await viewModel.addReaction(
                                      message.id, reaction);
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
                                      const SnackBar(
                                          content: Text('Could not download')),
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
                                      _selectedConversation!.id, message.id);
                                } else {
                                  await viewModel
                                      .unpinMessage(_selectedConversation!.id);
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
                            );
                            // End MessageBubble wrapper

                            if (showDateHeader) {
                              return Column(
                                children: [
                                  _buildDateHeader(message.createdAt,
                                      theme: theme),
                                  bubble,
                                ],
                              );
                            }
                            return bubble;
                          },
                        ),

              // Scroll to bottom button
              if (_showScrollToBottom)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    foregroundColor: CommonColors.primary,
                    elevation: 4,
                    onPressed: _scrollToBottom,
                    child: const Icon(Icons.arrow_downward_rounded),
                  ),
                ),
            ],
          ),
        ),

        // Typing indicator
        if (_typingUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      3,
                      (i) => TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.3, end: 1.0),
                        duration: Duration(milliseconds: 400 + (i * 200)),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) => Container(
                          width: 4,
                          height: 4 * value,
                          decoration: BoxDecoration(
                            color: CommonColors.primary.withOpacity(value),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getTypingText(),
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Reply Preview
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                top: BorderSide(
                  color: theme.id == 'default'
                      ? (isDark ? Colors.white10 : Colors.grey.shade200)
                      : textColor.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
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
                        'Replying to ${_replyingTo?.senderName ?? 'User'}',
                        style: TextStyle(
                          color: CommonColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _replyingTo?.content ?? 'Attachment',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _replyingTo = null);
                  },
                  icon: const Icon(Icons.close, size: 20),
                  color: secondaryTextColor,
                ),
              ],
            ),
          ),

        // Main Input Container
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: theme.id == 'default'
                  ? (isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.shade200)
                  : textColor.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Align items to center
            children: [
              // Attachment button
              Material(
                color: Colors.transparent,
                child: IconButton(
                  onPressed: () async {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
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
                            final teamSyncVM =
                                context.read<TeamSyncViewModel>();
                            final optimisticMessage =
                                await teamSyncVM.sendContactMessage(
                              _selectedConversation!.id,
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
                    Icons.add_circle_outline_rounded,
                    color: secondaryTextColor,
                    size: 24,
                  ),
                  tooltip: 'Attach',
                  splashRadius: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),

              // Text input
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  onChanged: (text) {
                    _handleTyping();
                    setState(
                        () {}); // Trigger rebuild to show/hide AI refine button
                  },
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: secondaryTextColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    suffixIcon: _messageController.text.isNotEmpty &&
                            !_isRefining
                        ? IconButton(
                            icon: const Icon(Icons.lightbulb_rounded,
                                color: Colors.amber, size: 20),
                            onPressed: _refineMessage,
                            tooltip: 'Refine with AI',
                            splashRadius: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : (_isRefining
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null),
                  ),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),

              // Emoji Picker Toggle
              IconButton(
                icon: Icon(
                  _showEmojiPicker
                      ? Icons.keyboard_alt_outlined
                      : Icons.emoji_emotions_outlined,
                  color: secondaryTextColor,
                  size: 22,
                ),
                onPressed: _toggleEmojiPicker,
                splashRadius: 20,
              ),

              const SizedBox(width: 4),

              // Send button
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x444F46E5),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  color: Colors.white,
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        // Emoji Picker
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _onEmojiSelected(emoji);
              },
              onBackspacePressed: _onBackspacePressed,
              config: Config(
                height: 256,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  // Default config will be used
                  buttonMode: ButtonMode.MATERIAL,
                ),
                categoryViewConfig: CategoryViewConfig(
                  initCategory: Category.RECENT,
                  iconColor: Colors.grey,
                  iconColorSelected: CommonColors.primary,
                  backspaceColor: CommonColors.primary,
                  tabIndicatorAnimDuration: kTabScrollDuration,
                  categoryIcons: const CategoryIcons(),
                  recentTabBehavior: RecentTabBehavior.RECENT,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  enabled: false,
                  backgroundColor: surfaceColor,
                  buttonColor: surfaceColor,
                  buttonIconColor: Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _refineMessage() async {
    if (_messageController.text.trim().isEmpty || _isRefining) return;

    setState(() => _isRefining = true);

    try {
      final response = await _aiApi.sendMessage(
        "Correct the grammar, complete the sentence if it ends abruptly, and refine this message to be clear and professional. Return ONLY the refined text: ${_messageController.text}",
      );

      if (response.success && response.data != null) {
        final refinedText = response.data['response']?.toString();
        if (refinedText != null) {
          setState(() {
            _messageController.text = refinedText;
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: refinedText.length),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error refining message: $e');
    } finally {
      if (mounted) setState(() => _isRefining = false);
    }
  }

  Future<void> _handleAiAction(String action) async {
    if (_selectedConversation == null) return;

    final conversationId = _selectedConversation!.id;

    String prompt = "";
    if (action == 'Summary') {
      prompt =
          "Please provide a concise summary of the recent messages in this conversation (ID: $conversationId). Identify key decisions and action items.";
    } else if (action == 'Catch-up') {
      prompt =
          "What did I miss in this conversation (ID: $conversationId)? Give me a quick briefing on the most recent discussions.";
    }

    // For now, toggle the sidebar. Real implementation will pass the prompt to the sidebar.
    setState(() {
      _aiPrompt = prompt;
      _showAiSidebar = true;
    });

    debugPrint('AI Action: $action with prompt: $prompt');
  }

  void _showChatInfo(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ChatInfoSheet(
          conversation: _selectedConversation!,
          messages: _messages,
          initialIndex: 0,
          isDark: isDark,
          onClose: () => Navigator.pop(context),
          onMessageTap: (msg) {
            Navigator.pop(context);
            final index = _messages.indexWhere((m) => m.id == msg.id);
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
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              final vm = context.read<TeamSyncViewModel>();
              await vm.deleteConversation(_selectedConversation!.id);
              if (mounted) {
                setState(() => _selectedConversation = null);
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color ?? Colors.white, size: 22),
        tooltip: tooltip,
        splashRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
    ];
    return colors[name.length % colors.length];
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return DateFormat('EEE').format(time);
      return DateFormat('MMM d').format(time);
    }

    return DateFormat('h:mm a').format(time);
  }
}
