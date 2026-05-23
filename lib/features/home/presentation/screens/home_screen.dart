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

/// Custom tab header — "Local 142" + "Premium SOON" with purple underline
/// under the active one.
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Local',
            badgeText: '$localCount',
            badgeBg: AppColors.primary,
            active: index == 0,
            onTap: () => controller.animateTo(0),
          ),
          const SizedBox(width: AppSpacing.xxl),
          _Tab(
            label: 'Premium',
            badgeText: 'SOON',
            badgeBg: AppColors.primary,
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
    required this.badgeBg,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String badgeText;
  final Color badgeBg;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 18,
                    color: active
                        ? AppColors.textPrimaryOnLight
                        : AppColors.textTertiaryOnLight,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? badgeBg
                        : badgeBg.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: AppTextStyles.brandFooter.copyWith(
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textTertiaryOnLight,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Underline
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: active ? 40 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
