import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/picked_file.dart';

/// Plays the uploaded photos as an auto-advancing slideshow — a preview of
/// the "video" the board will show. Each photo is displayed for
/// (totalSeconds / photoCount) seconds, cross-fading between frames.
/// The total slot is capped at 25 seconds.
///
/// This is a preview only — the actual MP4 for the boards is rendered
/// server-side at submit (FFmpeg). The per-photo timing shown here is the
/// same formula that render will use.
class CreativeSlideshowPreview extends StatefulWidget {
  const CreativeSlideshowPreview({
    super.key,
    required this.images,
    required this.headerLabel,
    this.totalSeconds = 25,
  });

  final List<PickedFile> images;
  final String headerLabel;

  /// Total board-slot length the photos are spread across.
  final int totalSeconds;

  @override
  State<CreativeSlideshowPreview> createState() =>
      _CreativeSlideshowPreviewState();
}

class _CreativeSlideshowPreviewState extends State<CreativeSlideshowPreview> {
  int _i = 0;
  Timer? _timer;

  double get _perPhoto =>
      widget.images.isEmpty ? 0 : widget.totalSeconds / widget.images.length;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant CreativeSlideshowPreview old) {
    super.didUpdateWidget(old);
    if (old.images.length != widget.images.length) {
      _i = 0;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    if (widget.images.length < 2) return;
    final ms = (_perPhoto * 1000).round().clamp(500, 25000);
    _timer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (!mounted) return;
      setState(() => _i = (_i + 1) % widget.images.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openFullscreen(BuildContext context) {
    _timer?.cancel();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => _SlideshowFullscreen(
            images: widget.images,
            totalSeconds: widget.totalSeconds,
          ),
        ))
        .then((_) {
      if (mounted) _start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.images.length;
    final safeIndex = _i % (n == 0 ? 1 : n);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.badgeDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.headerLabel.toUpperCase(),
                  style: AppTextStyles.brandFooter.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.slideshow_rounded,
                        size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'SLIDESHOW',
                      style: AppTextStyles.brandFooter.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => _openFullscreen(context),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    child: SizedBox.expand(
                      key: ValueKey(safeIndex),
                      child: Image.file(
                        File(widget.images[safeIndex].path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: AppSpacing.sm,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int k = 0; k < n; k++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            width: k == safeIndex ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: k == safeIndex
                                  ? Colors.white
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$n photos  ·  ${_perPhoto.toStringAsFixed(1)}s each  ·  '
            '${widget.totalSeconds}s loop  ·  tap to view',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}


/// Full-screen viewer opened when the preview is tapped. Swipe to browse
/// each photo individually, or let the slideshow auto-play (pause/play).
class _SlideshowFullscreen extends StatefulWidget {
  const _SlideshowFullscreen({required this.images, required this.totalSeconds});

  final List<PickedFile> images;
  final int totalSeconds;

  @override
  State<_SlideshowFullscreen> createState() => _SlideshowFullscreenState();
}

class _SlideshowFullscreenState extends State<_SlideshowFullscreen> {
  final PageController _pc = PageController();
  int _i = 0;
  bool _playing = true;
  Timer? _timer;

  double get _perPhoto =>
      widget.images.isEmpty ? 0 : widget.totalSeconds / widget.images.length;

  @override
  void initState() {
    super.initState();
    _startAuto();
  }

  void _startAuto() {
    _timer?.cancel();
    if (!_playing || widget.images.length < 2) return;
    final ms = (_perPhoto * 1000).round().clamp(500, 25000);
    _timer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (!mounted || !_pc.hasClients) return;
      final next = (_i + 1) % widget.images.length;
      _pc.animateToPage(next,
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  void _toggle() {
    setState(() => _playing = !_playing);
    _startAuto();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.images.length;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pc,
              itemCount: n,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (_, i) => Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.file(
                    File(widget.images[i].path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Photo ${_i + 1} / $n',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int k = 0; k < n; k++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: k == _i ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: k == _i
                                ? AppColors.primary
                                : Colors.white38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _toggle,
                    icon: Icon(_playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                    label: Text(_playing ? 'Pause slideshow' : 'Play slideshow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_perPhoto.toStringAsFixed(1)}s each  ·  '
                    '${widget.totalSeconds}s loop  ·  swipe to browse',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
