import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/outlined_input.dart';
import '../../../user/domain/user_profile.dart';

/// Bottom sheet that collects a company's details (name, PAN, GSTIN,
/// official email) when an individual-enrolled user chooses to advertise
/// as a corporate. Pops `true` once the details are validated + saved.
class CompanyDetailsSheet extends StatefulWidget {
  const CompanyDetailsSheet({
    super.key,
    required this.managerName,
    required this.managerPhone,
    required this.initialEmail,
    required this.onSubmit,
  });

  final String managerName;
  final String managerPhone;
  final String initialEmail;
  final Future<void> Function(CorporateProfile data) onSubmit;

  static Future<bool?> show(
    BuildContext context, {
    required String managerName,
    required String managerPhone,
    required String initialEmail,
    required Future<void> Function(CorporateProfile data) onSubmit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompanyDetailsSheet(
        managerName: managerName,
        managerPhone: managerPhone,
        initialEmail: initialEmail,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<CompanyDetailsSheet> createState() => _CompanyDetailsSheetState();
}

class _CompanyDetailsSheetState extends State<CompanyDetailsSheet> {
  final _company = TextEditingController();
  final _pan = TextEditingController();
  final _gstin = TextEditingController();
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);
  bool _saving = false;

  static final _upper = TextInputFormatter.withFunction(
    (oldV, newV) => TextEditingValue(
      text: newV.text.toUpperCase(),
      selection: newV.selection,
    ),
  );

  @override
  void dispose() {
    _company.dispose();
    _pan.dispose();
    _gstin.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_company.text.trim().isEmpty) {
      context.showErrorSnack('Enter your company name');
      return;
    }
    final panErr = Validators.pan(_pan.text, corporate: true);
    if (panErr != null) {
      context.showErrorSnack(panErr);
      return;
    }
    final gstErr = Validators.gstin(_gstin.text, expectedPan: _pan.text.trim());
    if (gstErr != null) {
      context.showErrorSnack(gstErr);
      return;
    }
    final emailErr = Validators.email(_email.text);
    if (emailErr != null) {
      context.showErrorSnack(emailErr);
      return;
    }
    setState(() => _saving = true);
    final data = CorporateProfile(
      name: _company.text.trim(),
      panCin: _pan.text.trim().toUpperCase(),
      gstin: _gstin.text.trim().toUpperCase(),
      officialEmail: _email.text.trim(),
      managerName: widget.managerName,
      managerPhone: widget.managerPhone,
    );
    try {
      await widget.onSubmit(data);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        context.showErrorSnack('Could not save company details: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.bg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Company details',
                style: AppTextStyles.brandHuge.copyWith(
                  fontSize: 24,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'To advertise as a corporate, tell us about the company '
                'paying for this campaign.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              LabeledFormField(
                label: 'COMPANY NAME',
                child: OutlinedInput(
                  controller: _company,
                  hint: 'e.g. Acme Pvt. Ltd.',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledFormField(
                label: 'COMPANY PAN',
                child: OutlinedInput(
                  controller: _pan,
                  hint: 'AAACX1234C',
                  monospace: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(10),
                    _upper,
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledFormField(
                label: 'GSTIN',
                child: OutlinedInput(
                  controller: _gstin,
                  hint: '29AAACX1234C1ZP',
                  monospace: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(15),
                    _upper,
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledFormField(
                label: 'OFFICIAL EMAIL',
                child: OutlinedInput(
                  controller: _email,
                  hint: 'ads@company.com',
                  keyboardType: TextInputType.emailAddress,
                  leadingIcon: Icons.mail_outline_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save & continue',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
