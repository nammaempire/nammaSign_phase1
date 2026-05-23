import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import 'upload_area.dart';
import 'uploaded_file_card.dart';

/// One file "slot" on a signup form.
///
/// Renders the dashed [UploadArea] when no file is selected. Once a
/// [PlatformFile] is picked (parent passes it down), renders an
/// [UploadedFileCard] showing the actual filename and size, with a small
/// remove icon to clear the slot.
///
/// The parent owns the file state — this widget is stateless. Tapping
/// either state calls [onPickFile]; the parent is responsible for
/// invoking the file picker and updating its own state.
class FileUploadSlot extends StatelessWidget {
  const FileUploadSlot({
    super.key,
    required this.file,
    required this.onPickFile,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.filledStatus = UploadStatus.uploaded,
    this.filledIcon = Icons.insert_drive_file_outlined,
    this.onRemove,
  });

  final PlatformFile? file;
  final Future<void> Function() onPickFile;
  final String emptyTitle;
  final String emptySubtitle;
  final UploadStatus filledStatus;
  final IconData filledIcon;
  final VoidCallback? onRemove;

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return UploadArea(
        title: emptyTitle,
        subtitle: emptySubtitle,
        onTap: onPickFile,
      );
    }

    return Row(
      children: [
        Expanded(
          child: UploadedFileCard(
            fileName: file!.name,
            sizeLabel: formatSize(file!.size),
            status: filledStatus,
            icon: filledIcon,
            onTap: onPickFile, // tap card to re-pick / replace
          ),
        ),
        if (onRemove != null) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Remove',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black54,
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
    );
  }
}
