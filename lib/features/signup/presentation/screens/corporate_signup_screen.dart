import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/uploads/upload_limits.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/file_upload_slot.dart';
import '../../../../core/widgets/picked_file.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/outlined_input.dart';
import '../../../../core/widgets/uploaded_file_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/domain/user_profile.dart';
import '../../../user/presentation/providers/user_profile_provider.dart';
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

  PickedFile? _panCinFile;
  PickedFile? _additionalFile;

  @override
  void dispose() {
    _company.dispose();
    _pan.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPanCin() async {
    final file = await _pickKycFile();
    if (file != null) setState(() => _panCinFile = file);
  }

  Future<void> _pickAdditional() async {
    final file = await _pickKycFile();
    if (file != null) setState(() => _additionalFile = file);
  }

  /// Picks a KYC document, then validates extension + size. Returns null
  /// when the user cancelled OR when the picked file violated the rules
  /// (in which case an error snack is already shown).
  Future<PickedFile?> _pickKycFile() async {
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

  Future<void> _onContinue() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go(AppRoutes.login);
      return;
    }
    // The company name is what flips isSetupComplete=true in the
    // user-profile gate. If it's empty the router would keep them
    // stuck here forever.
    if (_company.text.trim().isEmpty) {
      context.showErrorSnack('Enter your company name to continue');
      return;
    }
    try {
      final repo = ref.read(userProfileRepositoryProvider);
      await repo.saveCorporate(
        user.id,
        CorporateProfile(
          name: _company.text.trim(),
          panCin: _pan.text.trim(),
          officialEmail: _email.text.trim(),
          // Manager name isn't collected on this form (only the
          // phone is). Default to empty; user can edit via the
          // Personal Info screen later (Phase 1c).
          managerName: '',
          managerPhone: _phone.text.trim(),
        ),
      );
      // Best-effort KYC upload — non-fatal so a flaky upload doesn't trap
      // the user on the signup screen. They can re-upload later.
      try {
        await repo.uploadKycDocs(user.id, {
          if (_panCinFile != null) 'panCin': _panCinFile!,
          if (_additionalFile != null) 'additional': _additionalFile!,
        });
      } catch (e, st) {
        appLogger.w('KYC upload failed', error: e, stackTrace: st);
        if (mounted) {
          context.showSnack('Profile saved. Document upload will retry later.');
        }
      }
      if (!mounted) return;
      // Router redirect sees isSetupComplete=true and bounces to /home.
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnack('Could not save profile: $e');
    }
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
              hint: 'e.g. Acme Pvt. Ltd.',
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
                  emptySubtitle: UploadLimits.kycHint,
                  filledStatus: UploadStatus.uploaded,
                  filledIcon: Icons.insert_drive_file_outlined,
                  onRemove: () => setState(() => _panCinFile = null),
                ),
                const SizedBox(height: AppSpacing.md),
                FileUploadSlot(
                  file: _additionalFile,
                  onPickFile: _pickAdditional,
                  emptyTitle: 'Add more documents',
                  emptySubtitle: 'CIN, GST, Address Proof  ·  ${UploadLimits.kycHint}',
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
