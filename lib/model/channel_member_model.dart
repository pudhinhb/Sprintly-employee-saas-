/// Channel member model for Syn Board
/// Represents a user's membership in a channel with role and read status

enum MemberRole { owner, admin, member }

class ChannelMember {
  final String id;
  final String channelId;
  final String employeeId;
  final MemberRole role;
  final DateTime joinedAt;
  final DateTime? lastReadAt;
  final int unreadCount;
  final bool isMuted;

  // Joined employee data (populated when fetching with employee details)
  final String? employeeName;
  final String? employeeEmail;
  final String? profileImageUrl;
  final String? designation;

  ChannelMember({
    required this.id,
    required this.channelId,
    required this.employeeId,
    required this.role,
    required this.joinedAt,
    this.lastReadAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.employeeName,
    this.employeeEmail,
    this.profileImageUrl,
    this.designation,
  });

  factory ChannelMember.fromJson(Map<String, dynamic> json) {
    // Handle nested employee data if present
    final employee = json['employees'] as Map<String, dynamic>?;

    return ChannelMember(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      employeeId: json['employee_id'] as String,
      role: _parseRole(json['role'] as String?),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      isMuted: json['is_muted'] as bool? ?? false,
      employeeName: employee?['employee_name'] as String?,
      employeeEmail: employee?['employee_company_email'] as String?,
      profileImageUrl: employee?['employee_img'] as String?,
      designation: employee?['employee_designation'] as String?,
    );
  }

  static MemberRole _parseRole(String? role) {
    switch (role) {
      case 'owner':
        return MemberRole.owner;
      case 'admin':
        return MemberRole.admin;
      default:
        return MemberRole.member;
    }
  }

  static String _roleToString(MemberRole role) {
    switch (role) {
      case MemberRole.owner:
        return 'owner';
      case MemberRole.admin:
        return 'admin';
      case MemberRole.member:
        return 'member';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel_id': channelId,
        'employee_id': employeeId,
        'role': _roleToString(role),
        'joined_at': joinedAt.toIso8601String(),
        'last_read_at': lastReadAt?.toIso8601String(),
        'unread_count': unreadCount,
        'is_muted': isMuted,
      };

  ChannelMember copyWith({
    String? id,
    String? channelId,
    String? employeeId,
    MemberRole? role,
    DateTime? joinedAt,
    DateTime? lastReadAt,
    int? unreadCount,
    bool? isMuted,
    String? employeeName,
    String? employeeEmail,
    String? profileImageUrl,
    String? designation,
  }) {
    return ChannelMember(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      employeeId: employeeId ?? this.employeeId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      employeeName: employeeName ?? this.employeeName,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      designation: designation ?? this.designation,
    );
  }

  /// Check if member is channel owner
  bool get isOwner => role == MemberRole.owner;

  /// Check if member is admin (owner or admin role)
  bool get isAdmin => role == MemberRole.owner || role == MemberRole.admin;

  /// Check if member can manage channel (invite, edit, etc.)
  bool get canManage => isAdmin;

  /// Get display name (falls back to employee ID)
  String get displayName => employeeName ?? employeeId;

  /// Get initials for avatar
  String get initials {
    if (employeeName == null || employeeName!.isEmpty) {
      return employeeId.substring(0, 2).toUpperCase();
    }
    final parts = employeeName!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return employeeName!.substring(0, 2).toUpperCase();
  }

  @override
  String toString() =>
      'ChannelMember(id: $id, employeeId: $employeeId, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelMember &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
