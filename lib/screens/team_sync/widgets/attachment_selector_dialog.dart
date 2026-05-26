import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AttachmentType { image, file, contact }

class AttachmentSelectorDialog extends StatelessWidget {
  final bool isDark;

  const AttachmentSelectorDialog({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Send Attachment',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'What would you like to send?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.blueGrey.shade400,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOption(
                    context,
                    icon: Icons.image_rounded,
                    label: 'Image',
                    color: const Color(0xFF9333EA),
                    bgColor: const Color(0xFFF3E8FF),
                    type: AttachmentType.image,
                  ),
                  _buildOption(
                    context,
                    icon: Icons.insert_drive_file_rounded,
                    label: 'File',
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFDBEAFE),
                    type: AttachmentType.file,
                  ),
                  _buildOption(
                    context,
                    icon: Icons.person_rounded,
                    label: 'Contact',
                    color: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFDCFCE7),
                    type: AttachmentType.contact,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.blueGrey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required AttachmentType type,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, type),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.2) : bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
