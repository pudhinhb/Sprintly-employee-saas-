import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:webnox_taskops/helpers/common_colors.dart';
import 'package:webnox_taskops/services/cloudinary_service.dart';

class QCCompletionDialog extends StatefulWidget {
  final String taskName;
  final VoidCallback? onWorkDone;
  final VoidCallback? onRedo;
  final Function(String notes, List<String> attachments)? onComplete;

  const QCCompletionDialog({
    super.key,
    required this.taskName,
    this.onWorkDone,
    this.onRedo,
    this.onComplete,
  });

  @override
  State<QCCompletionDialog> createState() => _QCCompletionDialogState();
}

class _QCCompletionDialogState extends State<QCCompletionDialog> {
  final TextEditingController _notesController = TextEditingController();
  final List<String> _attachments = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleWorkDone() {
    // Close the QC dialog first
    Navigator.of(context).pop();

    // Show congratulations animation
    // Call the completion callbacks
    if (widget.onComplete != null) {
      widget.onComplete!(
          _notesController.text, List<String>.from(_attachments));
    }
    if (widget.onWorkDone != null) {
      widget.onWorkDone!();
    }
  }

  void _handleRedo() {
    if (widget.onComplete != null) {
      widget.onComplete!(
          _notesController.text, List<String>.from(_attachments));
    }
    if (widget.onRedo != null) {
      widget.onRedo!();
    }
    Navigator.of(context).pop();
  }

  Future<void> _pickAndUploadAttachment() async {
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
    });
    try {
      // Allow picking on web and mobile/desktop; request bytes for web
      final result = await FilePicker.platform.pickFiles(withData: true);
      final file = result?.files.first;
      final apiRes = await CloudinaryService.uploadFileToBucket(file: file);
      if (apiRes.status && mounted) {
        setState(() {
          _attachments.add(apiRes.response as String);
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiRes.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick/upload file: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        width: isDesktop ? 500 : MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Clean and minimal
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quality Control',
                        style: TextStyle(
                          fontSize: isDesktop ? 28 : 24,
                          fontWeight: FontWeight.w300,
                          color: CommonColors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.taskName,
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 16,
                          color: CommonColors.grey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CommonColors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: CommonColors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Attachments Section
            Text(
              'Attachments',
              style: TextStyle(
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.w400,
                color: CommonColors.black,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadAttachment,
                  icon: Icon(Icons.upload_file, size: 18),
                  label: Text(_isUploading ? 'Uploading...' : 'Upload File'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                if (_attachments.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _attachments
                            .map((url) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Chip(
                                    label: Text(
                                      url.split('/').last,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _attachments.remove(url);
                                      });
                                    },
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // QC Notes Section - Premium styling
            Text(
              'Notes',
              style: TextStyle(
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.w400,
                color: CommonColors.black,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CommonColors.grey.withOpacity(0.2),
                  width: 1,
                ),
                color: CommonColors.grey.withOpacity(0.02),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 4,
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 14,
                  color: CommonColors.black,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Add your quality control notes...',
                  hintStyle: TextStyle(
                    color: CommonColors.grey.withOpacity(0.6),
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons - Premium minimalist design
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _handleRedo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: CommonColors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: CommonColors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Send for Redo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          fontWeight: FontWeight.w500,
                          color: CommonColors.red,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _handleWorkDone,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: CommonColors.green,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: CommonColors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Approve Work',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
