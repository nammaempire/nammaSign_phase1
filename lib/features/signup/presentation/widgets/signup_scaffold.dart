import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Common scaffold for signup forms — light background, BACK button, serif
/// title (regular + italic purple), subtitle, scrollable body, and a
/// pinned full-width Continue CTA.
class SignupScaffold extends StatelessWidget {
  const SignupScaffold({
    super.key,
    required this.titlePart1,
    required this.titlePart2Italic,
    required this.subtitle,
    required this.body,
    required this.onContinue,
    this.continueLabel = 'Continue',
  });

  final String titlePart1;
  final String titlePart2Italic;
  final String subtitle;
  final Widget body;
  final VoidCallback onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    // Force light status-bar icons since the screen is on a light bg.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundLight,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // BACK button — no step counter, no progress bars per request.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.canPop()
                        ? context.pop()
                        // Fallback: deep-linked into signup with no history.
                        : context.go(AppRoutes.login),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                            color: AppColors.textPrimaryOnLight,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'BACK',
                            style: AppTextStyles.brandFooter.copyWith(
                              color: AppColors.textPrimaryOnLight,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      titlePart1,
                      style: AppTextStyles.brandHuge.copyWith(
                        fontSize: 30,
                        color: AppColors.textPrimaryOnLight,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      titlePart2Italic,
                      style: AppTextStyles.brandHugeItalic.copyWith(
                        fontSize: 30,
                        color: AppColors.primary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondaryOnLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    body,
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // Continue CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                0,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        continueLabel,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 22,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
