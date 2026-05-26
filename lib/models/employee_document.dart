class EmployeeDocument {
  final String id;
  final String employeeId;
  final String documentName;
  final String? documentUrl;
  final String status;
  final bool isRequired;
  final String requestedBy;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final String? adminComments;

  EmployeeDocument({
    required this.id,
    required this.employeeId,
    required this.documentName,
    this.documentUrl,
    required this.status,
    required this.isRequired,
    required this.requestedBy,
    required this.createdAt,
    this.submittedAt,
    this.adminComments,
  });

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) {
    return EmployeeDocument(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ??
          json['employee_id']?.toString() ??
          '',
      documentName: json['documentName']?.toString() ??
          json['document_name']?.toString() ??
          '',
      documentUrl:
          json['documentUrl']?.toString() ?? json['document_url']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      isRequired: json['isRequired'] == true || json['is_required'] == true,
      requestedBy: json['requestedBy']?.toString() ??
          json['requested_by']?.toString() ??
          '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now()), // Fallback to now if missing
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'].toString())
          : (json['submitted_at'] != null
              ? DateTime.parse(json['submitted_at'].toString())
              : null),
      adminComments: json['adminComments']?.toString() ??
          json['admin_comments']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'document_name': documentName,
      'document_url': documentUrl,
      'status': status,
      'is_required': isRequired,
      'requested_by': requestedBy,
      'created_at': createdAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'admin_comments': adminComments,
    };
  }

  bool get isPending => status == 'pending';
  bool get isSubmitted => status == 'submitted';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
