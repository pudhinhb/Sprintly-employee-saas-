class Project {
  final String projectId;
  final String projectName;
  final String? projectImg;
  final String? projectDescription;
  final List<dynamic>? projectRequirements; // JSONB
  final String? projectStartDate;
  final String? projectEndDate;
  final String? projectMVPDate;
  final String? projectStatus;
  final String? priorityLevel;
  final String? projectType;
  final String? projectTeamLeaderId;
  final String? projectManagerId;
  final List<Map<String, dynamic>>
      teamMembers; // Maps to project_team_member_ids (JSONB)
  final List<String>
      followedByEmployees; // Maps to project_followed_by_bde_employee_ids (JSONB)

  // Sub-resources (Lists of Maps)
  final List<Map<String, dynamic>> projectDocuments;
  final List<Map<String, dynamic>> projectFigmaUrls;
  final List<Map<String, dynamic>> projectMilestones;
  final List<Map<String, dynamic>> projectReleases;

  // Client Details
  final String? clientName;
  final String? companyName;
  final String? clientType;
  final String? clientAddress;
  final String? clientCountry;
  final String? clientPhone;

  final String? createdBy;
  final String? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  // Legacy/Computed fields (kept for compatibility if needed, or mapped from new structure)
  // Legacy/Computed fields (kept for compatibility if needed, or mapped from new structure)
  // final List<String> projectScopeDocUrl; // Deprecated
  // final List<String> projectFigmaUrl; // Deprecated
  // final Map<String, dynamic>? milestones; // Deprecated

  Project({
    required this.projectId,
    required this.projectName,
    this.projectImg,
    this.projectDescription,
    this.projectRequirements,
    this.projectStartDate,
    this.projectEndDate,
    this.projectMVPDate,
    this.projectStatus,
    this.priorityLevel,
    this.projectType,
    this.projectTeamLeaderId,
    this.projectManagerId,
    this.teamMembers = const [],
    this.followedByEmployees = const [],
    this.projectDocuments = const [],
    this.projectFigmaUrls = const [],
    this.projectMilestones = const [],
    this.projectReleases = const [],
    this.clientName,
    this.companyName,
    this.clientType,
    this.clientAddress,
    this.clientCountry,
    this.clientPhone,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      projectId: json['project_id']?.toString() ?? '',
      projectName: json['project_name']?.toString() ?? '',
      projectImg: json['project_img']?.toString(),
      projectDescription: json['project_description']?.toString(),
      projectRequirements: json['project_requirements'] as List<dynamic>?,
      projectStartDate: json['project_start_date']?.toString(),
      projectEndDate: json['project_end_date']?.toString(),
      projectMVPDate: json['project_mvp_date']?.toString(),
      projectStatus: json['project_status']?.toString(),
      priorityLevel: json['project_priority_level']?.toString() ??
          json['priority_level']?.toString(),
      projectType: json['project_type']?.toString(),
      projectTeamLeaderId: json['project_team_leader_id']?.toString(),
      projectManagerId: json['project_manager_id']?.toString(),

      // Handle team members (JSONB list of strings or objects)
      // Handle team members (JSONB list of strings or objects)
      teamMembers: _safeTeamMembersFromJson(json['project_team_member_ids'] ??
              json['team_members'] ??
              json['project_members']) ??
          [],

      followedByEmployees: _safeStringListFromJson(
          json['project_followed_by_bde_employee_ids'] ??
              json['followed_by_employees']),

      clientName: json['client_name']?.toString(),
      companyName: json['company_name']?.toString(),
      clientType: json['client_type']?.toString(),
      clientAddress: json['client_address']?.toString(),
      clientCountry: json['client_country']?.toString(),
      clientPhone: json['client_phone']?.toString(),

      createdBy: json['project_created_by']?.toString() ??
          json['created_by']?.toString(),
      updatedBy: json['project_updated_by']?.toString() ??
          json['updated_by']?.toString(),
      createdAt: json['project_created_at']?.toString() ??
          json['created_at']?.toString(),
      updatedAt: json['project_updated_at']?.toString() ??
          json['updated_at']?.toString(),

      // Sub-resources
      projectDocuments: _safeListMapFromJson(
          json['project_documents'] ?? json['project_scope_doc_url']),
      projectFigmaUrls: _safeListMapFromJson(
          json['project_figma_urls'] ?? json['project_figma_url']),
      projectMilestones: _safeListMapFromJson(
          json['project_milestones'] ?? json['milestones']),
      projectReleases: _safeListMapFromJson(json['project_releases']),
    );
  }

  // Helper method to safely convert dynamic to List<String>
  static List<String> _safeStringListFromJson(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  // Helper method to safely convert dynamic to List<Map<String, dynamic>>
  static List<Map<String, dynamic>>? _safeTeamMembersFromJson(dynamic data) {
    if (data == null) return null;
    if (data is List) {
      return data.map((e) {
        if (e is Map<String, dynamic>) {
          return e;
        } else if (e is Map) {
          return Map<String, dynamic>.from(e);
        } else if (e is String) {
          return <String, dynamic>{'employee_id': e, 'employeeId': e};
        }
        return <String, dynamic>{};
      }).toList();
    }
    return null;
  }

  // Helper method to safely convert dynamic to Map<String, dynamic>
  // Helper method to safely convert dynamic to List<Map<String, dynamic>>
  static List<Map<String, dynamic>> _safeListMapFromJson(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) {
        if (e is Map<String, dynamic>) {
          return e;
        } else if (e is Map) {
          return Map<String, dynamic>.from(e);
        }
        // If it's a string (legacy URL), wrap it in an object for consistency
        else if (e is String) {
          return <String, dynamic>{'url': e, 'name': 'Document'};
        }
        return <String, dynamic>{};
      }).toList();
    }
    // Handle legacy definition where milestones was a Map
    if (data is Map) {
      // If it's a map (legacy milestones), convert values to list
      return data.values.map((e) {
        if (e is Map<String, dynamic>) return e;
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'project_name': projectName,
      'project_img': projectImg,
      'project_description': projectDescription,
      'project_requirements': projectRequirements,
      'project_start_date': projectStartDate,
      'project_end_date': projectEndDate,
      'project_mvp_date': projectMVPDate,
      'project_status': projectStatus,
      'project_priority_level': priorityLevel,
      'project_type': projectType,
      'project_team_leader_id': projectTeamLeaderId,
      'project_manager_id': projectManagerId,
      'project_team_member_ids':
          teamMembers, // Or should we send just IDs? keeping full object for now.
      'project_followed_by_bde_employee_ids': followedByEmployees,
      'client_name': clientName,
      'company_name': companyName,
      'client_type': clientType,
      'client_address': clientAddress,
      'client_country': clientCountry,
      'client_phone': clientPhone,
      'project_created_by': createdBy,
      'project_updated_by': updatedBy,
      'project_created_at': createdAt,
      'project_updated_at': updatedAt,
      // Extras
      'project_documents': projectDocuments,
      'project_figma_urls': projectFigmaUrls,
      'project_milestones': projectMilestones,
      'project_releases': projectReleases,
    };
  }

  // Helper method to check if an employee is in the team
  bool isEmployeeInTeam(String employeeId) {
    // Check direct roles first
    if (projectTeamLeaderId == employeeId ||
        projectManagerId == employeeId ||
        createdBy == employeeId) {
      return true;
    }

    if (teamMembers.isEmpty) {
      return false;
    }

    return teamMembers.any((member) =>
        member['employee_id'] == employeeId ||
        member['employeeId'] == employeeId ||
        member['id'] == employeeId);
  }

  // Format start date for display
  String? getFormattedStartDate() {
    if (projectStartDate == null || projectStartDate!.isEmpty) return null;

    try {
      final date = DateTime.parse(projectStartDate!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return projectStartDate;
    }
  }

  // Format end date for display
  String? getFormattedEndDate() {
    if (projectEndDate == null || projectEndDate!.isEmpty) return null;

    try {
      final date = DateTime.parse(projectEndDate!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return projectEndDate;
    }
  }

  // Calculate and return project duration
  String? getProjectDuration() {
    if (projectStartDate == null ||
        projectEndDate == null ||
        projectStartDate!.isEmpty ||
        projectEndDate!.isEmpty) return null;

    try {
      final startDate = DateTime.parse(projectStartDate!);
      final endDate = DateTime.parse(projectEndDate!);
      final duration = endDate.difference(startDate);

      final days = duration.inDays;
      final weeks = (days / 7).floor();
      final months = (days / 30).floor();
      final years = (days / 365).floor();

      if (years > 0) {
        return '$years year${years > 1 ? 's' : ''}';
      } else if (months > 0) {
        return '$months month${months > 1 ? 's' : ''}';
      } else if (weeks > 0) {
        return '$weeks week${weeks > 1 ? 's' : ''}';
      } else {
        return '$days day${days > 1 ? 's' : ''}';
      }
    } catch (e) {
      return 'Invalid dates';
    }
  }
}
