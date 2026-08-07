import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/picked_file.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/uploads/upload_limits.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/outlined_input.dart';
import '../../../user/presentation/providers/user_profile_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_top_bar.dart';
import '../widgets/creative_preview.dart';
import '../widgets/creative_slideshow_preview.dart';
import '../widgets/creative_upload_button.dart';
import '../widgets/creative_thumbs.dart';
import '../widgets/duration_selector.dart';
import '../../../../app/theme/app_palette.dart';

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
    if (isVideo) {
      await _pickVideo();
    } else {
      await _pickImages();
    }
  }

  Future<void> _pickImages() async {
    final allowed = UploadLimits.creativeImageExtensions;
    final maxBytes = UploadLimits.creativeImageMaxBytes;
    try {
      final existing = ref.read(bookingProvider).creativeImages;
      final picked = await PickedFile.pickMultiple(
        extensions: allowed,
        label: 'images',
      );
      if (picked.isEmpty) return;
      final valid = <PickedFile>[];
      for (final f in picked) {
        final error =
            f.validate(allowedExtensions: allowed, maxBytes: maxBytes);
        if (error != null) {
          if (mounted) context.showErrorSnack(error);
          continue;
        }
        valid.add(f);
      }
      if (valid.isEmpty) return;
      final combined = [...existing, ...valid];
      if (combined.length > 5 && mounted) {
        context.showSnack('Up to 5 photos allowed — extras were skipped.');
      }
      ref
          .read(bookingProvider.notifier)
          .setCreativeImages(combined.take(5).toList());
    } catch (e, st) {
      appLogger.e('File pick failed', error: e, stackTrace: st);
      if (mounted) context.showErrorSnack('Could not open file picker');
    }
  }

  Future<void> _pickVideo() async {
    final allowed = UploadLimits.creativeVideoExtensions;
    final maxBytes = UploadLimits.creativeVideoMaxBytes;
    try {
      final file =
          await PickedFile.pick(extensions: allowed, label: 'videos');
      if (file == null) return;
      final error =
          file.validate(allowedExtensions: allowed, maxBytes: maxBytes);
      if (error != null) {
        if (mounted) context.showErrorSnack(error);
        return;
      }
      ref.read(bookingProvider.notifier).setCreative(file, isVideo: true);
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
      backgroundColor: context.colors.bg,
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
                        color: context.colors.textPrimary,
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
                        color: context.colors.textSecondary,
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

                    (draft.creativeImages.length >= 2 &&
                            !draft.creativeIsVideo)
                        ? CreativeSlideshowPreview(
                            images: draft.creativeImages,
                            headerLabel: 'Creative preview  ·  Live on board',
                          )
                        : CreativePreview(
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

                    CreativeThumbs(
                      images: draft.creativeImages,
                      onRemove: (i) => ref
                          .read(bookingProvider.notifier)
                          .removeCreativeImageAt(i),
                    ),

                    CreativeUploadButton(
                      title: draft.creativeFile != null
                          ? 'Replace creative'
                          : 'Add creative',
                      subtitle: 'Up to 5 photos  ·  or one MP4 video',
                      onPickImage: () => _pick(isVideo: false),
                      onPickVideo: () => _pick(isVideo: true),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Maximum 25 seconds allowed · photos auto-play as a '
                        'slideshow.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.colors.textTertiary,
                        ),
                      ),
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
