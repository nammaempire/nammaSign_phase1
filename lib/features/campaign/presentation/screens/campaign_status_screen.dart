import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/gradient_border_box.dart';
import '../../../history/domain/booking.dart';
import '../../../history/presentation/providers/bookings_provider.dart';
import '../widgets/campaign_status_hero.dart';
import '../widgets/timeline_step.dart';

/// Renders the campaign status for a single booking. Streams the booking
/// live from Firestore so status changes (admin approval, rejection)
/// reflect instantly without the user reloading.
class CampaignStatusScreen extends ConsumerWidget {
  const CampaignStatusScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundLight,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: bookingAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    "Couldn't load campaign\n$e",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiaryOnLight,
                    ),
                  ),
                ),
                data: (booking) {
                  if (booking == null) {
                    return Center(
                      child: Text(
                        'Booking not found.',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textTertiaryOnLight,
                        ),
                      ),
                    );
                  }
                  return switch (booking.status) {
                    BookingStatus.live =>
                      _LiveOnBoardBody(booking: booking),
                    BookingStatus.rejected =>
                      _NeedsChangesBody(booking: booking),
                    _ => _UnderReviewBody(booking: booking),
                  };
                },
              ),
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
  // Circle now reuses the pill background tone so the clock reads as a
  // dark-amber outline on a soft cream disc (matches the design ref).
  static const _amberCircle = Color(0xFFFAEBD3);
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
            iconColor: _amberPillFg,
            titleFontSize: 32,
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
                title: 'Booking submitted',
                subtitle: '₹${_format(booking.amount)}  ·  payable on approval',
                dotKind: TimelineDotKind.filled,
                dotColor: AppColors.success,
              ),
              TimelineStep(
                title: 'Admin review',
                subtitle: 'In progress  ·  within ~2 hours',
                dotKind: TimelineDotKind.filled,
                dotColor: AppColors.primary,
              ),
              TimelineStep(
                title: 'Goes live on board',
                subtitle: 'Once approved',
                dotKind: TimelineDotKind.empty,
                titleMuted: true,
                isLast: true,
              ),
            ],
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

  // Lighter lime circle reads as a soft disc behind the dark-green
  // bullseye icon — matches the Under Review treatment.
  static const _greenCircle = Color(0xFFDBE6BB);
  static const _greenPillBg = Color(0xFFDAF5E0);
  static const _greenPillFg = Color(0xFF3B7F2A);

  @override
  Widget build(BuildContext context) {
    final boardLabel = _shortBoardLabel(booking.boardType);
    final dates = _formatDateRange(
      booking.scheduledStartAt,
      booking.scheduledEndAt,
    );

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
            iconColor: _greenPillFg,
            titleFontSize: 32,
            pillText: 'LIVE ON BOARD',
            pillBg: _greenPillBg,
            pillFg: _greenPillFg,
            titleLeading: "You're on ",
            titleTrailingItalic: '${booking.location}.',
            subtitle: const Text(
              'Your campaign is approved and running on the selected board.',
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          _InfoCard(
            header: 'CAMPAIGN INFORMATION',
            rows: [
              _InfoRow(
                label: 'STATUS',
                valueBuilder: (context) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _greenPillFg,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: AppTextStyles.brandFooter.copyWith(
                        color: _greenPillFg,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _InfoRow(
                label: 'BOARD NAME',
                value: '${booking.location} · $boardLabel',
              ),
              _InfoRow(
                label: 'DURATION',
                value: '${booking.durationDays} days',
              ),
              _InfoRow(
                label: 'ACTIVE DATES',
                value: dates,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "4 LED Boards" → "LED", "Digital Screen" → "Digital Screen".
  static String _shortBoardLabel(String raw) {
    if (raw.toUpperCase().contains('LED')) return 'LED';
    return raw;
  }

  /// Renders the active window as "28 Oct — 11 Nov", or "—" when missing.
  static String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    String fmt(DateTime d) => '${d.day} ${months[d.month - 1]}';
    return '${fmt(start)} — ${fmt(end)}';
  }
}

// ---------------------------------------------------------------------------
// Campaign Information card — header + labelled rows separated by hairlines.
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.header, required this.rows});

  final String header;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
        );
      }
      children.add(rows[i]);
    }

    return GradientBorderBox(
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: AppTextStyles.brandFooter.copyWith(
              color: AppColors.primary,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    this.value,
    this.valueBuilder,
  }) : assert(value != null || valueBuilder != null,
            'Provide either value or valueBuilder');

  final String label;
  final String? value;
  final WidgetBuilder? valueBuilder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.brandFooter.copyWith(
              color: AppColors.textTertiaryOnLight,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          valueBuilder != null
              ? valueBuilder!(context)
              : Text(
                  value!,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimaryOnLight,
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

  // Pink palette — circle now uses the pill bg so the error icon reads as
  // a dark pink outline on a soft blush disc (matches Under Review/Live).
  static const _pinkCircle = Color(0xFFFBE3E8);
  static const _pinkPillBg = Color(0xFFFBE3E8);
  static const _pinkPillFg = Color(0xFFB7245B);

  @override
  Widget build(BuildContext context) {
    final feedback = booking.adminNote ??
        'Creative exceeds the 30% text rule for outdoor LED. '
            'The body copy is too dense to read from 50m+ at vehicle speeds. '
            "We're unable to approve this submission.";
    final reviewer = booking.adminReviewerName ?? 'NammaSign Team';
    final ruleCode = booking.adminRuleCode;

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
            icon: Icons.error_outline_rounded,
            iconColor: _pinkPillFg,
            titleFontSize: 32,
            pillText: 'NOT APPROVED',
            pillBg: _pinkPillBg,
            pillFg: _pinkPillFg,
            dashedRing: false,
            titleLeading: 'Campaign ',
            titleTrailingItalic: 'not approved.',
            subtitle: const Text(
              'Your campaign did not pass our admin review. '
              'Please see the feedback below.',
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Feedback card with left pink accent stripe.
          _LeftAccentCard(
            accentColor: _pinkPillFg,
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
                      reviewer.toUpperCase(),
                      style: AppTextStyles.brandFooter.copyWith(
                        color: _pinkPillFg,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
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
                    if (ruleCode != null && ruleCode.isNotEmpty)
                      Text(
                        'RULE: $ruleCode',
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

          const SizedBox(height: AppSpacing.lg),

          // Refund card — lavender background, white icon box, message.
          _RefundCard(amount: booking.amount),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card with a coloured accent strip down the left edge (Not Approved state).
// ---------------------------------------------------------------------------

class _LeftAccentCard extends StatelessWidget {
  const _LeftAccentCard({
    required this.accentColor,
    required this.child,
  });

  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Refund initiated card — lavender bg + replay icon box + message.
// ---------------------------------------------------------------------------

class _RefundCard extends StatelessWidget {
  const _RefundCard({required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.replay_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refund initiated',
                  style: AppTextStyles.brandHuge.copyWith(
                    fontSize: 18,
                    color: AppColors.textPrimaryOnLight,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondaryOnLight,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Your amount of '),
                      TextSpan(
                        text: '₹${_formatAmount(amount)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimaryOnLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' will be refunded to your original payment method within ',
                      ),
                      TextSpan(
                        text: '5–7 business days.',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimaryOnLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatAmount(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
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
    return GradientBorderBox(
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.all(AppSpacing.lg),
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

