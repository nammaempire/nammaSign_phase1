import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

enum UploadStatus { uploaded, verified, failed }

/// Card representing an already-uploaded file in a signup form.
/// Shows file icon, filename, size + status, and a trailing check/error.
class UploadedFileCard extends StatelessWidget {
  const UploadedFileCard({
    super.key,
    required this.fileName,
    required this.sizeLabel,
    this.status = UploadStatus.uploaded,
    this.icon = Icons.insert_drive_file_outlined,
    this.onTap,
  });

  final String fileName;
  final String sizeLabel;
  final UploadStatus status;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimaryOnLight,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          sizeLabel,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiaryOnLight,
                          ),
                        ),
                        Text(
                          '  ·  ',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiaryOnLight,
                          ),
                        ),
                        Text(
                          _statusLabel(status),
                          style: AppTextStyles.brandFooter.copyWith(
                            color: AppColors.textTertiaryOnLight,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _statusIcon(status),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(UploadStatus s) => switch (s) {
        UploadStatus.uploaded => 'UPLOADED',
        UploadStatus.verified => 'VERIFIED',
        UploadStatus.failed => 'FAILED',
      };

  Widget _statusIcon(UploadStatus s) {
    switch (s) {
      case UploadStatus.uploaded:
      case UploadStatus.verified:
        return const Icon(
          Icons.check_rounded,
          color: AppColors.success,
          size: 22,
        );
      case UploadStatus.failed:
        return const Icon(
          Icons.error_outline_rounded,
          color: AppColors.error,
          size: 22,
        );
    }
  }
}
