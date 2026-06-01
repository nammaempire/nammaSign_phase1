import 'package:file_selector/file_selector.dart';

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
}
