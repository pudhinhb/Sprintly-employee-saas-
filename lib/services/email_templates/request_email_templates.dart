/// Email Templates for Request Notifications
///
/// This file contains email templates for:
/// - Work From Home Request
/// - Leave Request
/// - Permission Request
/// - Task Card Request

/// Work From Home Request Email Template
class WorkFromHomeRequestEmailTemplate {
  static String generateEmailContent({
    required String employeeName,
    required String startDate,
    required String endDate,
    required String totalDays,
    String? reason,
    String? employeeRole,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Work From Home Request</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <style>
        body {
            margin: 0;
            background: #eef1f5;
            padding: 30px 0;
            font-family: 'Poppins', sans-serif;
            color: #2b2d33;
        }
        .email-wrapper {
            max-width: 680px;
            width: 100%;
            margin: 0 auto;
            background: #ffffff;
            border-radius: 14px;
            overflow: hidden;
            box-shadow: 0 8px 28px rgba(0, 0, 0, 0.08);
        }
        .header {
            background: linear-gradient(135deg, #003d80, #0073d4);
            padding: 35px 40px;
            text-align: left;
        }
        .header h1 {
            margin: 0;
            font-size: 26px;
            font-weight: 600;
            color: #ffffff;
            letter-spacing: 0.5px;
        }
        .content {
            padding: 40px;
        }
        .greeting {
            font-size: 17px;
            font-weight: 500;
            margin-bottom: 15px;
            color: #222;
        }

        /* Mobile Responsive Queries */
        @media only screen and (max-width: 600px) {
            .email-wrapper {
                width: 100% !important;
                border-radius: 0 !important;
            }
            .header {
                padding: 25px 20px !important;
            }
            .header h1 {
                font-size: 22px !important;
            }
            .content {
                padding: 25px 20px !important;
            }
            .detail-row {
                flex-direction: column;
                align-items: flex-start;
            }
            .detail-value {
                text-align: left !important;
                margin-top: 5px;
            }
        }
        p {
            font-size: 15px;
            line-height: 1.7;
            margin: 0 0 16px 0;
            color: #4a4e57;
        }
        .section-title {
            font-size: 18px;
            font-weight: 600;
            color: #0066cc;
            margin-bottom: 18px;
            padding-bottom: 6px;
            border-bottom: 2px solid #e6e9ef;
        }
        .request-details {
            background: #f8f9fc;
            padding: 22px;
            border-radius: 12px;
            border: 1px solid #e5e8ef;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid #e1e4ea;
        }
        .detail-row:last-child {
            border-bottom: none;
        }
        .detail-label {
            font-size: 15px;
            font-weight: 600;
            color: #333;
            min-width: 150px;
        }
        .detail-value {
            font-size: 15px;
            font-weight: 500;
            color: #2b2d33;
            text-align: right;
        }
        .reason-box {
            margin: 28px 0;
            background: #ffffff;
            border: 1px solid #dfe3eb;
            padding: 20px;
            border-radius: 10px;
            font-size: 14px;
            color: #4f535b;
            line-height: 1.6;
        }
        .footer {
            margin-top: 40px;
            text-align: center;
            padding: 24px 35px;
            background: #f0f2f6;
            border-top: 1px solid #e4e7ed;
        }
        .footer p {
            margin: 5px 0;
            font-size: 13px;
            color: #7a7e87;
        }
        .watermark {
            margin-top: 12px;
            font-size: 12px;
            color: #9aa0a9;
        }
        .cta-container {
            text-align: center;
            margin-top: 35px;
        }
        .dashboard-btn {
            background: #0073d4;
            color: #ffffff;
            padding: 14px 36px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
            font-size: 15px;
            display: inline-block;
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="header">
            <h1>Work From Home Request</h1>
        </div>
        <div class="content">
            <div class="greeting">
                Hello <strong>HR Department</strong>,
            </div>
            <p>
                A work from home request has been submitted. Below are the complete details for your reference.
            </p>
            <h3 class="section-title">Request Details</h3>
            <div class="request-details">
                <div class="detail-row">
                    <span class="detail-label">Employee Name:</span>
                    <span class="detail-value">$employeeName</span>
                </div>
                ${employeeRole != null ? '''
                <div class="detail-row">
                    <span class="detail-label">Role:</span>
                    <span class="detail-value">$employeeRole</span>
                </div>
                ''' : ''}
                <div class="detail-row">
                    <span class="detail-label">Start Date:</span>
                    <span class="detail-value">$startDate</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">End Date:</span>
                    <span class="detail-value">$endDate</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Total Days:</span>
                    <span class="detail-value">$totalDays</span>
                </div>
            </div>
            ${reason != null && reason.isNotEmpty ? '''
            <div class="reason-box">
                <strong>Reason:</strong>
                <br><br>
                $reason
            </div>
            ''' : ''}
        </div>
        <div class="cta-container">
            <a href="https://sprintlyadmin.webnoxdigital.com/" 
               target="_blank"
               class="dashboard-btn">
                Open Dashboard
            </a>
        </div>
        <div class="footer">
            <p>This is an automated message. Please do not reply to this email.</p>
            <div class="watermark">
                © Webnox Technologies Pvt Ltd<br>
                A Product by Mobile App Team
            </div>
        </div>
    </div>
</body>
</html>
    ''';
  }

  static String generateEmailSubject({
    required String employeeName,
  }) {
    return 'Work From Home Request - $employeeName';
  }
}

/// Leave Request Email Template
class LeaveRequestEmailTemplate {
  static String generateEmailContent({
    required String employeeName,
    required String startDate,
    required String endDate,
    required String totalDays,
    required String reason,
    String? leaveType,
    bool isPaidLeave = false,
    bool isHalfDay = false,
    String? halfDayType,
  }) {
    final leaveTypeText = leaveType ?? 'General Leave';
    final paidLeaveText = isPaidLeave ? 'Yes' : 'No';
    final halfDayText = isHalfDay ? (halfDayType ?? 'Half Day') : 'No';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Leave Request</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <style>
        body {
            margin: 0;
            background: #eef1f5;
            padding: 30px 0;
            font-family: 'Poppins', sans-serif;
            color: #2b2d33;
        }
        .email-wrapper {
            max-width: 680px;
            width: 100%;
            margin: 0 auto;
            background: #ffffff;
            border-radius: 14px;
            overflow: hidden;
            box-shadow: 0 8px 28px rgba(0, 0, 0, 0.08);
        }
        .header {
            background: linear-gradient(135deg, #003d80, #0073d4);
            padding: 35px 40px;
            text-align: left;
        }
        .header h1 {
            margin: 0;
            font-size: 26px;
            font-weight: 600;
            color: #ffffff;
            letter-spacing: 0.5px;
        }
        .content {
            padding: 40px;
        }
        .greeting {
            font-size: 17px;
            font-weight: 500;
            margin-bottom: 15px;
            color: #222;
        }

        /* Mobile Responsive Queries */
        @media only screen and (max-width: 600px) {
            .email-wrapper {
                width: 100% !important;
                border-radius: 0 !important;
            }
            .header {
                padding: 25px 20px !important;
            }
            .header h1 {
                font-size: 22px !important;
            }
            .content {
                padding: 25px 20px !important;
            }
            .detail-row {
                flex-direction: column;
                align-items: flex-start;
            }
            .detail-value {
                text-align: left !important;
                margin-top: 5px;
            }
        }
        p {
            font-size: 15px;
            line-height: 1.7;
            margin: 0 0 16px 0;
            color: #4a4e57;
        }
        .section-title {
            font-size: 18px;
            font-weight: 600;
            color: #0066cc;
            margin-bottom: 18px;
            padding-bottom: 6px;
            border-bottom: 2px solid #e6e9ef;
        }
        .request-details {
            background: #f8f9fc;
            padding: 22px;
            border-radius: 12px;
            border: 1px solid #e5e8ef;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid #e1e4ea;
        }
        .detail-row:last-child {
            border-bottom: none;
        }
        .detail-label {
            font-size: 15px;
            font-weight: 600;
            color: #333;
            min-width: 150px;
        }
        .detail-value {
            font-size: 15px;
            font-weight: 500;
            color: #2b2d33;
            text-align: right;
        }
        .reason-box {
            margin: 28px 0;
            background: #ffffff;
            border: 1px solid #dfe3eb;
            padding: 20px;
            border-radius: 10px;
            font-size: 14px;
            color: #4f535b;
            line-height: 1.6;
        }
        .footer {
            margin-top: 40px;
            text-align: center;
            padding: 24px 35px;
            background: #f0f2f6;
            border-top: 1px solid #e4e7ed;
        }
        .footer p {
            margin: 5px 0;
            font-size: 13px;
            color: #7a7e87;
        }
        .watermark {
            margin-top: 12px;
            font-size: 12px;
            color: #9aa0a9;
        }
        .cta-container {
            text-align: center;
            margin-top: 35px;
        }
        .dashboard-btn {
            background: #0073d4;
            color: #ffffff;
            padding: 14px 36px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
            font-size: 15px;
            display: inline-block;
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="header">
            <h1>Leave Request</h1>
        </div>
        <div class="content">
            <div class="greeting">
                Hello <strong>HR Department</strong>,
            </div>
            <p>
                A leave request has been submitted. Below are the complete details for your reference.
            </p>
            <h3 class="section-title">Leave Details</h3>
            <div class="request-details">
                <div class="detail-row">
                    <span class="detail-label">Employee Name:</span>
                    <span class="detail-value">$employeeName</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Leave Type:</span>
                    <span class="detail-value">$leaveTypeText</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Start Date:</span>
                    <span class="detail-value">$startDate</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">End Date:</span>
                    <span class="detail-value">$endDate</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Total Days:</span>
                    <span class="detail-value">$totalDays</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Half Day:</span>
                    <span class="detail-value">$halfDayText</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Paid Leave:</span>
                    <span class="detail-value">$paidLeaveText</span>
                </div>
            </div>
            <div class="reason-box">
                <strong>Reason:</strong>
                <br><br>
                $reason
            </div>
        </div>
        <div class="cta-container">
            <a href="https://sprintlyadmin.webnoxdigital.com/" 
               target="_blank"
               class="dashboard-btn">
                Open Dashboard
            </a>
        </div>
        <div class="footer">
            <p>This is an automated message. Please do not reply to this email.</p>
            <div class="watermark">
                © Webnox Technologies Pvt Ltd<br>
                A Product by Mobile App Team
            </div>
        </div>
    </div>
</body>
</html>
    ''';
  }

  static String generateEmailSubject({
    required String employeeName,
    required String leaveType,
  }) {
    return 'Leave Request - $employeeName ($leaveType)';
  }
}

/// Permission Request Email Template
class PermissionRequestEmailTemplate {
  static String generateEmailContent({
    required String employeeName,
    required String permissionDate,
    required String fromTime,
    required String toTime,
    required String duration,
    String? remarks,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Permission Request</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <style>
        body {
            margin: 0;
            background: #eef1f5;
            padding: 30px 0;
            font-family: 'Poppins', sans-serif;
            color: #2b2d33;
        }
        .email-wrapper {
            max-width: 680px;
            width: 100%;
            margin: 0 auto;
            background: #ffffff;
            border-radius: 14px;
            overflow: hidden;
            box-shadow: 0 8px 28px rgba(0, 0, 0, 0.08);
        }
        .header {
            background: linear-gradient(135deg, #003d80, #0073d4);
            padding: 35px 40px;
            text-align: left;
        }
        .header h1 {
            margin: 0;
            font-size: 26px;
            font-weight: 600;
            color: #ffffff;
            letter-spacing: 0.5px;
        }
        .content {
            padding: 40px;
        }
        .greeting {
            font-size: 17px;
            font-weight: 500;
            margin-bottom: 15px;
            color: #222;
        }

        /* Mobile Responsive Queries */
        @media only screen and (max-width: 600px) {
            .email-wrapper {
                width: 100% !important;
                border-radius: 0 !important;
            }
            .header {
                padding: 25px 20px !important;
            }
            .header h1 {
                font-size: 22px !important;
            }
            .content {
                padding: 25px 20px !important;
            }
            .detail-row {
                flex-direction: column;
                align-items: flex-start;
            }
            .detail-value {
                text-align: left !important;
                margin-top: 5px;
            }
        }
        p {
            font-size: 15px;
            line-height: 1.7;
            margin: 0 0 16px 0;
            color: #4a4e57;
        }
        .section-title {
            font-size: 18px;
            font-weight: 600;
            color: #0066cc;
            margin-bottom: 18px;
            padding-bottom: 6px;
            border-bottom: 2px solid #e6e9ef;
        }
        .request-details {
            background: #f8f9fc;
            padding: 22px;
            border-radius: 12px;
            border: 1px solid #e5e8ef;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid #e1e4ea;
        }
        .detail-row:last-child {
            border-bottom: none;
        }
        .detail-label {
            font-size: 15px;
            font-weight: 600;
            color: #333;
            min-width: 150px;
        }
        .detail-value {
            font-size: 15px;
            font-weight: 500;
            color: #2b2d33;
            text-align: right;
        }
        .remarks-box {
            margin: 28px 0;
            background: #ffffff;
            border: 1px solid #dfe3eb;
            padding: 20px;
            border-radius: 10px;
            font-size: 14px;
            color: #4f535b;
            line-height: 1.6;
        }
        .footer {
            margin-top: 40px;
            text-align: center;
            padding: 24px 35px;
            background: #f0f2f6;
            border-top: 1px solid #e4e7ed;
        }
        .footer p {
            margin: 5px 0;
            font-size: 13px;
            color: #7a7e87;
        }
        .watermark {
            margin-top: 12px;
            font-size: 12px;
            color: #9aa0a9;
        }
        .cta-container {
            text-align: center;
            margin-top: 35px;
        }
        .dashboard-btn {
            background: #0073d4;
            color: #ffffff;
            padding: 14px 36px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
            font-size: 15px;
            display: inline-block;
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="header">
            <h1>Permission Request</h1>
        </div>
        <div class="content">
            <div class="greeting">
                Hello <strong>HR Department</strong>,
            </div>
            <p>
                A permission request has been submitted. Below are the complete details for your reference.
            </p>
            <h3 class="section-title">Permission Details</h3>
            <div class="request-details">
                <div class="detail-row">
                    <span class="detail-label">Employee Name:</span>
                    <span class="detail-value">$employeeName</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Date:</span>
                    <span class="detail-value">$permissionDate</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">From Time:</span>
                    <span class="detail-value">$fromTime</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">To Time:</span>
                    <span class="detail-value">$toTime</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Duration:</span>
                    <span class="detail-value">$duration</span>
                </div>
            </div>
            ${remarks != null && remarks.isNotEmpty ? '''
            <div class="remarks-box">
                <strong>Remarks:</strong>
                <br><br>
                $remarks
            </div>
            ''' : ''}
        </div>
        <div class="cta-container">
            <a href="https://sprintlyadmin.webnoxdigital.com/" 
               target="_blank"
               class="dashboard-btn">
                Open Dashboard
            </a>
        </div>
        <div class="footer">
            <p>This is an automated message. Please do not reply to this email.</p>
            <div class="watermark">
                © Webnox Technologies Pvt Ltd<br>
                A Product by Mobile App Team
            </div>
        </div>
    </div>
</body>
</html>
    ''';
  }

  static String generateEmailSubject({
    required String employeeName,
    required String permissionDate,
  }) {
    return 'Permission Request - $employeeName ($permissionDate)';
  }
}

/// Task Card Request Email Template
class TaskCardRequestEmailTemplate {
  static String generateEmailContent({
    required String employeeName,
    required String taskName,
    required String taskDescription,
    required String taskType,
    required String priorityLevel,
    required String projectName,
    required String assignedBy,
    required String fromDate,
    required String toDate,
    required String taskDuration,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Task Request Notification</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <style>
        body {
            margin: 0;
            background: #eef1f5;
            padding: 30px 0;
            font-family: 'Poppins', sans-serif;
            color: #2b2d33;
        }
        .email-wrapper {
            max-width: 680px;
            margin: 0 auto;
            background: #ffffff;
            border-radius: 14px;
            overflow: hidden;
            box-shadow: 0 8px 28px rgba(0, 0, 0, 0.08);
        }
        .header {
            background: linear-gradient(135deg, #4a148c, #7b1fa2);
            padding: 35px 40px;
        }
        .header h1 {
            margin: 0;
            font-size: 26px;
            font-weight: 600;
            color: #ffffff;
        }
        .content {
            padding: 40px;
        }
        .greeting {
            font-size: 17px;
            font-weight: 500;
            margin-bottom: 15px;
        }
        p {
            font-size: 15px;
            line-height: 1.7;
            margin-bottom: 16px;
            color: #4a4e57;
        }
        .section-title {
            font-size: 18px;
            font-weight: 600;
            color: #6a1b9a;
            margin-bottom: 18px;
            border-bottom: 2px solid #e6e9ef;
            padding-bottom: 6px;
        }
        .task-details {
            background: #f8f9fc;
            padding: 22px;
            border-radius: 12px;
            border: 1px solid #e5e8ef;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid #e1e4ea;
        }
        .detail-row:last-child {
            border-bottom: none;
        }
        .detail-label {
            font-weight: 600;
        }
        .detail-value {
            font-weight: 500;
        }
        .priority-high {
            background: #c62828;
            color: #fff;
            padding: 5px 14px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }
        .priority-medium {
            background: #f9a825;
            color: #2b2d33;
            padding: 5px 14px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }
        .priority-low {
            background: #2e7d32;
            color: #ffffff;
            padding: 5px 14px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }
        .description-box {
            margin: 28px 0;
            background: #ffffff;
            border: 1px solid #dfe3eb;
            padding: 20px;
            border-radius: 10px;
            font-size: 14px;
            line-height: 1.6;
        }
        .cta-container {
            text-align: center;
            margin-top: 35px;
        }
        .dashboard-btn {
            background: #6a1b9a;
            color: #ffffff;
            padding: 14px 36px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
            font-size: 15px;
            display: inline-block;
        }
        .footer {
            margin-top: 40px;
            text-align: center;
            padding: 24px;
            background: #f0f2f6;
        }
        .footer p {
            font-size: 13px;
            color: #7a7e87;
        }
    </style>
</head>

<body>
<div class="email-wrapper">
    <div class="header">
        <h1>New Task Request Notification</h1>
    </div>

    <div class="content">
        <div class="greeting">
            Hello Webnox Admins,
        </div>

        <p>
            <strong>$employeeName</strong> has requested a new task card.
            Please review the task details below and take the necessary action
            from the Admin Dashboard.
        </p>

        <h3 class="section-title">Requested Task Details</h3>

        <div class="task-details">
            <div class="detail-row">
                <span class="detail-label">Task Name:</span>
                <span class="detail-value">$taskName</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Task Type:</span>
                <span class="detail-value">$taskType</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Priority:</span>
                <span class="detail-value">
                    <span class="priority-${priorityLevel.toLowerCase()}">
                        $priorityLevel
                    </span>
                </span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Project:</span>
                <span class="detail-value">$projectName</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Requested Duration:</span>
                <span class="detail-value">$taskDuration</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Proposed Start:</span>
                <span class="detail-value">$fromDate</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Proposed End:</span>
                <span class="detail-value">$toDate</span>
            </div>
        </div>

        <div class="description-box">
            <strong>Task Description:</strong><br><br>
            $taskDescription
        </div>

        <p>
            To approve, modify, or manage this request, please visit the Admin Dashboard.
        </p>

        <div class="cta-container">
            <a href="https://sprintlyadmin.webnoxdigital.com/" 
               target="_blank"
               class="dashboard-btn">
                Go to Admin Dashboard
            </a>
        </div>
    </div>

    <div class="footer">
        <p>This is an automated message. Please do not reply.</p>
        <p>© Webnox Technologies Pvt Ltd</p>
    </div>
</div>
</body>
</html>
    ''';
  }

  static String generateEmailSubject({
    required String taskName,
    required String projectName,
  }) {
    return 'New Task Assigned: $taskName - $projectName';
  }
}
