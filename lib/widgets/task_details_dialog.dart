import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webnox_taskops/model/task_model.dart';
import 'package:intl/intl.dart';

/// Shows a dialog with full task details
void showTaskDetailsDialog(BuildContext context, Task task) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.task_alt, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Task Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Name
                      _buildDetailRow(
                        context,
                        'Task Name',
                        task.taskName ?? 'Untitled Task',
                        Icons.title,
                      ),
                      const Divider(height: 24),

                      // Description
                      _buildDetailRow(
                        context,
                        'Description',
                        task.taskDescription ?? 'No description',
                        Icons.description,
                      ),
                      const Divider(height: 24),

                      // Status
                      _buildDetailRow(
                        context,
                        'Status',
                        task.workflowStatus ?? 'Unknown',
                        Icons.flag,
                      ),
                      const Divider(height: 24),

                      // Priority
                      _buildDetailRow(
                        context,
                        'Priority',
                        task.priorityLevel?.toString() ?? 'Not set',
                        Icons.priority_high,
                      ),
                      const Divider(height: 24),

                      // Project
                      if (task.projectDetails != null) ...[
                        _buildDetailRow(
                          context,
                          'Project',
                          task.projectDetails!['project_name'] ??
                              'Unknown Project',
                          Icons.folder,
                        ),
                        const Divider(height: 24),
                      ],

                      // Duration
                      if (task.taskDuration != null) ...[
                        _buildDetailRow(
                          context,
                          'Estimated Duration',
                          '${task.taskDuration} hours',
                          Icons.schedule,
                        ),
                        const Divider(height: 24),
                      ],

                      // Assigned Date
                      if (task.assignedAt != null) ...[
                        _buildDetailRow(
                          context,
                          'Assigned Date',
                          _formatDate(task.assignedAt!),
                          Icons.calendar_today,
                        ),
                        const Divider(height: 24),
                      ],

                      // Dev Started
                      if (task.devStartedAt != null) ...[
                        _buildDetailRow(
                          context,
                          'Started Date',
                          _formatDate(task.devStartedAt!),
                          Icons.play_arrow,
                        ),
                        const Divider(height: 24),
                      ],

                      // Dev Completed
                      if (task.devCompletedAt != null) ...[
                        _buildDetailRow(
                          context,
                          'Completed Date',
                          _formatDate(task.devCompletedAt!),
                          Icons.check_circle,
                        ),
                        const Divider(height: 24),
                      ],

                      // Total Dev Hours
                      if (task.totalDevHours != null) ...[
                        _buildDetailRow(
                          context,
                          'Total Hours Worked',
                          '${task.totalDevHours} hours',
                          Icons.timer,
                        ),
                        const Divider(height: 24),
                      ],

                      // Dev Notes
                      if (task.devNotes != null &&
                          task.devNotes!.isNotEmpty) ...[
                        _buildDetailRow(
                          context,
                          'Developer Notes',
                          task.devNotes!,
                          Icons.note,
                        ),
                        const Divider(height: 24),
                      ],

                      // Task Type
                      if (task.taskType != null) ...[
                        _buildDetailRow(
                          context,
                          'Task Type',
                          task.taskType!,
                          Icons.category,
                        ),
                        const Divider(height: 24),
                      ],

                      // Attachments
                      if (task.taskAttachments != null &&
                          task.taskAttachments!.isNotEmpty) ...[
                        _buildAttachmentSection(
                          context,
                          'Attachments',
                          task.taskAttachments!,
                          Icons.attach_file,
                        ),
                        const Divider(height: 24),
                      ],

                      // Dev Completed Attachments
                      if (task.devCompletedAttachments != null &&
                          task.devCompletedAttachments!.isNotEmpty) ...[
                        _buildAttachmentSection(
                          context,
                          'Completion Attachments',
                          task.devCompletedAttachments!,
                          Icons.cloud_upload,
                        ),
                        const Divider(height: 24),
                      ],

                      // QC Attachments
                      if (task.qcCompletedAttachments != null &&
                          task.qcCompletedAttachments!.isNotEmpty) ...[
                        _buildAttachmentSection(
                          context,
                          'QC Attachments',
                          task.qcCompletedAttachments!,
                          Icons.verified,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Footer
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Helper to build detail rows
Widget _buildDetailRow(
  BuildContext context,
  String label,
  String value,
  IconData icon,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        icon,
        size: 20,
        color: Theme.of(context).primaryColor,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// Helper to format date
String _formatDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

// Helper to build attachment sections
Widget _buildAttachmentSection(
  BuildContext context,
  String label,
  List<dynamic> attachments,
  IconData icon,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${attachments.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ...attachments.map((attachment) {
        String fileName = 'Unknown file';
        String? fileUrl;

        if (attachment is Map) {
          fileName = attachment['file_name'] ??
              attachment['fileName'] ??
              attachment['name'] ??
              'Unknown file';
          fileUrl = attachment['file_url'] ??
              attachment['fileUrl'] ??
              attachment['url'];
        } else if (attachment is String) {
          fileName = attachment;
          fileUrl = attachment;
        }

        return Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.insert_drive_file,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      fileName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (fileUrl != null && fileUrl.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      SelectableText(
                        fileUrl,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                tooltip: 'Copy link',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  if (fileUrl != null && fileUrl.isNotEmpty) {
                    await Clipboard.setData(ClipboardData(text: fileUrl));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Link copied: ${fileUrl.length > 50 ? "${fileUrl.substring(0, 50)}..." : fileUrl}'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      }).toList(),
    ],
  );
}
