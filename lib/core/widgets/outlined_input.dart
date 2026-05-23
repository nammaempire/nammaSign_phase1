import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Light-themed outlined input field used on signup forms.
///
/// - White background
/// - Thin border by default, purple border when focused
/// - Optional leading icon
/// - Optional monospace style (for IDs / Aadhaar numbers)
/// - Explicitly opts out of the global `filled: true` so the dark fill from
///   the global InputDecorationTheme doesn't bleed onto this light field.
class OutlinedInput extends StatefulWidget {
  const OutlinedInput({
    super.key,
    this.controller,
    this.hint,
    this.leadingIcon,
    this.monospace = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.maxLength,
    this.maxLines = 1,
    this.suffix,
    this.locked = false,
  });

  final TextEditingController? controller;
  final String? hint;
  final IconData? leadingIcon;
  final bool monospace;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLength;
  final int maxLines;
  final Widget? suffix;
  /// When true, the field reads as a locked / read-only pill — lavender
  /// background, no border highlight on focus, taps do nothing.
  final bool locked;

  @override
  State<OutlinedInput> createState() => _OutlinedInputState();
}

class _OutlinedInputState extends State<OutlinedInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focus.hasFocus;
    final textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimaryOnLight,
      letterSpacing: widget.monospace ? 1 : 0.2,
      fontFamily: widget.monospace ? 'monospace' : null,
    );

    return Theme(
      // Local override: parent dark theme has dark selection that would
      // render unreadable on this white input.
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.primary,
          selectionColor: AppColors.primary.withValues(alpha: 0.25),
          selectionHandleColor: AppColors.primary,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: widget.locked ? AppColors.surfaceLight : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: widget.locked
                ? Colors.transparent
                : (isFocused
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.15)),
            width: (isFocused && !widget.locked) ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.lg),
            if (widget.leadingIcon != null) ...[
              Icon(
                widget.leadingIcon,
                size: 20,
                color: AppColors.textTertiaryOnLight,
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focus,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                validator: widget.validator,
                onChanged: widget.onChanged,
                readOnly: widget.readOnly || widget.locked,
                onTap: widget.locked ? null : widget.onTap,
                maxLength: widget.maxLength,
                maxLines: widget.maxLines,
                cursorColor: AppColors.primary,
                style: textStyle,
                decoration: InputDecoration(
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: widget.hint,
                  hintStyle: textStyle.copyWith(
                    color: AppColors.textTertiaryOnLight,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                  ),
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
              ),
            ),
            if (widget.suffix != null) ...[
              widget.suffix!,
              const SizedBox(width: AppSpacing.md),
            ] else
              const SizedBox(width: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
