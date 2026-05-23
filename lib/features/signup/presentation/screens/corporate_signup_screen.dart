import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/file_upload_slot.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/outlined_input.dart';
import '../../../../core/widgets/uploaded_file_card.dart';
import '../widgets/signup_scaffold.dart';

/// "Tell us about your company." — corporate account signup form.
///
/// Verification slots start EMPTY. User taps an upload area, picks a file
/// via the platform picker, and the filename appears in the slot.
class CorporateSignupScreen extends ConsumerStatefulWidget {
  const CorporateSignupScreen({super.key});

  @override
  ConsumerState<CorporateSignupScreen> createState() =>
      _CorporateSignupScreenState();
}

class _CorporateSignupScreenState extends ConsumerState<CorporateSignupScreen> {
  final _company = TextEditingController();
  final _pan = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  PlatformFile? _panCinFile;
  PlatformFile? _additionalFile;

  @override
  void dispose() {
    _company.dispose();
    _pan.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPanCin() async {
    final file = await _pickFile(allowed: ['pdf', 'jpg', 'jpeg', 'png']);
    if (file != null) setState(() => _panCinFile = file);
  }

  Future<void> _pickAdditional() async {
    final file = await _pickFile(allowed: ['pdf', 'jpg', 'jpeg', 'png']);
    if (file != null) setState(() => _additionalFile = file);
  }

  Future<PlatformFile?> _pickFile({required List<String> allowed}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowed,
        withData: false,
      );
      return result?.files.firstOrNull;
    } catch (e, st) {
      appLogger.e('File pick failed', error: e, stackTrace: st);
      if (mounted) context.showErrorSnack('Could not open file picker');
      return null;
    }
  }

  void _onContinue() {
    context.showSnack('Account created (demo). Sign in to continue.');
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      titlePart1: 'Tell us about your',
      titlePart2Italic: 'company.',
      subtitle: 'We use this to verify your business and bill correctly.',
      onContinue: _onContinue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledFormField(
            label: 'COMPANY NAME',
            child: OutlinedInput(
              controller: _company,
              hint: 'Brigade Enterprises Ltd.',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          LabeledFormField(
            label: 'PAN / CIN NUMBER',
            child: OutlinedInput(
              controller: _pan,
              hint: 'L85110KA1995PLC019126',
              monospace: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(21),
                TextInputFormatter.withFunction(
                  (oldValue, newValue) => TextEditingValue(
                    text: newValue.text.toUpperCase(),
                    selection: newValue.selection,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          LabeledFormField(
            label: 'OFFICIAL EMAIL',
            child: OutlinedInput(
              controller: _email,
              hint: 'ads@brigadegroup.com',
              keyboardType: TextInputType.emailAddress,
              leadingIcon: Icons.mail_outline_rounded,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          LabeledFormField(
            label: 'MANAGER PHONE',
            child: OutlinedInput(
              controller: _phone,
              hint: '+91 98450 12345',
              keyboardType: TextInputType.phone,
              leadingIcon: Icons.phone_outlined,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d +]')),
                LengthLimitingTextInputFormatter(18),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          LabeledFormField(
            label: 'VERIFICATION DOCUMENTS',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FileUploadSlot(
                  file: _panCinFile,
                  onPickFile: _pickPanCin,
                  emptyTitle: 'Upload PAN / CIN document',
                  emptySubtitle: 'PDF or JPG  ·  max 5MB',
                  filledStatus: UploadStatus.uploaded,
                  filledIcon: Icons.insert_drive_file_outlined,
                  onRemove: () => setState(() => _panCinFile = null),
                ),
                const SizedBox(height: AppSpacing.md),
                FileUploadSlot(
                  file: _additionalFile,
                  onPickFile: _pickAdditional,
                  emptyTitle: 'Add more documents',
                  emptySubtitle: 'CIN, GST, Address Proof  ·  PDF or JPG',
                  filledStatus: UploadStatus.uploaded,
                  filledIcon: Icons.insert_drive_file_outlined,
                  onRemove: () => setState(() => _additionalFile = null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
