import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_palette.dart';

/// Drop-in replacement for a `Container` that paints a gradient border.
///
/// Flutter's `BoxDecoration.border` only supports solid colors, so we
/// achieve the gradient-border look by stacking two containers:
///   - outer: filled with the gradient, rounded
///   - inner: filled with [innerColor] (white by default), slightly smaller
/// The exposed strip between the two is the gradient "border".
///
/// Use this everywhere a content card needs the brand purple gradient ring.
/// For selectable / focusable elements (form inputs, picker tiles), keep
/// the existing solid-color borders so the selected state reads clearly.
class GradientBorderBox extends StatelessWidget {
  const GradientBorderBox({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.borderWidth = 1.2,
    this.gradient = AppColors.cardBorderGradient,
    this.innerColor,
    this.padding,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Gradient gradient;

  /// When null (the default), uses the current theme's card surface so the
  /// box flips correctly between light and dark mode. Pass a concrete color
  /// only when you need to override (e.g. a colored highlight card).
  final Color? innerColor;

  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: innerColor ?? context.colors.card,
          borderRadius: BorderRadius.circular(
            (borderRadius - borderWidth).clamp(0, borderRadius),
          ),
        ),
        clipBehavior: clipBehavior,
        padding: padding,
        child: child,
      ),
    );
  }
}
