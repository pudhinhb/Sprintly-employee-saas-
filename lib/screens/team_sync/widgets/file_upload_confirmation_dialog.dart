import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class FileUploadConfirmationDialog extends StatefulWidget {
  final List<PlatformFile> initialFiles;
  final bool isDark;

  const FileUploadConfirmationDialog({
    super.key,
    required this.initialFiles,
    required this.isDark,
  });

  @override
  State<FileUploadConfirmationDialog> createState() =>
      _FileUploadConfirmationDialogState();
}

class _FileUploadConfirmationDialogState
    extends State<FileUploadConfirmationDialog> {
  late List<PlatformFile> _files;
  final _captionController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.initialFiles);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickMoreFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _files = [..._files, ...result.files];
      });
    }
  }

  void _removeFile(PlatformFile file) {
    setState(() {
      _files = _files.where((f) => f != file).toList();
    });
    if (_files.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  void _onSend() {
    if (_files.isNotEmpty) {
      Navigator.of(context).pop({
        'files': _files,
        'caption': _captionController.text.trim(),
      });
    }
  }

  Widget _buildFilePreview(PlatformFile file) {
    final ext = file.extension?.toLowerCase() ?? '';
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark ? Colors.white10 : Colors.grey.shade300,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: isImage
              ? (file.bytes != null
                  ? Image.memory(
                      file.bytes!,
                      fit: BoxFit.cover,
                    )
                  : (file.path != null
                      ? Image.file(
                          File(file.path!),
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported)))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getFileIcon(ext),
                      size: 32,
                      color: _getFileColor(ext),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        ext.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDark ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: InkWell(
            onTap: () => _removeFile(file),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: widget.isDark ? AppTheme.darkSurfaceColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Send Files',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Files Grid/List
              Flexible(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ..._files.map((f) => _buildFilePreview(f)),
                      // Add Button
                      InkWell(
                        onTap: _pickMoreFiles,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: widget.isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 32,
                                color: widget.isDark
                                    ? Colors.white54
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: widget.isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Selected File Name (if only one)
              if (_files.length == 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _files.first.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: widget.isDark
                          ? Colors.white70
                          : AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Caption Input
              TextField(
                controller: _captionController,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: widget.isDark ? Colors.white : AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: GoogleFonts.poppins(
                    color:
                        widget.isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: widget.isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.message_rounded,
                    size: 20,
                    color:
                        widget.isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                ),
                minLines: 1,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: widget.isDark
                            ? Colors.white54
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _onSend,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      'Send ${_files.length > 1 ? "(${_files.length})" : ""}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.play_circle_rounded;
      case 'mp3':
      case 'wav':
        return Icons.audio_file_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Colors.purple;
      case 'mp3':
      case 'wav':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
