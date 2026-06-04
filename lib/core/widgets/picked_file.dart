import 'package:file_selector/file_selector.dart';

import '../uploads/upload_limits.dart';

/// Thin holder around a picked [XFile] that caches the file size
/// synchronously, since UI widgets need to render the size label without
/// awaiting `XFile.length()` on every rebuild.
///
/// Build via [PickedFile.from] which performs the one-time async length()
/// call right after the user picks the file.
class PickedFile {
  const PickedFile({
    required this.xfile,
    required this.sizeBytes,
  });

  final XFile xfile;
  final int sizeBytes;

  String get name => xfile.name;
  String get path => xfile.path;

  /// Lower-cased extension WITHOUT the leading dot (`'pdf'`, `'jpg'`).
  /// Empty string when the filename has no extension.
  String get extension {
    final i = name.lastIndexOf('.');
    if (i < 0 || i == name.length - 1) return '';
    return name.substring(i + 1).toLowerCase();
  }

  static Future<PickedFile> from(XFile file) async {
    return PickedFile(
      xfile: file,
      sizeBytes: await file.length(),
    );
  }

  /// Convenience: pick a single file via file_selector and wrap it.
  /// Returns null if the user cancelled the picker.
  static Future<PickedFile?> pick({
    required List<String> extensions,
    String label = 'files',
  }) async {
    final typeGroup = XTypeGroup(label: label, extensions: extensions);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;
    return PickedFile.from(file);
  }

  /// Validates this picked file against an allowed extension list + a
  /// size cap. Returns `null` when the file is good; otherwise returns a
  /// short user-facing error string ready to drop into a snackbar.
  ///
  /// The OS picker should already have filtered by extension, but some
  /// platforms ignore the filter (e.g. iOS's "Recents" tab), so we
  /// double-check here.
  String? validate({
    required List<String> allowedExtensions,
    required int maxBytes,
  }) {
    final ext = extension;
    if (ext.isEmpty || !allowedExtensions.contains(ext)) {
      final pretty = allowedExtensions.map((e) => e.toUpperCase()).join(', ');
      return 'This file type isn\'t supported. Please choose a $pretty file.';
    }
    if (sizeBytes > maxBytes) {
      final size = UploadLimits.formatMaxMb(sizeBytes);
      final cap = UploadLimits.formatMaxMb(maxBytes);
      return 'That file is $size — please pick something under $cap.';
    }
    return null;
  }
}
