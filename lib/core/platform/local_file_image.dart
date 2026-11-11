import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Renders an image the user just picked from their device.
///
/// On Android / iOS this is exactly `Image.file(File(path))`. On web there
/// is no file system — the picker hands back a `blob:` URL as the path —
/// so the same image is shown with `Image.network`.
Widget localFileImage(
  String path, {
  BoxFit? fit,
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  if (kIsWeb) {
    return Image.network(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }
  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}
