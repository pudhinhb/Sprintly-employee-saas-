import 'team_sync_message.dart';

/// User status enum for presence
enum UserStatus {
  active,
  away,
  inBreak,
  inMeeting,
  inLunch,
  offline;

  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.away:
        return 'Away';
      case UserStatus.inBreak:
        return 'In Break';
      case UserStatus.inMeeting:
        return 'In Meeting';
      case UserStatus.inLunch:
        return 'In Lunch';
      case UserStatus.offline:
        return 'Offline';
    }
  }

  static UserStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return UserStatus.active;
      case 'away':
        return UserStatus.away;
      case 'in_break':
      case 'inbreak':
        return UserStatus.inBreak;
      case 'in_meeting':
      case 'inmeeting':
        return UserStatus.inMeeting;
      case 'in_lunch':
      case 'inlunch':
        return UserStatus.inLunch;
      default:
        return UserStatus.offline;
    }
  }
}

/// Chat Conversation Model for TeamSync
class TeamSyncConversation {
  final String id;
  final String? name;
  final String? description;
  final ConversationType type;
  final String? avatarUrl;
  final String createdBy;
  final String createdByType;
  final bool isActive;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ConversationParticipant> participants;
  final TeamSyncMessage? lastMessage;
  final int unreadCount;
  final bool isMuted;
  final String? displayName;
  final String? displayImage;
  final String? otherUserId;
  final String? otherUserType;
  final bool? otherUserOnline;
  final String? otherUserDesignation;
  final bool isPinned;
  final UserStatus? otherUserStatus;
  final DateTime? otherUserLastSeen;
  final bool isPublic;
  final String? inviteCode;

  const TeamSyncConversation({
    required this.id,
    this.name,
    this.description,
    required this.type,
    this.avatarUrl,
    required this.createdBy,
    required this.createdByType,
    this.isActive = true,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
    this.isMuted = false,
    this.displayName,
    this.displayImage,
    this.otherUserId,
    this.otherUserType,
    this.otherUserOnline,
    this.otherUserDesignation,
    this.isPinned = false,
    this.otherUserStatus,
    this.otherUserLastSeen,
    this.isPublic = false,
    this.inviteCode,
  });

  bool get isGroupChat => type == ConversationType.group;
  bool get isDirectMessage => type == ConversationType.direct;
  String get effectiveDisplayName => displayName ?? name ?? 'Unknown';
  String? get effectiveDisplayImage => displayImage ?? avatarUrl;

  ConversationParticipant? getOtherParticipant(String currentUserId) {
    if (!isDirectMessage) return null;
    return participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants.isNotEmpty
          ? participants.first
          : ConversationParticipant.empty(),
    );
  }

  factory TeamSyncConversation.fromJson(Map<String, dynamic> json) {
    TeamSyncMessage? lastMessage;
    if (json['last_message'] != null) {
      if (json['last_message'] is Map<String, dynamic>) {
        lastMessage = TeamSyncMessage.fromJson(
          json['last_message'] as Map<String, dynamic>,
        );
      }
    }

    List<ConversationParticipant> participants = [];
    if (json['participants'] != null && json['participants'] is List) {
      participants = (json['participants'] as List)
          .map((e) =>
              ConversationParticipant.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    String? nonEmptyString(dynamic value) {
      final str = value?.toString();
      return (str == null || str.isEmpty) ? null : str;
    }

    return TeamSyncConversation(
      id: json['id']?.toString() ?? '',
      name: nonEmptyString(json['name']),
      description: nonEmptyString(json['description']),
      type: _parseConversationType(json['type']?.toString()),
      avatarUrl: nonEmptyString(json['avatar_url']),
      createdBy: json['created_by']?.toString() ?? '',
      createdByType: json['created_by_type']?.toString() ?? 'Admin',
      isActive: json['is_active'] != false,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      participants: participants,
      lastMessage: lastMessage,
      unreadCount: json['unread_count'] as int? ?? 0,
      isMuted: json['is_muted'] == true,
      displayName: nonEmptyString(json['display_name']),
      displayImage: nonEmptyString(json['display_image']),
      otherUserId: nonEmptyString(json['other_user_id']),
      otherUserType: nonEmptyString(json['other_user_type']),
      otherUserOnline: json['other_user_online'] as bool?,
      otherUserDesignation: nonEmptyString(json['other_user_designation']),
      isPinned: json['is_pinned'] == true,
      otherUserStatus: UserStatus.fromString(
        json['other_user_status']?.toString(),
      ),
      otherUserLastSeen: json['other_user_last_seen'] != null
          ? DateTime.tryParse(json['other_user_last_seen'].toString())
          : null,
      isPublic: json['is_public'] == true,
      inviteCode: nonEmptyString(json['invite_code']),
    );
  }

  static ConversationType _parseConversationType(String? type) {
    switch (type) {
      case 'group':
        return ConversationType.group;
      case 'announcement':
        return ConversationType.announcement;
      default:
        return ConversationType.direct;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'avatar_url': avatarUrl,
      'created_by': createdBy,
      'created_by_type': createdByType,
      'is_active': isActive,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'participants': participants.map((e) => e.toJson()).toList(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'is_muted': isMuted,
    };
  }

  TeamSyncConversation copyWith({
    String? id,
    String? name,
    String? description,
    ConversationType? type,
    String? avatarUrl,
    String? createdBy,
    String? createdByType,
    bool? isActive,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ConversationParticipant>? participants,
    TeamSyncMessage? lastMessage,
    int? unreadCount,
    bool? isMuted,
    String? displayName,
    String? displayImage,
    String? otherUserId,
    String? otherUserType,
    bool? otherUserOnline,
    String? otherUserDesignation,
    bool? isPinned,
    UserStatus? otherUserStatus,
    DateTime? otherUserLastSeen,
    bool? isPublic,
    String? inviteCode,
  }) {
    return TeamSyncConversation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdBy: createdBy ?? this.createdBy,
      createdByType: createdByType ?? this.createdByType,
      isActive: isActive ?? this.isActive,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      displayName: displayName ?? this.displayName,
      displayImage: displayImage ?? this.displayImage,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserType: otherUserType ?? this.otherUserType,
      otherUserOnline: otherUserOnline ?? this.otherUserOnline,
      otherUserDesignation: otherUserDesignation ?? this.otherUserDesignation,
      isPinned: isPinned ?? this.isPinned,
      otherUserStatus: otherUserStatus ?? this.otherUserStatus,
      otherUserLastSeen: otherUserLastSeen ?? this.otherUserLastSeen,
      isPublic: isPublic ?? this.isPublic,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}

enum ConversationType { direct, group, announcement }

/// Conversation Participant Model
class ConversationParticipant {
  final String id;
  final String? participantId;
  final String conversationId;
  final String userId;
  final String userType;
  final String? userName;
  final String? userImage;
  final String? userDesignation;
  final String role;
  final String? nickname;
  final bool isMuted;
  final DateTime? mutedUntil;
  final DateTime? lastReadAt;
  final String? lastReadMessageId;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isActive;
  final bool isOnline;
  final DateTime? lastSeenAt;

  ConversationParticipant({
    this.id = '',
    this.participantId,
    this.conversationId = '',
    required this.userId,
    required this.userType,
    this.userName,
    this.userImage,
    this.userDesignation,
    this.role = 'member',
    this.nickname,
    this.isMuted = false,
    this.mutedUntil,
    this.lastReadAt,
    this.lastReadMessageId,
    DateTime? joinedAt,
    this.leftAt,
    this.isActive = true,
    this.isOnline = false,
    this.lastSeenAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory ConversationParticipant.empty() {
    return ConversationParticipant(userId: '', userType: 'Employee');
  }

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    String? nonEmptyString(dynamic value) {
      final str = value?.toString();
      return (str == null || str.isEmpty) ? null : str;
    }

    return ConversationParticipant(
      id: json['id']?.toString() ?? '',
      participantId: nonEmptyString(json['participant_id']),
      conversationId: json['conversation_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? 'Employee',
      userName: nonEmptyString(json['user_name']),
      userImage: nonEmptyString(json['user_image']),
      userDesignation: nonEmptyString(json['user_designation']),
      role: json['role']?.toString() ?? 'member',
      nickname: nonEmptyString(json['nickname']),
      isMuted: json['is_muted'] == true,
      mutedUntil: json['muted_until'] != null
          ? DateTime.tryParse(json['muted_until'].toString())
          : null,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.tryParse(json['last_read_at'].toString())
          : null,
      lastReadMessageId: nonEmptyString(json['last_read_message_id']),
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'].toString())
          : DateTime.now(),
      leftAt: json['left_at'] != null
          ? DateTime.tryParse(json['left_at'].toString())
          : null,
      isActive: json['is_active'] != false,
      isOnline: json['is_online'] == true,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_id': participantId,
      'conversation_id': conversationId,
      'user_id': userId,
      'user_type': userType,
      'user_name': userName,
      'user_image': userImage,
      'user_designation': userDesignation,
      'role': role,
      'nickname': nickname,
      'is_muted': isMuted,
      'muted_until': mutedUntil?.toIso8601String(),
      'last_read_at': lastReadAt?.toIso8601String(),
      'last_read_message_id': lastReadMessageId,
      'joined_at': joinedAt.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'is_active': isActive,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt?.toIso8601String(),
    };
  }
}

/// Chat User - for user list when starting new chat
class TeamSyncUser {
  final String id;
  final String userType;
  final String name;
  final String? image;
  final String? designation;
  final String? role;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const TeamSyncUser({
    required this.id,
    required this.userType,
    required this.name,
    this.image,
    this.designation,
    this.role,
    this.isOnline = false,
    this.lastSeenAt,
  });

  factory TeamSyncUser.fromJson(Map<String, dynamic> json) {
    String? nonEmptyString(dynamic value) {
      final str = value?.toString();
      return (str == null || str.isEmpty) ? null : str;
    }

    return TeamSyncUser(
      id: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? 'Employee',
      name: json['name']?.toString() ?? 'Unknown',
      image: nonEmptyString(json['image']),
      designation: nonEmptyString(json['designation']),
      role: nonEmptyString(json['role']),
      isOnline: json['is_online'] == true,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'user_type': userType,
      'name': name,
      'image': image,
      'designation': designation,
      'role': role,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt?.toIso8601String(),
    };
  }
}
