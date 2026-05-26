class Employee {
  final String employeeId;
  final String? employeeRole;
  final String? employeeImg;
  final String? employeeName;
  final String? employeePhoneNum;
  final String? employeePersonalEmail;
  final String? employeeCompanyEmail;
  final String? employeeAddress;
  final String? employeeDesignation;
  final String? employeeDob;
  final int? employeeAge;
  final String? employeeDoj;
  final String? employeeBloodGroup;
  final String? employeeEmergencyContactNumber;
  final int? employeeActualSalary;
  final double? employeeTotalLeaveDaysInYear;
  final double? employeePendingLeaveCount;
  final String? employeeGender;
  final String? employeeUuid;
  final String? employeeQualification;
  final bool? status;

  Employee({
    required this.employeeId,
    this.employeeRole,
    this.employeeImg,
    this.employeeName,
    this.employeePhoneNum,
    this.employeePersonalEmail,
    this.employeeCompanyEmail,
    this.employeeAddress,
    this.employeeDesignation,
    this.employeeDob,
    this.employeeAge,
    this.employeeDoj,
    this.employeeBloodGroup,
    this.employeeEmergencyContactNumber,
    this.employeeActualSalary,
    this.employeeTotalLeaveDaysInYear,
    this.employeePendingLeaveCount,
    this.employeeGender,
    this.employeeUuid,
    this.employeeQualification,
    this.status,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        employeeId: json['employee_id'] as String,
        employeeRole: json['employee_role'] as String?,
        employeeImg: json['employee_img'] as String?,
        employeeName: json['employee_name'] as String?,
        employeePhoneNum: json['employee_phone_num'] as String?,
        employeePersonalEmail: json['employee_personal_email'] as String?,
        employeeCompanyEmail: json['employee_company_email'] as String?,
        employeeAddress: json['employee_address'] as String?,
        employeeDesignation: json['employee_designation'] as String?,
        employeeDob: json['employee_dob'] as String?,
        employeeAge: _toInt(json['employee_age']),
        employeeDoj: json['employee_doj'] as String?,
        employeeBloodGroup: json['employee_blood_group'] as String?,
        employeeEmergencyContactNumber:
            json['employee_emergency_contact_number'] as String?,
        employeeActualSalary: _toInt(json['employee_actual_salary']),
        employeeTotalLeaveDaysInYear:
            _toDouble(json['employee_total_leave_days_in_year']),
        employeePendingLeaveCount:
            _toDouble(json['employee_pending_leave_count']),
        employeeGender: json['employee_gender'] as String?,
        employeeUuid: json['employee_uuid'] as String?,
        employeeQualification: json['employee_qualification'] as String?,
        status: json['status'] as bool?,
      );

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'employee_role': employeeRole,
        'employee_img': employeeImg,
        'employee_name': employeeName,
        'employee_phone_num': employeePhoneNum,
        'employee_personal_email': employeePersonalEmail,
        'employee_company_email': employeeCompanyEmail,
        'employee_address': employeeAddress,
        'employee_designation': employeeDesignation,
        'employee_dob': employeeDob,
        'employee_age': employeeAge,
        'employee_doj': employeeDoj,
        'employee_blood_group': employeeBloodGroup,
        'employee_emergency_contact_number': employeeEmergencyContactNumber,
        'employee_actual_salary': employeeActualSalary,
        'employee_total_leave_days_in_year': employeeTotalLeaveDaysInYear,
        'employee_pending_leave_count': employeePendingLeaveCount,
        'employee_gender': employeeGender,
        'employee_uuid': employeeUuid,
        'employee_qualification': employeeQualification,
        'status': status,
      };

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final asDouble = double.tryParse(value);
      return asDouble?.toInt();
    }
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
