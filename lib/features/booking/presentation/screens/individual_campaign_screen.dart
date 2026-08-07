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
import '../../../../app/theme/app_palette.dart';

/// Step 2 — individual flow. Simpler form: name, purpose, message, fixed
/// 1-day duration with the listing's price, creative upload.
class IndividualCampaignScreen extends ConsumerStatefulWidget {
  const IndividualCampaignScreen({super.key});

  @override
  ConsumerState<IndividualCampaignScreen> createState() =>
      _IndividualCampaignScreenState();
}

class _IndividualCampaignScreenState
    extends ConsumerState<IndividualCampaignScreen> {
  final _name = TextEditingController();
  final _purpose = TextEditingController();
  final _message = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill the name from the user's profile; leave purpose/message
    // blank for the user to write their own.
    final individual = ref.read(userProfileProvider).valueOrNull?.individual;
    _name.text = individual?.fullName ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(bookingProvider.notifier);
      notifier
        ..setManager(_name.text)
        ..setPurpose(_purpose.text)
        ..setDescription(_message.text)
        ..setDuration(1);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _purpose.dispose();
    _message.dispose();
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
    // Gate payment behind KYC: only a verified user may proceed. Otherwise
    // show a clear alert and stay on this screen.
    final kycStatus =
        ref.read(userProfileProvider).valueOrNull?.kycStatus ?? 'none';
    if (kycStatus != 'verified') {
      _showKycNotVerifiedDialog();
      return;
    }
    context.push(AppRoutes.bookingReview);
  }

  void _showKycNotVerifiedDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('KYC verification required'),
        content: const Text(
          'Your KYC is not verified yet. Please complete your KYC verification '
          'first — you can continue to payment once it has been verified by '
          'our team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingProvider);
    final price = draft.listing?.pricePerDay ?? 0;

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
                      'Make it ',
                      style: AppTextStyles.brandHuge.copyWith(
                        fontSize: 30,
                        color: context.colors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'personal.',
                      style: AppTextStyles.brandHugeItalic.copyWith(
                        fontSize: 30,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Birthdays, proposals, shoutouts — your message on the '
                      'big screen, for one day.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    LabeledFormField(
                      label: 'YOUR NAME',
                      child: OutlinedInput(
                        controller: _name,
                        onChanged: (v) =>
                            ref.read(bookingProvider.notifier).setManager(v),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    LabeledFormField(
                      label: 'PURPOSE',
                      child: OutlinedInput(
                        controller: _purpose,
                        onChanged: (v) =>
                            ref.read(bookingProvider.notifier).setPurpose(v),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    LabeledFormField(
                      label: 'MESSAGE / DESCRIPTION',
                      showIndicator: false,
                      child: OutlinedInput(
                        controller: _message,
                        maxLines: 3,
                        onChanged: (v) => ref
                            .read(bookingProvider.notifier)
                            .setDescription(v),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    LabeledFormField(
                      label: 'DURATION',
                      showIndicator: false,
                      child: _OneDayChip(price: price),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    (draft.creativeImages.length >= 2 &&
                            !draft.creativeIsVideo)
                        ? CreativeSlideshowPreview(
                            images: draft.creativeImages,
                            headerLabel: 'Preview  ·  6:00 PM slot',
                          )
                        : CreativePreview(
                      file: draft.creativeFile,
                      isVideo: draft.creativeIsVideo,
                      headerLabel: 'Preview  ·  6:00 PM slot',
                      fallbackTitle: 'Your message here',
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
                          ? 'Replace photo or video'
                          : 'Add photo or video',
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

class _OneDayChip extends StatelessWidget {
  const _OneDayChip({required this.price});
  final int price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.badgeDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1 Day',
                style: AppTextStyles.brandHuge.copyWith(
                  fontSize: 22,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'DEFAULT FOR INDIVIDUAL',
                style: AppTextStyles.brandFooter.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '₹$price',
            style: AppTextStyles.brandHuge.copyWith(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.check_rounded, color: AppColors.success, size: 18),
        ],
      ),
    );
  }
}
