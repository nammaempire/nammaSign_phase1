import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/uploads/upload_limits.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/picked_file.dart';
import '../../../account_type/domain/account_type.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/domain/user_profile.dart';
import '../../../user/presentation/providers/user_profile_provider.dart';
import '../../../../app/theme/app_palette.dart';

/// KYC documents — lets the user preview the ID documents they uploaded and,
/// while their KYC is still unverified, replace any of them. Once an admin
/// marks the account 'verified', the documents become read-only.
class KycDocumentsScreen extends ConsumerStatefulWidget {
  const KycDocumentsScreen({super.key});

  @override
  ConsumerState<KycDocumentsScreen> createState() =>
      _KycDocumentsScreenState();
}

class _KycDocumentsScreenState extends ConsumerState<KycDocumentsScreen> {
  // Which slot is uploading right now (null = none).
  String? _uploadingLabel;

  Future<void> _replace(String label) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final file = await PickedFile.pick(
        extensions: UploadLimits.kycExtensions,
        label: 'KYC documents',
      );
      if (file == null) return;
      final error = file.validate(
        allowedExtensions: UploadLimits.kycExtensions,
        maxBytes: UploadLimits.kycMaxBytes,
      );
      if (error != null) {
        if (mounted) context.showErrorSnack(error);
        return;
      }
      setState(() => _uploadingLabel = label);
      await ref
          .read(userProfileRepositoryProvider)
          .uploadKycDocs(user.id, {label: file});
      if (mounted) {
        context.showSnack('Document updated — sent back for review.');
      }
    } catch (e, st) {
      appLogger.e('KYC replace failed', error: e, stackTrace: st);
      if (mounted) {
        context.showErrorSnack('Could not upload. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _uploadingLabel = null);
    }
  }

  /// Document slots for the account type: (storage key, human label).
  List<(String, String)> _slotsFor(UserProfile p) {
    switch (p.accountType) {
      case AccountType.corporate:
        return const [
          ('panCin', 'PAN / CIN document'),
          ('additional', 'Additional document'),
        ];
      case AccountType.individual:
        return const [
          ('aadhaarFront', 'Aadhaar — front'),
          ('aadhaarBack', 'Aadhaar — back'),
        ];
      case null:
        return const [];
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
          error: (e, _) => Center(
            child: Text(
              "Couldn't load documents\n$e",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return Center(
                child: Text(
                  'No profile found.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
              );
            }
            final verified = profile.kycStatus == 'verified';
            final slots = _slotsFor(profile);
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                _BackBar(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'KYC documents',
                  style: AppTextStyles.brandHuge.copyWith(
                    fontSize: 28,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _StatusBanner(status: profile.kycStatus),
                const SizedBox(height: AppSpacing.xl),
                for (final (key, label) in slots) ...[
                  _DocCard(
                    label: label,
                    url: profile.kycDocs[key],
                    locked: verified,
                    uploading: _uploadingLabel == key,
                    onReplace: () => _replace(key),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (!verified) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'You can replace your documents until they are verified. '
                    'Uploading a new file sends it back for review.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.profile),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chevron_left_rounded,
                size: 22,
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
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'verified' => ('Verified', AppColors.success),
      'rejected' => ('Rejected — please re-upload', AppColors.error),
      'pending' => ('Pending review', AppColors.warning),
      _ => ('Not uploaded yet', context.colors.textTertiary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'KYC status: $label',
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.label,
    required this.url,
    required this.locked,
    required this.uploading,
    required this.onReplace,
  });

  final String label;
  final String? url;
  final bool locked;
  final bool uploading;
  final VoidCallback onReplace;

  bool get _hasDoc => url != null && url!.isNotEmpty;
  bool get _isPdf =>
      _hasDoc && Uri.decodeFull(url!).toLowerCase().contains('.pdf');

  void _openFullScreen(BuildContext context) {
    if (!_hasDoc || _isPdf) return;
    showDialog<void>(
      context: context,
      builder: (_) => _FullScreenImage(url: url!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => _openFullScreen(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: _preview(context),
              ),
            ),
          ),
          if (_hasDoc && !_isPdf) ...[
            const SizedBox(height: 4),
            Text(
              'Tap the image to view it full-screen.',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (locked)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Verified — locked',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'This document is verified and can no longer be changed. '
                  'To update it, please contact our customer support team.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: uploading ? null : onReplace,
                icon: uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_outlined, size: 18),
                label: Text(
                  uploading
                      ? 'Uploading…'
                      : (_hasDoc ? 'Replace document' : 'Upload document'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _preview(BuildContext context) {
    if (!_hasDoc) {
      return const _Placeholder(
        text: 'No document uploaded yet',
        icon: Icons.image_not_supported_outlined,
      );
    }
    if (_isPdf) {
      return const _Placeholder(
        text: 'PDF document uploaded',
        icon: Icons.picture_as_pdf_outlined,
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (c, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (c, e, s) {
        appLogger.e('KYC preview failed for $label ($url)', error: e);
        return const _Placeholder(
          text: 'Preview unavailable — check your connection',
          icon: Icons.broken_image_outlined,
        );
      },
    );
  }
}

/// Full-screen, zoomable image viewer opened when a preview is tapped.
class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (c, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                errorBuilder: (c, e, s) => const Center(
                  child: Text(
                    'Could not load image.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: context.colors.textTertiary),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
