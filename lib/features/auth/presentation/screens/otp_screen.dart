import 'dart:async';

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
import '../../../../core/widgets/otp_box_field.dart';
import '../providers/auth_provider.dart';
import '../../../../app/theme/app_palette.dart';

/// OTP verification screen — matches the Figma exactly.
/// Back button, serif title with italic '6-digit code', phone + Edit,
/// 6-box OTP input, resend countdown + paste-from-sms, verify CTA.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _resendSeconds = 30;
  final _otpKey = GlobalKey<OtpBoxFieldState>();
  String _code = '';
  int _secondsLeft = _resendSeconds;
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _secondsLeft = _resendSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) t.cancel();
      });
    });
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _verify() async {
    if (_code.length != AppConstants.otpLength) {
      context.showErrorSnack(
        'Enter the ${AppConstants.otpLength}-digit code',
      );
      return;
    }

    // verifyOtp posts the SMS code to Firebase Auth using the verificationId
    // captured during sendOtp on the Login screen. On success the auth state
    // stream emits a user → router redirects to /home. On failure the
    // ref.listen handler below shows the real Firebase error message.
    setState(() => _isVerifying = true);
    await ref.read(otpFlowProvider.notifier).verifyOtp(_code);
    if (!mounted) return;
    setState(() => _isVerifying = false);
  }

  Future<void> _resend() async {
    final flow = ref.read(otpFlowProvider);
    if (flow is! OtpCodeSent) return;
    await ref.read(otpFlowProvider.notifier).sendOtp(flow.phone);
    if (!mounted) return;
    _startCountdown();
    context.showSnack('Code resent');
  }

  Future<void> _pasteFromSms() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text ?? '';
    final match = RegExp(r'\d{6}').firstMatch(raw);
    if (match == null) {
      if (!mounted) return;
      context.showSnack('No 6-digit code found in clipboard');
      return;
    }
    _otpKey.currentState?.setValue(match.group(0)!);
    setState(() => _code = match.group(0)!);
  }

  void _editPhone() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Drive UI feedback off the OTP flow state.
    //   - OtpVerified → push to /home explicitly (don't wait for the
    //     router redirect to catch up — Firebase's authStateChanges
    //     stream can emit a tick after verifyOtp resolves, so the
    //     redirect alone causes a visible "stuck on OTP" beat).
    //   - OtpError → surface the real Firebase message to the user.
    ref.listen<OtpFlowState>(otpFlowProvider, (prev, next) {
      if (next is OtpVerified) {
        context.go(AppRoutes.home);
      } else if (next is OtpError) {
        context.showErrorSnack(next.message);
      }
    });

    final flow = ref.watch(otpFlowProvider);
    final isVerifying = _isVerifying;
    final phone = flow is OtpCodeSent ? flow.phone : '';

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Back
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _editPhone,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                            color: context.colors.textPrimary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'BACK',
                            style: AppTextStyles.brandFooter.copyWith(
                              color: context.colors.textPrimary,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title — "Enter the *6-digit code.*"
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.brandHuge.copyWith(
                          fontSize: 32,
                          color: context.colors.textPrimary,
                          height: 1.15,
                        ),
                        children: [
                          const TextSpan(text: 'Enter the '),
                          TextSpan(
                            text: '6-digit\ncode.',
                            style: AppTextStyles.brandHugeItalic.copyWith(
                              fontSize: 32,
                              color: AppColors.primary,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Subtitle
                    Text(
                      'We sent a verification code to',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          _formatPhone(phone),
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        GestureDetector(
                          onTap: _editPhone,
                          child: Text(
                            'Edit',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // OTP boxes
                    OtpBoxField(
                      key: _otpKey,
                      onChanged: (v) => setState(() => _code = v),
                      onCompleted: (_) => _verify(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Resend timer + paste from SMS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ResendLabel(
                          secondsLeft: _secondsLeft,
                          format: _formatTime,
                          onResend: _resend,
                        ),
                        GestureDetector(
                          onTap: _pasteFromSms,
                          child: Text(
                            'PASTE FROM SMS',
                            style: AppTextStyles.brandFooter.copyWith(
                              color: context.colors.textTertiary,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Verify CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                0,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isVerifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: isVerifying
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Verify & continue',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "+91 9876543210" → "+91 98765 43210" for display.
  String _formatPhone(String raw) {
    if (raw.isEmpty) return '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return raw;
    final tenDigit = digits.substring(digits.length - 10);
    final cc = digits.substring(0, digits.length - 10);
    return '+$cc ${tenDigit.substring(0, 5)} ${tenDigit.substring(5)}';
  }
}

/// "RESEND IN 0:28" while counting down; tappable "RESEND CODE" at 0.
class _ResendLabel extends StatelessWidget {
  const _ResendLabel({
    required this.secondsLeft,
    required this.format,
    required this.onResend,
  });

  final int secondsLeft;
  final String Function(int) format;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    if (secondsLeft > 0) {
      return Row(
        children: [
          Text(
            'RESEND IN ',
            style: AppTextStyles.brandFooter.copyWith(
              color: context.colors.textTertiary,
              letterSpacing: 2,
            ),
          ),
          Text(
            format(secondsLeft),
            style: AppTextStyles.brandFooter.copyWith(
              color: AppColors.primary,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: onResend,
      child: Text(
        'RESEND CODE',
        style: AppTextStyles.brandFooter.copyWith(
          color: AppColors.primary,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
