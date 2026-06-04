import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_palette.dart';

/// 6-box OTP input matching the design:
///   - filled box: lavender bg + 1.5px purple border + bold purple digit
///   - focused (cursor) box: white bg + 1.5px purple border + cursor
///   - empty box: white bg + light border
///
/// Uses one hidden TextField under the hood for keyboard input and renders
/// custom box widgets for display. Tap anywhere on the row to focus.
class OtpBoxField extends StatefulWidget {
  const OtpBoxField({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.autofocus = true,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  @override
  State<OtpBoxField> createState() => OtpBoxFieldState();
}

class OtpBoxFieldState extends State<OtpBoxField> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Programmatically fill the field (used by "Paste from SMS").
  void setValue(String value) {
    final clean = value.replaceAll(RegExp(r'\D'), '');
    final trimmed = clean.length > widget.length
        ? clean.substring(0, widget.length)
        : clean;
    _ctrl.text = trimmed;
    widget.onChanged?.call(trimmed);
    if (trimmed.length == widget.length) {
      widget.onCompleted?.call(trimmed);
      _focus.unfocus();
    }
    setState(() {});
  }

  void _onTextChanged(String v) {
    widget.onChanged?.call(v);
    if (v.length == widget.length) {
      widget.onCompleted?.call(v);
      _focus.unfocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final value = _ctrl.text;

    return Stack(
      children: [
        // Invisible input — captures keyboard, no visible UI.
        //
        // `Offstage` keeps the TextField in the widget tree (so the focus
        // node can request focus and the soft keyboard appears) but skips
        // painting and hit-testing entirely — so no stray underline, hairline
        // or cursor can leak above the OTP boxes.
        Offstage(
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(widget.length),
            ],
            showCursor: false,
            style: const TextStyle(color: Colors.transparent, height: 0),
            decoration: const InputDecoration(
              filled: false,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              counterText: '',
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: _onTextChanged,
          ),
        ),

        // Visible boxes — tap anywhere to focus the hidden input.
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (i) {
              final filled = i < value.length;
              final isFocusedBox = i == value.length && _focus.hasFocus;
              return _OtpBox(
                digit: filled ? value[i] : null,
                state: filled
                    ? _BoxState.filled
                    : (isFocusedBox ? _BoxState.focused : _BoxState.empty),
              );
            }),
          ),
        ),
      ],
    );
  }
}

enum _BoxState { empty, focused, filled }

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.digit, required this.state});

  final String? digit;
  final _BoxState state;

  @override
  Widget build(BuildContext context) {
    final isFilled = state == _BoxState.filled;
    final isFocused = state == _BoxState.focused;

    return Container(
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFilled ? context.colors.surface : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: (isFilled || isFocused)
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.12),
          width: (isFilled || isFocused) ? 1.5 : 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: isFilled
          ? Text(
              digit!,
              style: AppTextStyles.brandHuge.copyWith(
                fontSize: 24,
                color: AppColors.primary,
                height: 1,
              ),
            )
          : isFocused
              ? const _BlinkingCursor()
              : null,
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 22,
        color: AppColors.primary,
      ),
    );
  }
}
