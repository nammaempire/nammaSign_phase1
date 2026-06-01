import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/billboard_listing.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/local_tab.dart';
import '../widgets/premium_tab.dart';

/// Home tab — custom top bar, Local/Premium sub-tabs, and the matching
/// content for each.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundLight,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging || _tabs.index != _index) {
        setState(() => _index = _tabs.index);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const HomeAppBar(),
            _TabHeader(
              controller: _tabs,
              index: _index,
              localCount: sampleListings.length,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  LocalTab(),
                  PremiumTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered "Local" / "Premium" pill switcher.
///
/// Active pill: solid purple fill, white text + matching badge.
/// Inactive pill: white surface with thin border, dark text + light badge.
/// No bottom divider — the tabs sit on the screen background.
class _TabHeader extends StatelessWidget {
  const _TabHeader({
    required this.controller,
    required this.index,
    required this.localCount,
  });

  final TabController controller;
  final int index;
  final int localCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Tab(
            label: 'Local',
            badgeText: '$localCount',
            active: index == 0,
            onTap: () => controller.animateTo(0),
          ),
          const SizedBox(width: AppSpacing.md),
          _Tab(
            label: 'Premium',
            badgeText: 'SOON',
            active: index == 1,
            onTap: () => controller.animateTo(1),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.badgeText,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String badgeText;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: active
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: active
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryOnLight,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: AppTextStyles.brandFooter.copyWith(
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textSecondaryOnLight,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
