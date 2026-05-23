import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../providers/splash_provider.dart';

/// Branded splash screen for NammaSign.
///
/// Shows the logo lockup centered on the purple radial gradient for
/// [AppConstants.splashDuration] (3s), then flips [splashCompleteProvider]
/// true so the router redirects to the next appropriate destination
/// (onboarding / login / home).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.splashEdge,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.splashDuration,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          ref.read(splashCompleteProvider.notifier).state = true;
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.1,
            colors: [
              AppColors.splashCenter,
              AppColors.splashMid,
              AppColors.splashEdge,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 4),

              // Logo lockup — rendered inside a white tile so the dark
              // monogram stays readable on the purple gradient. The lockup
              // includes "NAMMASIGN" + "AD-TECH MARKETPLACE" baked in.
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.splashEdge.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const BrandLogo(
                  variant: LogoVariant.lockup,
                  height: 170,
                ),
              ),

              const SizedBox(height: AppSpacing.huge),

              // Animated progress bar — fills over 3 seconds.
              _SplashProgressBar(controller: _controller),

              const Spacer(flex: 5),

              // Version + Made in India
              Text(
                '${AppConstants.appVersionLabel}  ·  ${AppConstants.appOriginLabel}',
                style: AppTextStyles.brandFooter.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.75),
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashProgressBar extends StatelessWidget {
  const _SplashProgressBar({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 4,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: controller.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
