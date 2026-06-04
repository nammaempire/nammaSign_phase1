import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// One booking → one tax-style PDF invoice.
///
/// Builds a clean A4 invoice with NammaSign brand colours: header band,
/// order reference, billed-to block (when we have user identity), line
/// items, subtotal + 18% GST + total, and a footer with payment status.
/// Designed to be readable on a phone screen but also printable.
class InvoiceData {
  const InvoiceData({
    required this.orderRef,
    required this.campaignTitle,
    required this.boardLabel,
    required this.location,
    required this.durationDays,
    required this.dailyRate,
    required this.subtotal,
    required this.gst,
    required this.total,
    required this.status,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.runDateLabel,
    this.paymentMethod,
    DateTime? issuedAt,
  }) : issuedAt = issuedAt;

  final String orderRef;
  final String campaignTitle;
  final String boardLabel;
  final String location;
  final int durationDays;
  final int dailyRate;
  final int subtotal;
  final int gst;
  final int total;

  /// Free-text like 'Pending review', 'Paid', etc.
  final String status;

  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? runDateLabel;
  final String? paymentMethod;
  final DateTime? issuedAt;

  DateTime get when => issuedAt ?? DateTime.now();
}

class InvoiceBuilder {
  InvoiceBuilder._();

  /// NammaSign brand purple used in the PDF.
  static const _purple = PdfColor.fromInt(0xFF7B2FE3);
  static const _darkInk = PdfColor.fromInt(0xFF1A1A22);
  static const _mutedInk = PdfColor.fromInt(0xFF6E6E7C);
  static const _hairline = PdfColor.fromInt(0xFFE5E0F0);

  /// Builds and returns the raw PDF bytes. The caller hands these to
  /// `Printing.sharePdf` / `Printing.layoutPdf`.
  static Future<List<int>> build(InvoiceData data) async {
    final doc = pw.Document(
      title: 'NammaSign invoice ${data.orderRef}',
      author: 'NammaSign',
    );

    final fmtAmt = NumberFormat.decimalPattern('en_IN');
    final fmtDate = DateFormat('d MMM y · HH:mm');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _header(data, fmtDate),
            pw.SizedBox(height: 24),
            _identityBlock(data),
            pw.SizedBox(height: 18),
            _lineItemsTable(data, fmtAmt),
            pw.SizedBox(height: 14),
            _totalsBlock(data, fmtAmt),
            pw.Spacer(),
            _footer(data),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  static pw.Widget _header(InvoiceData data, DateFormat fmtDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const pw.BoxDecoration(
        color: _purple,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'NammaSign',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Ad-Tech Marketplace · Bengaluru',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'TAX INVOICE',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                data.orderRef,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Issued ${fmtDate.format(data.when)} IST',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _identityBlock(InvoiceData data) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _block(
            caption: 'BILLED TO',
            lines: [
              if (data.customerName?.isNotEmpty == true) data.customerName!,
              if (data.customerEmail?.isNotEmpty == true) data.customerEmail!,
              if (data.customerPhone?.isNotEmpty == true) data.customerPhone!,
              if (data.customerName == null &&
                  data.customerEmail == null &&
                  data.customerPhone == null)
                'NammaSign customer',
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: _block(
            caption: 'CAMPAIGN',
            lines: [
              data.campaignTitle,
              '${data.location} · ${data.boardLabel}',
              if (data.runDateLabel != null) 'Runs from ${data.runDateLabel}',
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _lineItemsTable(InvoiceData data, NumberFormat fmt) {
    pw.Widget cell(String text,
        {bool right = false, bool head = false, double size = 10}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(
          text,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: size,
            color: head ? _mutedInk : _darkInk,
            fontWeight: head ? pw.FontWeight.bold : pw.FontWeight.normal,
            letterSpacing: head ? 1.4 : 0,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _hairline, width: 0.5),
        bottom: pw.BorderSide(color: _hairline, width: 0.5),
        top: pw.BorderSide(color: _hairline, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.8),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF6F1FA),
          ),
          children: [
            cell('DESCRIPTION', head: true),
            cell('QTY', head: true, right: true),
            cell('RATE', head: true, right: true),
            cell('AMOUNT', head: true, right: true),
          ],
        ),
        pw.TableRow(
          children: [
            cell(
              '${data.boardLabel} at ${data.location}\nCampaign: '
              '${data.campaignTitle}',
            ),
            cell('${data.durationDays} day${data.durationDays == 1 ? '' : 's'}',
                right: true),
            cell('Rs ${fmt.format(data.dailyRate)} / day', right: true),
            cell('Rs ${fmt.format(data.subtotal)}', right: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _totalsBlock(InvoiceData data, NumberFormat fmt) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 260,
        child: pw.Column(
          children: [
            _totalRow('Subtotal', 'Rs ${fmt.format(data.subtotal)}'),
            _totalRow('GST (18%)', 'Rs ${fmt.format(data.gst)}'),
            pw.Divider(color: _hairline, height: 12),
            _totalRow(
              'TOTAL',
              'Rs ${fmt.format(data.total)}',
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value,
      {bool emphasize = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: emphasize ? _purple : _mutedInk,
              fontSize: emphasize ? 13 : 11,
              fontWeight:
                  emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
              letterSpacing: emphasize ? 1.4 : 0,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: emphasize ? _purple : _darkInk,
              fontSize: emphasize ? 16 : 11,
              fontWeight:
                  emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(InvoiceData data) {
    final paymentLine = (data.paymentMethod?.isNotEmpty ?? false)
        ? 'Payment method: ${data.paymentMethod}'
        : 'Payment to be settled offline with our team.';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF6F1FA),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                'STATUS: ',
                style: pw.TextStyle(
                  color: _mutedInk,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
              pw.Text(
                data.status.toUpperCase(),
                style: pw.TextStyle(
                  color: _purple,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          paymentLine,
          style: pw.TextStyle(color: _mutedInk, fontSize: 9),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'GST is computed at 18% on the taxable subtotal as per Indian '
          'tax regulations. NammaSign collects GST on behalf of the '
          'government. Save this invoice for your records.',
          style: pw.TextStyle(color: _mutedInk, fontSize: 8, lineSpacing: 2),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Questions? nammaempire@gmail.com',
          style: pw.TextStyle(color: _mutedInk, fontSize: 9),
        ),
      ],
    );
  }

  static pw.Widget _block({required String caption, required List<String> lines}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          caption,
          style: pw.TextStyle(
            color: _mutedInk,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.6,
          ),
        ),
        pw.SizedBox(height: 4),
        for (final line in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 1),
            child: pw.Text(
              line,
              style: const pw.TextStyle(color: _darkInk, fontSize: 11),
            ),
          ),
      ],
    );
  }
}
