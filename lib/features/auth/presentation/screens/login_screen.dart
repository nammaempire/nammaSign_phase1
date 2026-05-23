import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/india_flag.dart';
import '../providers/auth_provider.dart';

/// "Welcome to NammaSign" — phone number entry + social sign-in.
/// Matches the Figma exactly: location chip, dark logo card, serif title
/// with italic purple brand, labeled phone input, send-code CTA, divider,
/// Google + Apple buttons, create-account link.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  static const _dialCode = '+91';
  static const _detectedCity = 'BENGALURU';

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
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = '$_dialCode${_phoneCtrl.text.replaceAll(" ", "")}';
    await ref.read(otpFlowProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OtpFlowState>(otpFlowProvider, (prev, next) {
      switch (next) {
        case OtpCodeSent():
          context.push(AppRoutes.otp);
        case OtpError(:final message):
          context.showErrorSnack(message);
        default:
          break;
      }
    });

    final flow = ref.watch(otpFlowProvider);
    final isLoading = flow is OtpSending;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LocationChip(city: _detectedCity),
                const SizedBox(height: AppSpacing.xxl),

                // Logo card
                _LogoCard(),
                const SizedBox(height: AppSpacing.xxl),

                // Title
                Text(
                  'Welcome to',
                  style: AppTextStyles.brandHuge.copyWith(
                    fontSize: 32,
                    color: AppColors.textPrimaryOnLight,
                    height: 1.1,
                  ),
                ),
                Text(
                  '${AppConstants.appName}.',
                  style: AppTextStyles.brandHugeItalic.copyWith(
                    fontSize: 32,
                    color: AppColors.primary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sign in to book signage across India.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondaryOnLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // "01 PHONE NUMBER" label
                const _SectionLabel(number: '01', label: 'PHONE NUMBER'),
                const SizedBox(height: AppSpacing.sm),

                // Phone input
                _PhoneInputField(
                  controller: _phoneCtrl,
                  dialCode: _dialCode,
                  onSubmitted: (_) => _sendCode(),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Helper text
                Row(
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      size: 14,
                      color: AppColors.textTertiaryOnLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "We'll text a 6-digit code to verify it's you",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiaryOnLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Primary CTA
                _PrimaryCta(
                  label: 'Send verification code',
                  loading: isLoading,
                  onPressed: isLoading ? null : _sendCode,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // "OR CONTINUE WITH" divider
                const _OrDivider(),
                const SizedBox(height: AppSpacing.xxl),

                // Social buttons
                _SocialButton(
                  label: 'Continue with Google',
                  leading: _GoogleGlyph(),
                  background: Colors.white,
                  foreground: AppColors.textPrimaryOnLight,
                  onTap: () =>
                      context.showSnack('Google sign-in coming in Phase 1b'),
                ),
                const SizedBox(height: AppSpacing.md),
                _SocialButton(
                  label: 'Continue with Apple',
                  leading: const Icon(
                    Icons.apple,
                    size: 22,
                    color: Colors.white,
                  ),
                  background: AppColors.badgeDark,
                  foreground: AppColors.textPrimary,
                  onTap: () =>
                      context.showSnack('Apple sign-in coming in Phase 1b'),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Create account link
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'New to ${AppConstants.appName}? ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryOnLight,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(
                          '${AppRoutes.accountType}'
                          '?${AppRoutes.accountTypeModeParam}='
                          '${AppRoutes.accountTypeModeSignup}',
                        ),
                        child: Text(
                          'Create an account',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

// ---- Sub-widgets ----

/// "● BENGALURU · DETECTED"
class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.city});
  final String city;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.crowdDot,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          city,
          style: AppTextStyles.brandFooter.copyWith(
            color: AppColors.textPrimaryOnLight,
            letterSpacing: 2,
          ),
        ),
        Text(
          '  ·  DETECTED',
          style: AppTextStyles.brandFooter.copyWith(
            color: AppColors.textPrimaryOnLight,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

/// Small dark logo card — the NammaSign monogram tinted white, with a
/// tiny purple notification dot in the corner.
class _LogoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.badgeDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          child: const BrandLogo(
            variant: LogoVariant.mark,
            height: 36,
            color: Colors.white,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

/// "[01] PHONE NUMBER" — dark numbered badge + uppercase label.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.number, required this.label});
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.badgeDark,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            number,
            style: AppTextStyles.brandFooter.copyWith(
              color: AppColors.textPrimary,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.brandFooter.copyWith(
            color: AppColors.textTertiaryOnLight,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

/// Phone input: flag + dial code | text field, with purple border.
class _PhoneInputField extends StatelessWidget {
  const _PhoneInputField({
    required this.controller,
    required this.dialCode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String dialCode;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.lg),
          const IndiaFlag(),
          const SizedBox(width: AppSpacing.sm),
          Text(
            dialCode,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimaryOnLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 1,
            height: 24,
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Theme(
              // Local override: parent theme is dark and has filled inputs +
              // dark selection — neither works on this white field.
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: AppColors.primary,
                  selectionColor: AppColors.primary.withValues(alpha: 0.25),
                  selectionHandleColor: AppColors.primary,
                ),
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                  _PhoneSpacerFormatter(),
                ],
                validator: Validators.phone,
                onFieldSubmitted: onSubmitted,
                cursorColor: AppColors.primary,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryOnLight,
                  letterSpacing: 0.5,
                ),
                decoration: const InputDecoration(
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: '98765 43210',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: AppColors.textTertiaryOnLight,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(right: AppSpacing.lg),
                  errorStyle: TextStyle(height: 0, fontSize: 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Auto-formats Indian phone numbers as "XXXXX XXXXX".
class _PhoneSpacerFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 5) buf.write(' ');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Full-width purple CTA used throughout the auth flow.
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 0,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
      ),
    );
  }
}

/// "----- OR CONTINUE WITH -----"
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        color: AppColors.primary.withValues(alpha: 0.15),
      ),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'OR CONTINUE WITH',
            style: AppTextStyles.brandFooter.copyWith(
              color: AppColors.textTertiaryOnLight,
              letterSpacing: 2,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

/// Outlined social sign-in row.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.leading,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: background == Colors.white
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: foreground,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stylized "G" glyph for the Google button. Not the official logo —
/// swap for an SVG asset once available.
class _GoogleGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFF4285F4),
            Color(0xFFEA4335),
            Color(0xFFFBBC05),
            Color(0xFF34A853),
            Color(0xFF4285F4),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            'G',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4285F4),
            ),
          ),
        ),
      ),
    );
  }
}
