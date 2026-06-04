import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/outlined_input.dart';
import '../../../account_type/domain/account_type.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/domain/user_profile.dart';
import '../../../user/presentation/providers/user_profile_provider.dart';
import '../../../../app/theme/app_palette.dart';

/// "Personal info" — auto-fills with the data the user already entered
/// during signup and lets them edit it. Saves back to Firestore
/// `users/{uid}` via the same repository the signup forms use.
class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() =>
      _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  // Corporate fields
  final _company = TextEditingController();
  final _pan = TextEditingController();
  final _email = TextEditingController();
  final _managerName = TextEditingController();
  final _managerPhone = TextEditingController();

  // Individual fields
  final _fullName = TextEditingController();
  final _dob = TextEditingController();
  final _mobile = TextEditingController();
  final _aadhaarLast4 = TextEditingController();

  bool _seeded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _company.dispose();
    _pan.dispose();
    _email.dispose();
    _managerName.dispose();
    _managerPhone.dispose();
    _fullName.dispose();
    _dob.dispose();
    _mobile.dispose();
    _aadhaarLast4.dispose();
    super.dispose();
  }

  /// One-time seed of the text controllers from the live profile.
  ///
  /// For phone fields (manager phone / mobile) we fall back to the
  /// signed-in user's auth phone number when the profile field is empty,
  /// so the OTP number the user just typed in shows up here automatically.
  void _seedFrom(UserProfile profile) {
    if (_seeded) return;
    _seeded = true;
    final authPhone = ref.read(currentUserProvider)?.phone ?? '';
    final org = profile.corporate;
    if (org != null) {
      _company.text = org.name;
      _pan.text = org.panCin;
      _email.text = org.officialEmail;
      _managerName.text = org.managerName;
      _managerPhone.text =
          org.managerPhone.isNotEmpty ? org.managerPhone : authPhone;
    }
    final personal = profile.individual;
    if (personal != null) {
      _fullName.text = personal.fullName;
      if (personal.dob != null) {
        _dob.text = _formatDob(personal.dob!);
      }
      _mobile.text = personal.mobile.isNotEmpty ? personal.mobile : authPhone;
      _aadhaarLast4.text = 'XXXX XXXX ${personal.aadhaarLast4}';
    }
  }

  static String _formatDob(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _save(UserProfile profile) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(userProfileRepositoryProvider);
      if (profile.accountType == AccountType.corporate) {
        await repo.saveCorporate(
          user.id,
          CorporateProfile(
            name: _company.text.trim(),
            panCin: _pan.text.trim(),
            officialEmail: _email.text.trim(),
            managerName: _managerName.text.trim(),
            managerPhone: _managerPhone.text.trim(),
          ),
        );
      } else {
        await repo.saveIndividual(
          user.id,
          IndividualProfile(
            fullName: _fullName.text.trim(),
            dob: profile.individual?.dob,
            mobile: _mobile.text.trim(),
            aadhaarLast4: profile.individual?.aadhaarLast4 ?? '',
          ),
        );
      }
      if (!mounted) return;
      context.showSnack('Personal info saved');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnack('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('No profile yet.'));
            }
            // Seed once on first build with real data.
            _seedFrom(profile);

            return Column(
              children: [
                // Back row
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
                        onTap: () => context.canPop()
                            ? context.pop()
                            : context.go(AppRoutes.profile),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Personal ',
                          style: AppTextStyles.brandHuge.copyWith(
                            fontSize: 28,
                            color: context.colors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          'info.',
                          style: AppTextStyles.brandHugeItalic.copyWith(
                            fontSize: 28,
                            color: AppColors.primary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          profile.accountType == AccountType.corporate
                              ? "Your company's details. Used for "
                                  'verification and invoicing.'
                              : 'Your personal details. Used for one-time '
                                  'Aadhaar verification.',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        if (profile.accountType == AccountType.corporate)
                          ..._corporateFields()
                        else if (profile.accountType ==
                            AccountType.individual)
                          ..._individualFields(),

                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),

                // Save button
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
                      onPressed: _saving ? null : () => _save(profile),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              'Save changes',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _corporateFields() => [
        LabeledFormField(
          label: 'COMPANY NAME',
          child: OutlinedInput(controller: _company),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledFormField(
          label: 'PAN / CIN NUMBER',
          child: OutlinedInput(controller: _pan, monospace: true),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledFormField(
          label: 'OFFICIAL EMAIL',
          showIndicator: false,
          child: OutlinedInput(
            controller: _email,
            leadingIcon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledFormField(
          label: 'MANAGER NAME',
          showIndicator: false,
          child: OutlinedInput(controller: _managerName),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledFormField(
          label: 'MANAGER PHONE',
          showIndicator: false,
          child: OutlinedInput(
            controller: _managerPhone,
            leadingIcon: Icons.phone_outlined,
          ),
        ),
      ];

  List<Widget> _individualFields() => [
        LabeledFormField(
          label: 'FULL NAME (AS PER AADHAAR)',
          child: OutlinedInput(controller: _fullName),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledFormField(
          label: 'DATE OF BIRTH',
          showIndicator: false,
          child: OutlinedInput(
            controller: _dob,
            leadingIcon: Icons.calendar_today_outlined,
            locked: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledFormField(
          label: 'MOBILE NUMBER',
          showIndicator: false,
          child: OutlinedInput(
            controller: _mobile,
            leadingIcon: Icons.phone_outlined,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledFormField(
          label: 'AADHAAR NUMBER',
          showIndicator: false,
          child: OutlinedInput(
            controller: _aadhaarLast4,
            monospace: true,
            locked: true,
          ),
        ),
      ];
}
