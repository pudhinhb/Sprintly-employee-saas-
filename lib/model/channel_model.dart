/// Channel model for Syn Board Slack-like chat
/// Represents a public or private channel that users can join and send messages in

enum ChannelType {
  public,
  private,
  dm,
}

class Channel {
  final String id;
  final String name;
  final String? description;
  final ChannelType type;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final String? lastMessageSender;
  final int memberCount;
  final bool isArchived;
  final List<Map<String, dynamic>>? members; // Lightweight member info

  Channel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessage,
    this.lastMessageSender,
    this.memberCount = 0,
    this.isArchived = false,
    this.members,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        type: json['type'] == 'private'
            ? ChannelType.private
            : json['type'] == 'dm'
                ? ChannelType.dm
                : ChannelType.public,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.parse(json['last_message_at'] as String)
            : null,
        lastMessage: json['last_message'] as String?,
        lastMessageSender: json['last_message_sender'] as String?,
        memberCount: json['member_count'] as int? ?? 0,
        isArchived: json['is_archived'] as bool? ?? false,
        members: json['channel_members'] != null
            ? List<Map<String, dynamic>>.from(json['channel_members'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type == ChannelType.private ? 'private' : 'public',
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'last_message_at': lastMessageAt?.toIso8601String(),
        'last_message': lastMessage,
        'last_message_sender': lastMessageSender,
        'member_count': memberCount,
        'is_archived': isArchived,
      };

  Channel copyWith({
    String? id,
    String? name,
    String? description,
    ChannelType? type,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    String? lastMessage,
    String? lastMessageSender,
    int? memberCount,
    bool? isArchived,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      memberCount: memberCount ?? this.memberCount,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  /// Check if channel is public
  bool get isPublic => type == ChannelType.public;

  /// Check if channel is private
  bool get isPrivate => type == ChannelType.private;
  bool get isDm => type == ChannelType.dm;

  /// Get channel icon based on type
  String get icon => isPrivate
      ? '🔒'
      : isDm
          ? '💬'
          : '#';

  /// Get display name (handles DMs by showing other user's name)
  String getDisplayName(String currentUserId) {
    if (!isDm) return name;

    print(
        'DEBUG getDisplayName: channel=$name, currentUserId=$currentUserId, members=${members?.length}');
    if (members != null && members!.isNotEmpty) {
      print('DEBUG members: $members');
      // Find the other member (not the current user)
      for (final member in members!) {
        final employeeId = member['employee_id'];
        if (employeeId != null && employeeId != currentUserId) {
          // Try to get name from nested employees object
          final employeeData = member['employees'];
          if (employeeData != null && employeeData is Map) {
            final employeeName = employeeData['employee_name'];
            if (employeeName != null && employeeName.toString().isNotEmpty) {
              return employeeName.toString();
            }
          }
          // Fallback: try direct employee_name field
          final directName = member['employee_name'];
          if (directName != null && directName.toString().isNotEmpty) {
            return directName.toString();
          }
        }
      }
    }

    // Final fallback: If the channel name contains "dm-", try to return something meaningful
    if (name.startsWith('dm-')) {
      return 'Direct Message';
    }

    return name;
  }

  /// Get the ID of the other user in a DM
  String getOtherUserId(String currentUserId) {
    if (!isDm) return '';
    if (members != null && members!.isNotEmpty) {
      for (final member in members!) {
        final employeeId = member['employee_id'];
        if (employeeId != null && employeeId != currentUserId) {
          return employeeId.toString();
        }
      }
    }
    return '';
  }

  /// Get the profile image URL of the other user in a DM
  String? getOtherUserImageUrl(String currentUserId) {
    if (!isDm) return null;
    if (members != null && members!.isNotEmpty) {
      for (final member in members!) {
        final employeeId = member['employee_id'];
        if (employeeId != null && employeeId != currentUserId) {
          // Try to get image from nested employees object
          final employeeData = member['employees'];
          if (employeeData != null && employeeData is Map) {
            final imageUrl = employeeData['employee_img'];
            if (imageUrl != null && imageUrl.toString().isNotEmpty) {
              return imageUrl.toString();
            }
          }
          // Fallback: try direct employee_img field
          final directImg = member['employee_img'];
          if (directImg != null && directImg.toString().isNotEmpty) {
            return directImg.toString();
          }
        }
      }
    }
    return null;
  }

  @override
  String toString() => 'Channel(id: $id, name: $name, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
