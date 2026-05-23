import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/string_extensions.dart';

/// Profile header — purple gradient avatar with initials, green verified
/// check, name, and the "TYPE · ORG" line underneath.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.accountTypeLabel,
    required this.orgLabel,
    this.verified = true,
  });

  final String name;
  final String accountTypeLabel; // e.g. "CORPORATE" or "INDIVIDUAL"
  final String orgLabel; // e.g. "BRIGADE ENTERPRISES"
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.initials,
                  style: AppTextStyles.brandHuge.copyWith(
                    fontSize: 36,
                    color: AppColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (verified)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundLight,
                        width: 2.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        Text(
          name,
          style: AppTextStyles.brandHuge.copyWith(
            fontSize: 22,
            color: AppColors.textPrimaryOnLight,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              accountTypeLabel.toUpperCase(),
              style: AppTextStyles.brandFooter.copyWith(
                color: AppColors.textTertiaryOnLight,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '  ·  ',
              style: AppTextStyles.brandFooter.copyWith(
                color: AppColors.textTertiaryOnLight,
              ),
            ),
            Flexible(
              child: Text(
                orgLabel.toUpperCase(),
                style: AppTextStyles.brandFooter.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
