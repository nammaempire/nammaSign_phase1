import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../widgets/picked_file.dart';

/// Uploads a picked file to [ref].
///
/// On Android / iOS this is exactly `ref.putFile(File(path))` (streamed
/// from disk). On web there is no file system, so the bytes are read from
/// the browser and sent with `putData`, with the content type set from the
/// file extension (putFile infers it from the path; putData can't).
Future<TaskSnapshot> uploadPickedFile(Reference ref, PickedFile file) async {
  if (!kIsWeb) {
    return ref.putFile(File(file.path));
  }
  final bytes = await file.xfile.readAsBytes();
  return ref.putData(
    bytes,
    SettableMetadata(
      contentType: file.xfile.mimeType ?? _contentTypeFor(file.extension),
    ),
  );
}

String? _contentTypeFor(String ext) {
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    case 'pdf':
      return 'application/pdf';
    case 'mp4':
      return 'video/mp4';
    case 'mov':
      return 'video/quicktime';
    default:
      return null;
  }
}
