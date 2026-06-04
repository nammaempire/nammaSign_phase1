import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/upload_area.dart' show DottedBorder;
import '../../../../app/theme/app_palette.dart';

/// Dashed upload zone with image + video icon affordances.
/// Used on both campaign forms as the "Add / Replace creative" CTA.
class CreativeUploadButton extends StatelessWidget {
  const CreativeUploadButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPickImage,
    required this.onPickVideo,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      color: AppColors.primary.withValues(alpha: 0.3),
      radius: AppSpacing.radiusLg,
      strokeWidth: 1.4,
      dashWidth: 5,
      dashGap: 5,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IconChip(icon: Icons.image_outlined, onTap: onPickImage),
                const SizedBox(width: AppSpacing.md),
                _IconChip(icon: Icons.videocam_outlined, onTap: onPickVideo),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.brandHuge.copyWith(
                fontSize: 15,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.colors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}
