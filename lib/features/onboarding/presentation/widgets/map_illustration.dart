import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Illustration for onboarding slide 01 — discover locations.
/// Stylized city map with purple pin markers and a "200+ SPOTS" stat badge.
class MapIllustration extends StatelessWidget {
  const MapIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Map surface
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: CustomPaint(painter: _MapGridPainter()),
              ),
            ),
          ),

          // Pin markers — varied positions to feel like a real map.
          const Positioned(top: 30, left: 90, child: _Pin(big: true)),
          const Positioned(top: 70, right: 80, child: _Pin()),
          const Positioned(top: 130, left: 110, child: _Pin()),
          const Positioned(bottom: 60, right: 110, child: _Pin(big: true)),
          const Positioned(bottom: 30, left: 70, child: _Pin()),

          // Stat badge
          Positioned(
            bottom: -4,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.badgeDark,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '200+',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LOCATIONS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryLight,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({this.big = false});
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? 32.0 : 24.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.location_on,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }
}

/// Subtle grid lines + faint roads to imply "map".
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    // Vertical gridlines
    for (var x = 30.0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 8), Offset(x, size.height - 8), paint);
    }
    // Horizontal gridlines
    for (var y = 30.0; y < size.height; y += 40) {
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), paint);
    }

    // Two diagonal "roads" in stronger purple
    final road = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.18)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.6),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.5, size.height),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
