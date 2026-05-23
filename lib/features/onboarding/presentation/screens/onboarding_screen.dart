import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/billboard_illustration.dart';
import '../widgets/booking_illustration.dart';
import '../widgets/map_illustration.dart';
import '../widgets/onboarding_slide.dart';

/// 3-slide onboarding shown once on first launch.
/// Matches the Figma — light lavender background, top step counter + skip,
/// illustration card, two-line serif title, description, page dots,
/// purple full-width Next/Get started button.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _index = 0;

  static const _slides = <OnboardingSlideData>[
    OnboardingSlideData(
      illustration: MapIllustration(),
      titleLine1: 'Find the best',
      titleLine2Italic: 'spots in town.',
      description:
          'Browse verified digital boards across your city — sorted by '
          'footfall, audience type, and your budget.',
    ),
    OnboardingSlideData(
      illustration: BillboardIllustration(),
      titleLine1: 'Reach where eyes',
      titleLine2Italic: 'actually go.',
      description:
          'High-traffic digital boards in your city — verified locations, '
          'real-time footfall, daily pricing.',
    ),
    OnboardingSlideData(
      illustration: BookingIllustration(),
      titleLine1: 'Book in a tap,',
      titleLine2Italic: 'go live today.',
      description:
          'Pick your dates, upload creatives, pay securely, and watch your '
          'campaign launch across the city.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Onboarding has a light background — make the status-bar icons dark.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundLight,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goToAccountType() {
    // onboardingComplete is set by AccountTypeScreen after the user picks
    // a type and taps Continue. Until then, backing out returns to here.
    context.push(AppRoutes.accountType);
  }

  void _onNext() {
    if (_index == _slides.length - 1) {
      _goToAccountType();
    } else {
      _pageCtrl.nextPage(
        duration: AppConstants.mediumAnim,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — step counter + skip
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  _StepCounter(
                    current: _index + 1,
                    total: _slides.length,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _goToAccountType,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'SKIP',
                      style: AppTextStyles.brandFooter.copyWith(
                        color: AppColors.textPrimaryOnLight,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => OnboardingSlide(data: _slides[i]),
              ),
            ),

            // Page dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final selected = i == _index;
                return AnimatedContainer(
                  duration: AppConstants.shortAnim,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: selected ? 28 : 8,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                );
              }),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Next / Get started
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
                  onPressed: _onNext,
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
                        _index == _slides.length - 1
                            ? 'Get started'
                            : 'Next',
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

/// "STEP 02 / 03" — current step in bold purple, total in muted gray.
class _StepCounter extends StatelessWidget {
  const _StepCounter({required this.current, required this.total});

  final int current;
  final int total;

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.brandFooter.copyWith(letterSpacing: 2);
    return Row(
      children: [
        Text(
          'STEP ',
          style: base.copyWith(color: AppColors.textTertiaryOnLight),
        ),
        Text(
          _two(current),
          style: base.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          ' / ${_two(total)}',
          style: base.copyWith(color: AppColors.textTertiaryOnLight),
        ),
      ],
    );
  }
}
