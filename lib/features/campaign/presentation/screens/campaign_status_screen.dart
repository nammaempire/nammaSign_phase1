import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../history/domain/booking.dart';
import '../widgets/campaign_status_hero.dart';
import '../widgets/timeline_step.dart';

/// Renders the campaign status for a single booking. Switches between
/// Under Review / Live on Board / Needs Changes based on [booking.status].
class CampaignStatusScreen extends StatelessWidget {
  const CampaignStatusScreen({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
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
            _TopBar(),
            Expanded(
              child: switch (booking.status) {
                BookingStatus.pending => _UnderReviewBody(booking: booking),
                BookingStatus.live => _LiveOnBoardBody(booking: booking),
                BookingStatus.rejected =>
                  _NeedsChangesBody(booking: booking),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar — BACK + menu
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.home),
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
          const Spacer(),
          IconButton(
            onPressed: () => context.showSnack('Campaign menu (Phase 1b)'),
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: AppColors.textPrimaryOnLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// UNDER REVIEW
// ---------------------------------------------------------------------------

class _UnderReviewBody extends StatelessWidget {
  const _UnderReviewBody({required this.booking});
  final Booking booking;

  // Demo amber palette for the under-review state.
  static const _amberCircle = Color(0xFFD2A555);
  static const _amberPillBg = Color(0xFFFAEBD3);
  static const _amberPillFg = Color(0xFFB7791F);

  @override
  Widget build(BuildContext context) {
    final orderRef = 'NE-2026-A${(booking.amount * 7 % 9000 + 1000)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampaignStatusHero(
            circleColor: _amberCircle,
            icon: Icons.schedule_rounded,
            pillText: 'UNDER REVIEW',
            pillBg: _amberPillBg,
            pillFg: _amberPillFg,
            titleLeading: 'Hang tight, ',
            titleTrailingItalic: "we're reviewing.",
            subtitle: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondaryOnLight,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text: 'Our team typically approves ads within ',
                  ),
                  TextSpan(
                    text: '2 hours',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimaryOnLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(
                    text: ". We'll notify you instantly.",
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          _TimelineCard(
            header: 'CAMPAIGN  ·  $orderRef',
            steps: [
              TimelineStep(
                title: 'Payment received',
                subtitle: '14:23  ·  ₹${_format(booking.amount)} captured',
                dotKind: TimelineDotKind.filled,
                dotColor: AppColors.success,
              ),
              TimelineStep(
                title: 'Admin review',
                subtitle: 'In progress  ·  ~1h 38m left',
                dotKind: TimelineDotKind.filled,
                dotColor: AppColors.primary,
              ),
              TimelineStep(
                title: 'Goes live on board',
                subtitle: 'Scheduled  ·  28 Oct, 6:00 AM',
                dotKind: TimelineDotKind.empty,
                titleMuted: true,
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          _OutlinedCta(
            label: 'View campaign details',
            onTap: () => context.showSnack('Campaign details (Phase 1b)'),
          ),
        ],
      ),
    );
  }

  String _format(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ---------------------------------------------------------------------------
// LIVE ON BOARD
// ---------------------------------------------------------------------------

class _LiveOnBoardBody extends StatelessWidget {
  const _LiveOnBoardBody({required this.booking});
  final Booking booking;

  static const _greenCircle = Color(0xFFC4DFA0);
  static const _greenPillBg = Color(0xFFDAF5E0);
  static const _greenPillFg = Color(0xFF3B7F2A);

  @override
  Widget build(BuildContext context) {
    // Demo values — would come from analytics in real app.
    const dayOfTotal = 3;
    final total = booking.durationDays;
    const views = '36k';
    final left = total - dayOfTotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampaignStatusHero(
            circleColor: _greenCircle,
            icon: Icons.adjust_rounded,
            pillText: 'LIVE ON BOARD',
            pillBg: _greenPillBg,
            pillFg: _greenPillFg,
            titleLeading: "You're on ",
            titleTrailingItalic: '${booking.location}.',
            subtitle: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondaryOnLight,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Approved & running. '),
                  TextSpan(
                    text: 'Day $dayOfTotal of $total.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimaryOnLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(
                    text: ' Track impressions in real time below.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Stat row
          Row(
            children: [
              Expanded(child: _StatChip(value: views, label: 'VIEWS')),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatChip(
                  value: '$dayOfTotal / $total',
                  label: 'DAYS RUN',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _StatChip(value: '$left', label: 'LEFT')),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          _TimelineCard(
            header: 'CAMPAIGN TIMELINE',
            steps: [
              TimelineStep(
                title: 'Approved by admin',
                subtitle: '27 Oct  ·  15:48',
                dotKind: TimelineDotKind.filled,
                dotColor: AppColors.success,
              ),
              TimelineStep(
                title: 'Went live on board',
                subtitle: '28 Oct  ·  06:00',
                dotKind: TimelineDotKind.filled,
                dotColor: AppColors.success,
              ),
              TimelineStep(
                title: 'Running  ·  day $dayOfTotal of $total',
                subtitle: 'Performing',
                highlight: '+18% vs avg',
                dotKind: TimelineDotKind.filled,
                dotColor: AppColors.primary,
              ),
              TimelineStep(
                title: 'Campaign ends',
                subtitle: '11 Nov  ·  23:59',
                dotKind: TimelineDotKind.empty,
                titleMuted: true,
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Solid dark CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  context.showSnack('Live preview (Phase 1b)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.badgeDark,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Text(
                'View live preview',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.brandHuge.copyWith(
              fontSize: 20,
              color: AppColors.textPrimaryOnLight,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.brandFooter.copyWith(
              color: AppColors.textTertiaryOnLight,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NEEDS CHANGES
// ---------------------------------------------------------------------------

class _NeedsChangesBody extends StatelessWidget {
  const _NeedsChangesBody({required this.booking});
  final Booking booking;

  static const _pinkCircle = Color(0xFFE5559B);
  static const _pinkPillBg = Color(0xFFFBE3E8);
  static const _pinkPillFg = Color(0xFFB7245B);

  @override
  Widget build(BuildContext context) {
    final feedback = booking.adminNote ??
        'Creative exceeds the 30% text rule for outdoor LED. '
            'Please reduce body copy and increase logo size so the brand '
            "reads from 50m+. Re-upload and we'll fast-track approval.";

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampaignStatusHero(
            circleColor: _pinkCircle,
            icon: Icons.priority_high_rounded,
            pillText: 'NEEDS CHANGES',
            pillBg: _pinkPillBg,
            pillFg: _pinkPillFg,
            dashedRing: false,
            titleLeading: 'Almost there — ',
            titleTrailingItalic: 'one fix.',
            subtitle: const Text(
              'Edit your creative based on admin feedback and resubmit. '
              'No re-payment needed.',
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Feedback card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ADMIN FEEDBACK',
                      style: AppTextStyles.brandFooter.copyWith(
                        color: _pinkPillFg,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '  ·  ',
                      style: AppTextStyles.brandFooter.copyWith(
                        color: AppColors.textTertiaryOnLight,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'KAVYA R.',
                      style: AppTextStyles.brandFooter.copyWith(
                        color: AppColors.textSecondaryOnLight,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '"$feedback"',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimaryOnLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: _DashedLinePainter(),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text(
                      '27 Oct  ·  16:12',
                      style: AppTextStyles.brandFooter.copyWith(
                        color: AppColors.textTertiaryOnLight,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'RULE: NE-CREATIVE-04',
                      style: AppTextStyles.brandFooter.copyWith(
                        color: AppColors.textPrimaryOnLight,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Primary CTA — Edit & resubmit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  context.showSnack('Edit creative (Phase 1b)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Edit & resubmit',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          _OutlinedCta(
            label: 'Contact support',
            onTap: () => context.showSnack('Support (Phase 1b)'),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.header, required this.steps});

  final String header;
  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: AppTextStyles.brandFooter.copyWith(
              color: AppColors.textTertiaryOnLight,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...steps,
        ],
      ),
    );
  }
}

class _OutlinedCta extends StatelessWidget {
  const _OutlinedCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryOnLight,
          backgroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimaryOnLight,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
