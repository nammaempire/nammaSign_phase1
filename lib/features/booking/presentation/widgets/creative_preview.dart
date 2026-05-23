import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Preview area for the uploaded creative.
///
/// - No file yet → renders a fallback purple "stage" with [fallbackTitle]
///   and [fallbackSubtitle] (matches the design's "Brigade Cornerstone"
///   placeholder when no real upload exists).
/// - Image file → shows the image.
/// - Video file → renders a [VideoPlayer] with tap-to-play/pause and a
///   duration label (warns if duration > 20s).
class CreativePreview extends StatefulWidget {
  const CreativePreview({
    super.key,
    required this.file,
    required this.isVideo,
    required this.headerLabel,
    required this.fallbackTitle,
    required this.fallbackSubtitle,
    this.maxVideoSeconds = 20,
    this.onVideoTooLong,
  });

  final PlatformFile? file;
  final bool isVideo;
  final String headerLabel;
  final String fallbackTitle;
  final String fallbackSubtitle;
  final int maxVideoSeconds;
  final VoidCallback? onVideoTooLong;

  @override
  State<CreativePreview> createState() => _CreativePreviewState();
}

class _CreativePreviewState extends State<CreativePreview> {
  VideoPlayerController? _video;

  @override
  void didUpdateWidget(covariant CreativePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.file?.path != oldWidget.file?.path ||
        widget.isVideo != oldWidget.isVideo) {
      _disposeVideo();
      if (widget.isVideo) _initVideo();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    final path = widget.file?.path;
    if (path == null) return;
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _video = controller);
      if (controller.value.duration.inSeconds > widget.maxVideoSeconds) {
        widget.onVideoTooLong?.call();
      }
    } catch (_) {
      // Codec or playback failure — fall through to empty state.
      await controller.dispose();
    }
  }

  void _disposeVideo() {
    _video?.dispose();
    _video = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.badgeDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.headerLabel.toUpperCase(),
            style: AppTextStyles.brandFooter.copyWith(
              color: AppColors.primary,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Preview surface — 16:9
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: _buildPreviewBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBody() {
    final file = widget.file;
    if (file == null) {
      return _FallbackStage(
        title: widget.fallbackTitle,
        subtitle: widget.fallbackSubtitle,
      );
    }

    if (widget.isVideo) {
      final video = _video;
      if (video == null || !video.value.isInitialized) {
        return const _LoadingStage();
      }
      return _VideoStage(controller: video, maxSeconds: widget.maxVideoSeconds);
    }

    if (file.path != null) {
      return Image.file(
        File(file.path!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _LoadingStage(),
      );
    }
    return const _LoadingStage();
  }
}

class _FallbackStage extends StatelessWidget {
  const _FallbackStage({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.brandHuge.copyWith(
              fontSize: 22,
              color: AppColors.textPrimary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle.toUpperCase(),
            style: AppTextStyles.brandFooter.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.8),
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoadingStage extends StatelessWidget {
  const _LoadingStage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class _VideoStage extends StatefulWidget {
  const _VideoStage({required this.controller, required this.maxSeconds});
  final VideoPlayerController controller;
  final int maxSeconds;

  @override
  State<_VideoStage> createState() => _VideoStageState();
}

class _VideoStageState extends State<_VideoStage> {
  void _toggle() {
    setState(() {
      widget.controller.value.isPlaying
          ? widget.controller.pause()
          : widget.controller.play();
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.controller.value.duration;
    final tooLong = duration.inSeconds > widget.maxSeconds;
    return GestureDetector(
      onTap: _toggle,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: widget.controller.value.size.width,
              height: widget.controller.value.size.height,
              child: VideoPlayer(widget.controller),
            ),
          ),
          if (!widget.controller.value.isPlaying)
            const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 56,
                color: Colors.white70,
              ),
            ),
          Positioned(
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: tooLong ? AppColors.error : Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    tooLong
                        ? '${_fmt(duration)} · TOO LONG'
                        : _fmt(duration),
                    style: AppTextStyles.brandFooter.copyWith(
                      color: Colors.white,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
