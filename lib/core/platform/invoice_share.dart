import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a generated invoice PDF to the user.
///
/// On Android / iOS: writes it to a temp file and opens the OS share sheet
/// with the PDF attached (unchanged behaviour). On web there is no temp
/// directory or share sheet, so the browser downloads the PDF instead.
Future<void> shareInvoicePdf({
  required List<int> bytes,
  required String orderRef,
}) async {
  final fileName = 'Reset95_invoice_$orderRef.pdf';
  if (kIsWeb) {
    await XFile.fromData(
      Uint8List.fromList(bytes),
      mimeType: 'application/pdf',
      name: fileName,
    ).saveTo(fileName);
    return;
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/pdf')],
    subject: 'Reset95 invoice — $orderRef',
    text: 'Tax invoice for your Reset95 booking $orderRef.',
  );
}
