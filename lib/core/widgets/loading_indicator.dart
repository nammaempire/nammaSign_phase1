import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Small inline spinner.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(color ?? AppColors.primary),
        ),
      ),
    );
  }
}

/// Skeleton placeholder using shimmer effect. Use while data is loading.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.radius = AppSpacing.radiusSm,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
