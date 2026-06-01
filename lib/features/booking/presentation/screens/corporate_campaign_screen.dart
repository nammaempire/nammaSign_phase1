import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/picked_file.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/outlined_input.dart';
import '../../../user/presentation/providers/user_profile_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_top_bar.dart';
import '../widgets/creative_preview.dart';
import '../widgets/creative_upload_button.dart';
import '../widgets/duration_selector.dart';

/// Step 2 — corporate flow. Read-only organisation + campaign ID, then
/// editable manager / title / description, duration (7/15/30), creative
/// preview, and an Add/Replace creative zone.
class CorporateCampaignScreen extends ConsumerStatefulWidget {
  const CorporateCampaignScreen({super.key});

  @override
  ConsumerState<CorporateCampaignScreen> createState() =>
      _CorporateCampaignScreenState();
}

class _CorporateCampaignScreenState
    extends ConsumerState<CorporateCampaignScreen> {
  final _org = TextEditingController();
  final _manager = TextEditingController();
  final _campaignId = TextEditingController();
  final _title = TextEditingController();
  final _desc = TextEditingController();

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
    // Seed controllers from the booking draft + the user's real profile.
    final draft = ref.read(bookingProvider);
    final corp = ref.read(userProfileProvider).valueOrNull?.corporate;
    _org.text = corp?.name ?? '';
    _manager.text = draft.manager ?? corp?.managerName ?? '';
    _campaignId.text = draft.campaignId ?? '';
    // Sync initial values back into the draft so payment screen sees them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(bookingProvider.notifier);
      notifier
        ..setManager(_manager.text)
        ..setCampaignTitle(_title.text)
        ..setDescription(_desc.text);
    });
  }

  @override
  void dispose() {
    _org.dispose();
    _manager.dispose();
    _campaignId.dispose();
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool isVideo}) async {
    try {
      final file = await PickedFile.pick(
        extensions: isVideo ? ['mp4', 'mov'] : ['jpg', 'jpeg', 'png'],
        label: isVideo ? 'videos' : 'images',
      );
      if (file == null) return;
      ref
          .read(bookingProvider.notifier)
          .setCreative(file, isVideo: isVideo);
    } catch (e, st) {
      appLogger.e('File pick failed', error: e, stackTrace: st);
      if (mounted) context.showErrorSnack('Could not open file picker');
    }
  }

  void _onContinue() {
    context.push(AppRoutes.bookingReview);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const BookingTopBar(currentStep: 2),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your ',
                      style: AppTextStyles.brandHuge.copyWith(
                        fontSize: 30,
                        color: AppColors.textPrimaryOnLight,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'campaign.',
                      style: AppTextStyles.brandHugeItalic.copyWith(
                        fontSize: 30,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      "Tell us what's running, how long, and upload "
                      'your creative.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondaryOnLight,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    LabeledFormField(
                      label: 'ORGANISATION',
                      showIndicator: false,
                      child: OutlinedInput(controller: _org, locked: true),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: LabeledFormField(
                            label: 'MANAGER',
                            showIndicator: false,
                            child: OutlinedInput(
                              controller: _manager,
                              onChanged: (v) => ref
                                  .read(bookingProvider.notifier)
                                  .setManager(v),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: LabeledFormField(
                            label: 'CAMPAIGN ID',
                            showIndicator: false,
                            child: OutlinedInput(
                              controller: _campaignId,
                              locked: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    LabeledFormField(
                      label: 'ADVERTISING TITLE',
                      child: OutlinedInput(
                        controller: _title,
                        onChanged: (v) => ref
                            .read(bookingProvider.notifier)
                            .setCampaignTitle(v),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    LabeledFormField(
                      label: 'DESCRIPTION',
                      showIndicator: false,
                      child: OutlinedInput(
                        controller: _desc,
                        maxLines: 3,
                        onChanged: (v) => ref
                            .read(bookingProvider.notifier)
                            .setDescription(v),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    LabeledFormField(
                      label: 'DURATION',
                      child: DurationSelector(
                        options: const [
                          DurationOption(days: 7),
                          DurationOption(days: 15, discountLabel: 'SAVE 8%'),
                          DurationOption(days: 30),
                        ],
                        selected: draft.durationDays ?? 15,
                        onChanged: (d) =>
                            ref.read(bookingProvider.notifier).setDuration(d),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    CreativePreview(
                      file: draft.creativeFile,
                      isVideo: draft.creativeIsVideo,
                      headerLabel: 'Creative preview  ·  Live on board',
                      fallbackTitle: 'Your creative here',
                      fallbackSubtitle: 'Add a photo or video below',
                      onVideoTooLong: () => context.showErrorSnack(
                        'Video is longer than 20 seconds. Trim it first.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    CreativeUploadButton(
                      title: draft.creativeFile != null
                          ? 'Replace creative'
                          : 'Add creative',
                      subtitle: 'JPG / PNG / MP4  ·  up to 50MB',
                      onPickImage: () => _pick(isVideo: false),
                      onPickVideo: () => _pick(isVideo: true),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // CTA
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
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to payment',
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
}
