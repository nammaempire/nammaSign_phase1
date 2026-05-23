import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/file_upload_slot.dart';
import '../../../../core/widgets/india_flag.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/outlined_input.dart';
import '../../../../core/widgets/uploaded_file_card.dart';
import '../widgets/signup_scaffold.dart';

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

  PlatformFile? _aadhaarFront;
  PlatformFile? _aadhaarBack;

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _phone.dispose();
    _aadhaar.dispose();
    super.dispose();
  }

  Future<PlatformFile?> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: false,
      );
      return result?.files.firstOrNull;
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

  void _onContinue() {
    context.showSnack('Account created (demo). Sign in to continue.');
    context.go(AppRoutes.login);
  }

  Future<void> _pickDob() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year - 25),
      firstDate: DateTime(1920),
      lastDate: today,
      helpText: 'Select date of birth',
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
      subtitle: 'Aadhaar is used only for one-time verification. '
          'We never store the number on device.',
      onContinue: _onContinue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledFormField(
            label: 'FULL NAME (AS PER AADHAAR)',
            child: OutlinedInput(
              controller: _name,
              hint: 'Karthik Subramaniam',
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
                  emptySubtitle: 'JPG or PDF  ·  max 5MB',
                  filledStatus: UploadStatus.uploaded,
                  filledIcon: Icons.image_outlined,
                  onRemove: () => setState(() => _aadhaarFront = null),
                ),
                const SizedBox(height: AppSpacing.md),
                FileUploadSlot(
                  file: _aadhaarBack,
                  onPickFile: _pickAadhaarBack,
                  emptyTitle: 'Upload Aadhaar back',
                  emptySubtitle: 'JPG or PDF  ·  max 5MB',
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
          color: Colors.white,
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
                  contentPadding:
                      EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  errorStyle: TextStyle(height: 0, fontSize: 0),
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
