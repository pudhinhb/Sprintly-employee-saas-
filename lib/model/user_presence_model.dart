/// User presence model for Syn Board
/// Tracks online/away/offline status of users

enum PresenceStatus { online, away, offline }

class UserPresence {
  final String employeeId;
  final PresenceStatus status;
  final DateTime lastSeenAt;
  final String? currentChannelId;

  // Joined employee data
  final String? employeeName;
  final String? profileImageUrl;

  UserPresence({
    required this.employeeId,
    required this.status,
    required this.lastSeenAt,
    this.currentChannelId,
    this.employeeName,
    this.profileImageUrl,
  });

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    final employee = json['employees'] as Map<String, dynamic>?;

    return UserPresence(
      employeeId: json['employee_id'] as String,
      status: _parseStatus(json['status'] as String?),
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : DateTime.now(),
      currentChannelId: json['current_channel_id'] as String?,
      employeeName: employee?['employee_name'] as String?,
      profileImageUrl: employee?['employee_img'] as String?,
    );
  }

  static PresenceStatus _parseStatus(String? status) {
    switch (status) {
      case 'online':
        return PresenceStatus.online;
      case 'away':
        return PresenceStatus.away;
      default:
        return PresenceStatus.offline;
    }
  }

  static String _statusToString(PresenceStatus status) {
    switch (status) {
      case PresenceStatus.online:
        return 'online';
      case PresenceStatus.away:
        return 'away';
      case PresenceStatus.offline:
        return 'offline';
    }
  }

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'status': _statusToString(status),
        'last_seen_at': lastSeenAt.toIso8601String(),
        'current_channel_id': currentChannelId,
      };

  UserPresence copyWith({
    String? employeeId,
    PresenceStatus? status,
    DateTime? lastSeenAt,
    String? currentChannelId,
    String? employeeName,
    String? profileImageUrl,
  }) {
    return UserPresence(
      employeeId: employeeId ?? this.employeeId,
      status: status ?? this.status,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      currentChannelId: currentChannelId ?? this.currentChannelId,
      employeeName: employeeName ?? this.employeeName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  // Time thresholds for presence calculation
  static const _onlineThresholdMinutes = 20; // < 20 min = online
  static const _awayThresholdMinutes =
      60; // 20-60 min = away, > 60 min = offline

  /// Calculate effective status based on last_seen_at timestamp
  /// This provides time-based presence regardless of stored status
  PresenceStatus get effectiveStatus {
    final minutesSinceLastSeen =
        DateTime.now().difference(lastSeenAt).inMinutes;

    if (minutesSinceLastSeen < _onlineThresholdMinutes) {
      return PresenceStatus.online; // 🟢 Active within 20 min
    } else if (minutesSinceLastSeen < _awayThresholdMinutes) {
      return PresenceStatus.away; // 🟡 20-60 min
    } else {
      return PresenceStatus.offline; // ⚪ > 60 min
    }
  }

  /// Check if user is online (based on time)
  bool get isOnline => effectiveStatus == PresenceStatus.online;

  /// Check if user is away (based on time)
  bool get isAway => effectiveStatus == PresenceStatus.away;

  /// Check if user is offline (based on time)
  bool get isOffline => effectiveStatus == PresenceStatus.offline;

  /// Get status color for UI (uses effective status)
  String get statusColorHex {
    switch (effectiveStatus) {
      case PresenceStatus.online:
        return '#22C55E'; // Green
      case PresenceStatus.away:
        return '#F59E0B'; // Yellow/Orange
      case PresenceStatus.offline:
        return '#6B7280'; // Gray
    }
  }

  /// Get Color object for UI (uses effective status)
  int get statusColorValue {
    switch (effectiveStatus) {
      case PresenceStatus.online:
        return 0xFF22C55E; // Green
      case PresenceStatus.away:
        return 0xFFF59E0B; // Yellow/Orange
      case PresenceStatus.offline:
        return 0xFF9CA3AF; // Gray
    }
  }

  /// Get status display text (uses effective status)
  String get statusText {
    switch (effectiveStatus) {
      case PresenceStatus.online:
        return 'Online';
      case PresenceStatus.away:
        return 'Away';
      case PresenceStatus.offline:
        return _formatLastSeen();
    }
  }

  String _formatLastSeen() {
    final diff = DateTime.now().difference(lastSeenAt);
    if (diff.inMinutes < 1) {
      return 'Last seen just now';
    } else if (diff.inHours < 1) {
      return 'Last seen ${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return 'Last seen ${diff.inHours}h ago';
    } else {
      return 'Last seen ${diff.inDays}d ago';
    }
  }

  /// Get display name
  String get displayName => employeeName ?? employeeId;

  @override
  String toString() => 'UserPresence(employeeId: $employeeId, status: $status)';
}

/// Typing indicator model
class TypingIndicator {
  final String id;
  final String channelId;
  final String employeeId;
  final DateTime startedAt;

  // Joined employee data
  final String? employeeName;

  TypingIndicator({
    required this.id,
    required this.channelId,
    required this.employeeId,
    required this.startedAt,
    this.employeeName,
  });

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    final employee = json['employees'] as Map<String, dynamic>?;

    return TypingIndicator(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      employeeId: json['employee_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      employeeName: employee?['employee_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel_id': channelId,
        'employee_id': employeeId,
        'started_at': startedAt.toIso8601String(),
      };

  /// Get display name for typing indicator
  String get displayName => employeeName ?? employeeId;

  /// Check if typing indicator is still valid (within 1.5 seconds - matches refresh rate)
  bool get isValid =>
      DateTime.now().difference(startedAt).inMilliseconds < 1500;

  TypingIndicator copyWith({
    String? id,
    String? channelId,
    String? employeeId,
    DateTime? startedAt,
    String? employeeName,
  }) {
    return TypingIndicator(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      employeeId: employeeId ?? this.employeeId,
      startedAt: startedAt ?? this.startedAt,
      employeeName: employeeName ?? this.employeeName,
    );
  }

  @override
  String toString() =>
      'TypingIndicator(employeeId: $employeeId, channelId: $channelId)';
}
