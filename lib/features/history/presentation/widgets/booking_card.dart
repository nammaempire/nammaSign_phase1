import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_border_box.dart';
import '../../domain/booking.dart';

/// Single booking row card on the history list.
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking, this.onTap});

  final Booking booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GradientBorderBox(
      borderRadius: AppSpacing.radiusLg,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left icon container
                _StatusIcon(status: booking.status),
                const SizedBox(width: AppSpacing.md),

                // Right column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + status pill
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              booking.campaignTitle,
                              style: AppTextStyles.brandHuge.copyWith(
                                fontSize: 16,
                                color: AppColors.textPrimaryOnLight,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _StatusPill(status: booking.status),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Location · board type
                      Text(
                        '${booking.location}  ·  ${booking.boardType}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryOnLight,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Duration · date
                      Row(
                        children: [
                          _DaysChip(days: booking.durationDays),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '·  ${booking.runDateLabel}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textTertiaryOnLight,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.sm),
                      const _DashedDivider(),
                      const SizedBox(height: AppSpacing.sm),

                      // Payment row OR admin note
                      if (booking.adminNote != null)
                        _AdminNoteBox(text: booking.adminNote!)
                      else
                        _PaymentRow(
                          method: booking.paymentMethod,
                          paid: booking.paid,
                          amount: booking.amount,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: status.iconGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      alignment: Alignment.center,
      child: Icon(status.icon, size: 28, color: Colors.white),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: status.tint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.brandFooter.copyWith(
          color: status.accent,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _DaysChip extends StatelessWidget {
  const _DaysChip({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$days',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          days == 1 ? 'day' : 'days',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondaryOnLight,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.method,
    required this.paid,
    required this.amount,
  });

  final String method;
  final bool paid;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          method,
          style: AppTextStyles.brandFooter.copyWith(
            color: AppColors.textSecondaryOnLight,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (paid) ...[
          Text(
            '  ·  ',
            style: AppTextStyles.brandFooter.copyWith(
              color: AppColors.textTertiaryOnLight,
            ),
          ),
          Icon(
            Icons.check_rounded,
            size: 13,
            color: AppColors.textSecondaryOnLight,
          ),
          const SizedBox(width: 2),
          Text(
            'PAID',
            style: AppTextStyles.brandFooter.copyWith(
              color: AppColors.textSecondaryOnLight,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const Spacer(),
        Text(
          '₹${_format(amount)}',
          style: AppTextStyles.brandHuge.copyWith(
            fontSize: 16,
            color: AppColors.primary,
            height: 1,
          ),
        ),
      ],
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

class _AdminNoteBox extends StatelessWidget {
  const _AdminNoteBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE3E8),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADMIN NOTE',
            style: AppTextStyles.brandFooter.copyWith(
              color: const Color(0xFFB7245B),
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimaryOnLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
