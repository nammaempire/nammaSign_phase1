import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/uploads/upload_limits.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/file_upload_slot.dart';
import '../../../../core/widgets/india_flag.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/outlined_input.dart';
import '../../../../core/widgets/picked_file.dart';
import '../../../../core/widgets/uploaded_file_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/domain/user_profile.dart';
import '../../../user/presentation/providers/user_profile_provider.dart';
import '../widgets/signup_scaffold.dart';
import '../../../../app/theme/app_palette.dart';

/// "A few personal details." — individual account signup form.
class IndividualSignupScreen extends ConsumerStatefulWidget {
  const IndividualSignupScreen({super.key});

  @override
  ConsumerState<IndividualSignupScreen> createState() =>
      _IndividualSignupScreenState();
}

class _IndividualSignupScreenState
    extends ConsumerState<IndividualSignupScreen> {
  final _name = TextEditingController();
  final _dob = TextEditingController();
  final _phone = TextEditingController();
  final _aadhaar = TextEditingController();

  PickedFile? _aadhaarFront;
  PickedFile? _aadhaarBack;

  @override
  void initState() {
    super.initState();
    // Pre-fill the mobile field with the number the user signed in with,
    // shown as "98765 43210" (last 10 digits, spaced) so they see the
    // verified number instead of an empty box.
    final phone = ref.read(currentUserProvider)?.phone ?? '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      final local = digits.substring(digits.length - 10);
      _phone.text = '${local.substring(0, 5)} ${local.substring(5)}';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _phone.dispose();
    _aadhaar.dispose();
    super.dispose();
  }

  Future<PickedFile?> _pickFile() async {
    try {
      final file = await PickedFile.pick(
        extensions: UploadLimits.kycExtensions,
        label: 'KYC documents',
      );
      if (file == null) return null;
      final error = file.validate(
        allowedExtensions: UploadLimits.kycExtensions,
        maxBytes: UploadLimits.kycMaxBytes,
      );
      if (error != null) {
        if (mounted) context.showErrorSnack(error);
        return null;
      }
      return file;
    } catch (e, st) {
      appLogger.e('File pick failed', error: e, stackTrace: st);
      if (mounted) context.showErrorSnack('Could not open file picker');
      return null;
    }
  }

  Future<void> _pickAadhaarFront() async {
    final f = await _pickFile();
    if (f != null) setState(() => _aadhaarFront = f);
  }

  Future<void> _pickAadhaarBack() async {
    final f = await _pickFile();
    if (f != null) setState(() => _aadhaarBack = f);
  }

  Future<void> _onContinue() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go(AppRoutes.login);
      return;
    }
    // Full name flips isSetupComplete=true. Without it the router
    // would loop us back to the setup screens forever.
    if (_name.text.trim().isEmpty) {
      context.showErrorSnack('Enter your full name to continue');
      return;
    }
    // Only persist the last 4 digits of Aadhaar — never the full number.
    final aadhaarDigits = _aadhaar.text.replaceAll(RegExp(r'\D'), '');
    // Aadhaar stays optional here, but if entered it must be a valid 12-digit
    // number with a correct Verhoeff check digit (rejects typos / fakes).
    if (aadhaarDigits.isNotEmpty) {
      final aadhaarError = Validators.aadhaar(aadhaarDigits);
      if (aadhaarError != null) {
        context.showErrorSnack(aadhaarError);
        return;
      }
    }
    final aadhaarLast4 = aadhaarDigits.length >= 4
        ? aadhaarDigits.substring(aadhaarDigits.length - 4)
        : aadhaarDigits;
    try {
      final repo = ref.read(userProfileRepositoryProvider);
      await repo.saveIndividual(
        user.id,
        IndividualProfile(
          fullName: _name.text.trim(),
          dob: _parseDob(_dob.text.trim()),
          mobile: _phone.text.replaceAll(' ', ''),
          aadhaarLast4: aadhaarLast4,
        ),
      );
      // Best-effort KYC upload — non-fatal so a flaky upload doesn't trap
      // the user on the signup screen. They can re-upload later.
      try {
        await repo.uploadKycDocs(user.id, {
          'aadhaarFront': ?_aadhaarFront,
          'aadhaarBack': ?_aadhaarBack,
        });
      } catch (e, st) {
        appLogger.w('KYC upload failed', error: e, stackTrace: st);
        if (mounted) {
          context.showSnack('Profile saved. Document upload will retry later.');
        }
      }
      // Analytics — top of the individual funnel.
      await ref
          .read(analyticsServiceProvider)
          .signUpCompleted(accountType: 'individual');
      if (_aadhaarFront != null) {
        await ref
            .read(analyticsServiceProvider)
            .kycUploaded(docKind: 'aadhaar_front');
      }
      if (_aadhaarBack != null) {
        await ref
            .read(analyticsServiceProvider)
            .kycUploaded(docKind: 'aadhaar_back');
      }
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnack('Could not save profile: $e');
    }
  }

  /// "14 Mar 1992" → DateTime. Returns null on bad input.
  DateTime? _parseDob(String s) {
    if (s.isEmpty) return null;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final parts = s.split(' ');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = months.indexOf(parts[1]) + 1;
    final year = int.tryParse(parts[2]);
    if (day == null || month <= 0 || year == null) return null;
    return DateTime(year, month, day);
  }

  Future<void> _pickDob() async {
    final today = DateTime.now();
    // Must be at least 18 — the latest selectable DOB is 18 years ago today.
    final latestAdultDob = DateTime(today.year - 18, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year - 25),
      firstDate: DateTime(1920),
      lastDate: latestAdultDob,
      helpText: 'Select date of birth (must be 18+)',
    );
    if (picked == null) return;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    _dob.text = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      titlePart1: 'A few ',
      titlePart2Italic: 'personal details.',
      subtitle:
          'Aadhaar is used only for one-time verification. '
          'We never store the number on device.',
      onContinue: _onContinue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledFormField(
            label: 'FULL NAME (AS PER AADHAAR)',
            child: OutlinedInput(
              controller: _name,
              hint: 'e.g. Your full name',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          LabeledFormField(
            label: 'DATE OF BIRTH',
            child: OutlinedInput(
              controller: _dob,
              hint: '14 Mar 1992',
              leadingIcon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: _pickDob,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          LabeledFormField(
            label: 'MOBILE NUMBER',
            child: _PhoneInputWithFlag(controller: _phone),
          ),
          const SizedBox(height: AppSpacing.xl),

          LabeledFormField(
            label: 'AADHAAR NUMBER',
            child: OutlinedInput(
              controller: _aadhaar,
              hint: 'XXXX XXXX 4821',
              monospace: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
                _AadhaarSpacerFormatter(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          LabeledFormField(
            label: 'AADHAAR UPLOAD',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FileUploadSlot(
                  file: _aadhaarFront,
                  onPickFile: _pickAadhaarFront,
                  emptyTitle: 'Upload Aadhaar front',
                  emptySubtitle: UploadLimits.kycHint,
                  filledStatus: UploadStatus.uploaded,
                  filledIcon: Icons.image_outlined,
                  onRemove: () => setState(() => _aadhaarFront = null),
                ),
                const SizedBox(height: AppSpacing.md),
                FileUploadSlot(
                  file: _aadhaarBack,
                  onPickFile: _pickAadhaarBack,
                  emptyTitle: 'Upload Aadhaar back',
                  emptySubtitle: UploadLimits.kycHint,
                  filledStatus: UploadStatus.uploaded,
                  filledIcon: Icons.image_outlined,
                  onRemove: () => setState(() => _aadhaarBack = null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Phone input with flag + +91 prefix, matching the login screen pattern.
class _PhoneInputWithFlag extends StatefulWidget {
  const _PhoneInputWithFlag({required this.controller});
  final TextEditingController controller;

  @override
  State<_PhoneInputWithFlag> createState() => _PhoneInputWithFlagState();
}

class _PhoneInputWithFlagState extends State<_PhoneInputWithFlag> {
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
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.primary,
          selectionColor: AppColors.primary.withValues(alpha: 0.25),
          selectionHandleColor: AppColors.primary,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          // Match the other signup fields (grey/dark card), not white.
          color: context.colors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isFocused
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.15),
            width: isFocused ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.lg),
            const IndiaFlag(),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '+91',
              style: AppTextStyles.bodyLarge.copyWith(
                // Field is now the dark card colour, so the theme's light
                // textPrimary is the readable choice.
                color: context.colors.textPrimary,
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
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focus,
                keyboardType: TextInputType.phone,
                cursorColor: AppColors.primary,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  _PhoneSpacerFormatter(),
                ],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  // Light text on the dark card — matches the other fields.
                  color: context.colors.textPrimary,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: '98765 43210',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: context.colors.textTertiary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// "9876543210" → "98765 43210"
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

/// "123456789012" → "1234 5678 9012"
class _AadhaarSpacerFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
