/// Single source of truth for upload size + type limits.
///
/// Both the client validator (post-pick) and the empty-state subtitle
/// strings read from here, so the UI hint can't drift from the actual
/// rule. Firebase Storage rules at `storage.rules` mirror the same
/// numbers — keep them in sync if you change anything here.
class UploadLimits {
  UploadLimits._();

  // ---------------------------------------------------------------------------
  // KYC documents (Aadhaar, PAN, CIN, address proof, etc.)
  // ---------------------------------------------------------------------------

  /// Hard cap on a single KYC file.
  static const int kycMaxBytes = 5 * 1024 * 1024; // 5 MB

  /// Extensions accepted by the file picker. HEIC is included because
  /// iPhones save photos as HEIC by default — without it, iOS users can't
  /// pick the photo they just took of their ID card.
  static const List<String> kycExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'heic',
    'webp',
  ];

  /// Short human-friendly hint shown under the upload slot.
  static const String kycHint = 'PDF, JPG or PNG  ·  max 5 MB';

  // ---------------------------------------------------------------------------
  // Creative ads (image or video that plays on the LED boards)
  // ---------------------------------------------------------------------------

  /// Image cap. Bigger than KYC because brand creatives are usually
  /// 1920×1080 high-res JPEGs / PNGs.
  static const int creativeImageMaxBytes = 10 * 1024 * 1024; // 10 MB

  /// Video cap. Lets through a ~30-second 1080p H.264 MP4 with room
  /// to spare. Don't raise past 50MB until we ship chunked uploads.
  static const int creativeVideoMaxBytes = 50 * 1024 * 1024; // 50 MB

  /// Image formats the boards can decode. HEIC and TIFF are excluded
  /// because the LED player firmware can't render them.
  static const List<String> creativeImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  /// Video formats the boards can decode. MP4 only (H.264) — we drop
  /// MOV / MKV because not every board firmware handles them.
  static const List<String> creativeVideoExtensions = ['mp4'];

  static const String creativeImageHint =
      'JPG, PNG or WEBP  ·  1920×1080 preferred  ·  max 10 MB';
  static const String creativeVideoHint =
      'MP4 only  ·  10–30 seconds  ·  max 50 MB';

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  /// Renders a byte count as the rounded MB number used in error
  /// messages ("max 5 MB"). Conservative — uses MB = 1024×1024.
  static String formatMaxMb(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 10) return '${mb.toStringAsFixed(0)} MB';
    return '${mb.toStringAsFixed(1)} MB';
  }
}
