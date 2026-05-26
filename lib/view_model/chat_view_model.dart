import 'package:flutter/material.dart';
import 'package:webnox_taskops/model/employee_model.dart';
import 'package:webnox_taskops/services/chat_service.dart';
import 'package:webnox_taskops/model/chat_message_model.dart';
import 'package:webnox_taskops/model/chat_conversation_model.dart';

class ChatViewModel extends ChangeNotifier {
  List<ChatConversation> _conversations = [];
  List<ChatMessage> _currentMessages = [];
  List<Employee> _employees = [];
  ChatConversation? _selectedConversation;
  Employee? _selectedEmployee;
  bool _isLoading = false;
  String? _error;

  // Realtime channels removed as Supabase is removed
  // We will need a WebSocket service for this in the future

  // Getters
  List<ChatConversation> get conversations => _conversations;
  List<ChatMessage> get currentMessages => _currentMessages;
  List<Employee> get employees => _employees;
  ChatConversation? get selectedConversation => _selectedConversation;
  Employee? get selectedEmployee => _selectedEmployee;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Load conversations for a user
  Future<void> loadConversations(String userId) async {
    try {
      _setLoading(true);
      _setError(null);

      final conversations = await ChatService.getConversations(userId);
      _conversations = conversations;

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load conversations: $e');
      _setLoading(false);
    }
  }

  // Load messages for a conversation
  Future<void> loadMessages(String conversationId) async {
    try {
      _setLoading(true);
      _setError(null);

      final messages = await ChatService.getMessages(conversationId);
      _currentMessages = messages;

      // Debug print
      print('=== ChatViewModel.loadMessages ===');
      print('Conversation ID: $conversationId');
      print('Messages loaded: ${messages.length}');

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load messages: $e');
      _setLoading(false);
    }
  }

  // Load employees for chat
  Future<void> loadEmployees(String currentUserId) async {
    try {
      _setLoading(true);
      _setError(null);

      final employees = await ChatService.getEmployeesForChat(currentUserId);
      _employees = employees;

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load employees: $e');
      _setLoading(false);
    }
  }

  // Select a conversation
  void selectConversation(ChatConversation conversation) {
    _selectedConversation = conversation;
    notifyListeners();
  }

  // Select an employee to start chat
  void selectEmployee(Employee employee) {
    _selectedEmployee = employee;
    notifyListeners();
  }

  // Send a message
  Future<bool> sendMessage({
    required String message,
    required String senderId,
    String? replyToMessageId,
  }) async {
    try {
      if (_selectedConversation == null) {
        _setError('No conversation selected');
        return false;
      }

      final receiverId = _selectedConversation!.getOtherParticipantId(senderId);

      final chatMessage = await ChatService.sendMessage(
        conversationId: _selectedConversation!.conversationId,
        senderId: senderId,
        receiverId: receiverId,
        message: message, // Check parameters match ChatService
        replyToMessageId: replyToMessageId,
      );

      if (chatMessage != null) {
        _currentMessages.add(chatMessage);

        // Update conversation in list
        final index = _conversations.indexWhere(
          (c) => c.conversationId == _selectedConversation!.conversationId,
        );
        if (index != -1) {
          _conversations[index] = _conversations[index].copyWith(
            lastMessage: message,
            lastMessageTime: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _setError('Failed to send message: $e');
      return false;
    }
  }

  // Start a new conversation
  Future<bool> startNewConversation(
      String currentUserId, String otherUserId) async {
    try {
      _setLoading(true);
      _setError(null);

      final conversationId = await ChatService.getOrCreateConversation(
        currentUserId,
        otherUserId,
      );

      if (conversationId != null) {
        // Find the employee
        final employee = _employees.firstWhere(
          (e) => e.employeeId == otherUserId,
          orElse: () => Employee(
              employeeId: otherUserId,
              employeeName: 'Unknown',
              employeeCompanyEmail: '',
              employeeImg: '',
              employeeRole: '',
              employeeDesignation: ''),
        );

        // Create a new conversation object
        final newConversation = ChatConversation(
          conversationId: conversationId,
          participant1Id: currentUserId,
          participant2Id: otherUserId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        _selectedConversation = newConversation;
        _selectedEmployee = employee;

        // Remove existing conversation from list if presents and add to top
        _conversations.removeWhere((c) => c.conversationId == conversationId);
        _conversations.insert(0, newConversation);

        _currentMessages.clear();

        notifyListeners();
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to start conversation: $e');
      _setLoading(false);
      return false;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String userId) async {
    if (_selectedConversation != null) {
      try {
        await ChatService.markMessagesAsRead(
          _selectedConversation!.conversationId,
          userId,
        );

        // Update local state
        for (int i = 0; i < _currentMessages.length; i++) {
          if (_currentMessages[i].receiverId == userId) {
            _currentMessages[i] = _currentMessages[i].copyWith(isRead: true);
          }
        }

        notifyListeners();
      } catch (e) {
        print('Error marking messages as read: $e');
      }
    }
  }

  // Get conversations for a specific employee
  List<ChatConversation> getConversationsForEmployee(String employeeId) {
    return _conversations
        .where((conv) =>
            conv.participant1Id == employeeId ||
            conv.participant2Id == employeeId)
        .toList();
  }

  // Get or create conversation with an employee
  Future<ChatConversation?> getOrCreateConversationWithEmployee(
      String currentUserId, String employeeId) async {
    try {
      // Check if conversation already exists
      final existingConversation = _conversations.firstWhere(
        (conv) =>
            conv.participant1Id == employeeId ||
            conv.participant2Id == employeeId,
        orElse: () => ChatConversation(
          conversationId: '',
          participant1Id: '',
          participant2Id: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (existingConversation.conversationId.isNotEmpty) {
        return existingConversation;
      }

      // Create new conversation
      final success = await startNewConversation(currentUserId, employeeId);
      if (success && _selectedConversation != null) {
        return _selectedConversation;
      }

      return null;
    } catch (e) {
      _setError('Failed to get or create conversation: $e');
      return null;
    }
  }

  // Clear current conversation
  void clearCurrentConversation() {
    _selectedConversation = null;
    _selectedEmployee = null;
    _currentMessages.clear();
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _setError(null);
  }

  // Refresh conversations
  Future<void> refreshConversations(String userId) async {
    await loadConversations(userId);
  }

  // Refresh messages
  Future<void> refreshMessages() async {
    if (_selectedConversation != null) {
      await loadMessages(_selectedConversation!.conversationId);
    }
  }

  // Refresh current conversation and messages
  Future<void> refreshCurrentConversation() async {
    if (_selectedConversation != null) {
      // Refresh messages
      await loadMessages(_selectedConversation!.conversationId);

      // Refresh conversations to update last message and unread count
      if (_conversations.isNotEmpty) {
        final userId = _conversations.first.participant1Id;
        await refreshConversations(userId);
      }
    }
  }

  // Debug method to check all messages for a user
  Future<void> debugUserMessages(String userId) async {
    // Debug implementation
  }

  // Add test message for debugging left/right layout
  void addTestMessage(ChatMessage testMessage) {
    _currentMessages.insert(0, testMessage);
    notifyListeners();
  }

  // Subscribe to real-time message updates for a specific conversation
  void subscribeToMessages(String conversationId) {
    // Supabase realtime disabled
  }

  // Subscribe to all messages for the current user
  void subscribeToAllUserMessages(String userId) {
    // Supabase realtime disabled
  }

  // Subscribe to conversation updates
  void subscribeToConversations(String userId) {
    // Supabase realtime disabled
  }

  // Unsubscribe from all channels
  void unsubscribeFromChannels() {
    // Supabase realtime disabled
  }

  @override
  void dispose() {
    unsubscribeFromChannels();
    super.dispose();
  }
}
